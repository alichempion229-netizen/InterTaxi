"""
InterTaxi backend — Flask + Flask-SocketIO + SQLAlchemy.

Endpoints / events:
  REST:
    GET    /api/health            -> {"ok": true}
    GET    /api/trips             -> {"trips": [...]} (optional ?from= &to= filter)
    POST   /api/trips             -> create a trip (201)
    DELETE /api/trips/<trip_id>   -> delete trip + broadcast `trip_deleted`

  Socket.IO:
    post_trip   -> creates trip, broadcasts `new_trip`
    get_trips   -> emits `trips_list` back to the requester
    book_trip   -> decrements seats, broadcasts `trip_updated`,
                   acks `booking_confirmed` to the booking passenger
    delete_trip -> deletes trip, broadcasts `trip_deleted` to ALL clients
"""

import os
import json
import unicodedata
import uuid
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
from datetime import datetime, timezone

from flask import Flask, Response, jsonify, request
from flask_socketio import SocketIO, emit, join_room
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import func, inspect, text

# ---------------------------------------------------------------------------
# App & extensions
# ---------------------------------------------------------------------------

DB_URI = os.environ.get(
    "DATABASE_URL",
    "sqlite:///" + os.path.join(os.path.dirname(os.path.abspath(__file__)), "trips.db"),
).replace("postgres://", "postgresql://", 1)

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = DB_URI
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

db = SQLAlchemy(app)

socketio = SocketIO(app, cors_allowed_origins="*")


def _utc_iso(value):
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat()


# ---------------------------------------------------------------------------
# Model
# ---------------------------------------------------------------------------

class Trip(db.Model):
    """A driver's announced trip (эълон)."""

    __tablename__ = "trips"

    # UUID string primary key — matches the rows already stored on the
    # production database (Render), e.g. "42192e1f-788e-4312-a057-...".
    id = db.Column(
        db.String(64),
        primary_key=True,
        default=lambda: str(uuid.uuid4()),
    )
    driver_id = db.Column(db.String(64), index=True, nullable=False)
    driver_name = db.Column(db.String(120), default="", nullable=False)
    driver_phone = db.Column(db.String(32), default="", nullable=False)
    from_location = db.Column(db.String(120), nullable=False)
    to_location = db.Column(db.String(120), nullable=False)
    price = db.Column(db.Integer, default=0, nullable=False)
    available_seats = db.Column(db.Integer, default=0, nullable=False)
    departure_time = db.Column(db.String(32), default="", nullable=False)
    duration_minutes = db.Column(db.Integer, default=0, nullable=False)
    car_brand = db.Column(db.String(80), default="", nullable=False)
    car_model = db.Column(db.String(80), default="", nullable=False)
    car_color = db.Column(db.String(40), default="", nullable=False)
    car_plate = db.Column(db.String(40), default="", nullable=False)
    status = db.Column(db.String(16), default="active", index=True, nullable=False)
    completed_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def to_dict(self):
        """Serializes to the exact JSON shape the Flutter client expects."""
        return {
            "id": self.id,
            "driver_id": self.driver_id,
            "driver_name": self.driver_name,
            "driver_phone": self.driver_phone,
            "from_location": self.from_location,
            "to_location": self.to_location,
            "price": self.price,
            "available_seats": self.available_seats,
            "departure_time": self.departure_time,
            "duration_minutes": self.duration_minutes,
            "car_brand": self.car_brand,
            "car_model": self.car_model,
            "car_color": self.car_color,
            "car_plate": self.car_plate,
            "status": self.status,
            "completed_at": _utc_iso(self.completed_at),
            "created_at": self.created_at.isoformat() if self.created_at else "",
        }


class Booking(db.Model):
    """A passenger booking that must remain visible to the driver."""

    __tablename__ = "bookings"

    id = db.Column(db.String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    trip_id = db.Column(db.String(64), index=True, nullable=False)
    driver_id = db.Column(db.String(64), index=True, nullable=False)
    passenger_name = db.Column(db.String(120), default="", nullable=False)
    passenger_phone = db.Column(db.String(32), default="", nullable=False)
    from_location = db.Column(db.String(120), default="", nullable=False)
    to_location = db.Column(db.String(120), default="", nullable=False)
    requested_seats = db.Column(db.Integer, default=1, nullable=False)
    status = db.Column(db.String(16), default="pending", nullable=False)
    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def to_dict(self):
        return {
            "id": self.id,
            "trip_id": self.trip_id,
            "driver_id": self.driver_id,
            "passenger_name": self.passenger_name,
            "passenger_phone": self.passenger_phone,
            "from_location": self.from_location,
            "to_location": self.to_location,
            "requested_seats": self.requested_seats,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else "",
        }


class Review(db.Model):
    """One passenger review for one accepted booking."""

    __tablename__ = "reviews"

    id = db.Column(db.String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    trip_id = db.Column(db.String(64), index=True, nullable=False)
    booking_id = db.Column(db.String(64), unique=True, nullable=False)
    driver_id = db.Column(db.String(64), index=True, nullable=False)
    passenger_phone = db.Column(db.String(32), nullable=False)
    rating = db.Column(db.Integer, nullable=False)
    text = db.Column(db.Text, default="", nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "trip_id": self.trip_id,
            "booking_id": self.booking_id,
            "driver_id": self.driver_id,
            "passenger_phone": self.passenger_phone,
            "rating": self.rating,
            "text": self.text,
        }


with app.app_context():
    db.create_all()
    existing_columns = {column["name"] for column in inspect(db.engine).get_columns("trips")}
    new_columns = {
        "duration_minutes": "INTEGER DEFAULT 0 NOT NULL",
        "car_brand": "VARCHAR(80) DEFAULT '' NOT NULL",
        "car_model": "VARCHAR(80) DEFAULT '' NOT NULL",
        "car_color": "VARCHAR(40) DEFAULT '' NOT NULL",
        "car_plate": "VARCHAR(40) DEFAULT '' NOT NULL",
        "completed_at": "DATETIME NULL",
    }
    for column_name, definition in new_columns.items():
        if column_name not in existing_columns:
            db.session.execute(
                text(f"ALTER TABLE trips ADD COLUMN {column_name} {definition}")
            )
    existing_booking_columns = {
        column["name"] for column in inspect(db.engine).get_columns("bookings")
    }
    booking_columns = {
        "requested_seats": "INTEGER DEFAULT 1 NOT NULL",
        "status": "VARCHAR(16) DEFAULT 'pending' NOT NULL",
    }
    for column_name, definition in booking_columns.items():
        if column_name not in existing_booking_columns:
            db.session.execute(
                text(f"ALTER TABLE bookings ADD COLUMN {column_name} {definition}")
            )
    db.session.commit()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _broadcast_trip_deleted(trip_id) -> None:
    """Tells every connected client (drivers AND passengers) that a trip
    was removed so their lists update in real time."""
    socketio.emit("trip_deleted", {"id": str(trip_id)})


def _delete_trip_by_id(trip_id) -> bool:
    """Deletes a trip by its id. IDs are UUID strings (e.g.
    "42192e1f-788e-4312-a057-5ecc4129748a"), but any value is accepted —
    it is only used as an exact lookup key. Returns True when the trip
    existed and was removed."""
    key = str(trip_id).strip() if trip_id is not None else ""
    if not key:
        return False
    trip = db.session.get(Trip, key)
    if trip is None:
        return False
    db.session.delete(trip)
    db.session.commit()
    _broadcast_trip_deleted(key)
    return True

# ---------------------------------------------------------------------------
# REST endpoints
# ---------------------------------------------------------------------------

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"ok": True})


@app.route("/api/tts", methods=["POST"])
def text_to_speech():
    """Generate Tajik-compatible MP3 audio through ElevenLabs.

    The ElevenLabs key is read only from the server environment, never from
    the Flutter client or a checked-in source file.
    """
    api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not api_key:
        return jsonify({"ok": False, "error": "TTS is not configured"}), 503

    payload = request.get_json(silent=True) or {}
    text_value = str(payload.get("text", "")).strip()
    if not text_value or len(text_value) > 1200:
        return jsonify({"ok": False, "error": "Invalid speech text"}), 400

    voice_id = os.environ.get("ELEVENLABS_VOICE_ID", "21m00Tcm4TlvDq8ikWAM")
    provider_payload = json.dumps({
        "text": text_value,
        "model_id": "eleven_multilingual_v2",
        "voice_settings": {
            "stability": 0.48,
            "similarity_boost": 0.78,
            "style": 0.2,
            "use_speaker_boost": True,
        },
    }).encode("utf-8")
    provider_request = Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}",
        data=provider_payload,
        headers={
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": api_key,
        },
        method="POST",
    )

    try:
        with urlopen(provider_request, timeout=30) as provider_response:
            audio_bytes = provider_response.read()
        return Response(audio_bytes, mimetype="audio/mpeg")
    except (HTTPError, URLError, TimeoutError) as error:
        app.logger.warning("ElevenLabs TTS request failed: %s", error)
        return jsonify({"ok": False, "error": "TTS provider unavailable"}), 502


def _normalize_location(value: str) -> str:
    """Normalizes route names before applying the passenger route filter."""
    return " ".join(
        unicodedata.normalize("NFC", str(value or "")).casefold().split()
    )


def _filter_trips_by_route(trips, from_loc: str, to_loc: str):
    normalized_from = _normalize_location(from_loc)
    normalized_to = _normalize_location(to_loc)
    return [
        trip
        for trip in trips
        if (not normalized_from
            or _normalize_location(trip.from_location) == normalized_from)
        and (not normalized_to
             or _normalize_location(trip.to_location) == normalized_to)
    ]


@app.route("/api/trips", methods=["GET"])
def get_trips():
    """Lists active trips, optionally filtered by the EXACT route.

    `?from=Кулоб&to=Душанбе` returns ONLY trips whose `from_location` and
    `to_location` equal the requested values, so the passenger main screen
    never shows trips created for another route. Only `active` trips are
    returned — deleted rows are gone from the DB and booked ones are hidden,
    therefore a deleted trip can never reappear on refresh.
    """
    query = Trip.query.filter(Trip.status == "active")
    from_loc = request.args.get("from", "").strip()
    to_loc = request.args.get("to", "").strip()
    # STRICT route filtering with `ilike` (case-insensitive exact match):
    # a passenger searching "Кулоб -> Восе" gets ONLY trips whose
    # from_location AND to_location match — never trips for another route.
    trips = _filter_trips_by_route(
        query.order_by(Trip.created_at.desc()).all(), from_loc, to_loc
    )
    return jsonify({"trips": [t.to_dict() for t in trips]})


@app.route("/api/drivers/<string:driver_id>/earnings", methods=["GET"])
def get_driver_earnings(driver_id: str):
    """Returns fare totals from this driver's completed rides only.

    The fare is the per-seat price set on the trip. Only approved bookings
    contribute seats to earnings; pending and rejected bookings are excluded.
    """
    driver_key = driver_id.strip()
    if not driver_key:
        return jsonify({"ok": False, "error": "driver_id is required"}), 400

    trips = Trip.query.filter_by(
        driver_id=driver_key,
        status="completed",
    ).all()
    approved_seats_by_trip = dict(
        db.session.query(
            Booking.trip_id,
            func.coalesce(func.sum(Booking.requested_seats), 0),
        )
        .filter(
            Booking.driver_id == driver_key,
            Booking.status == "approved",
            Booking.trip_id.in_([trip.id for trip in trips]),
        )
        .group_by(Booking.trip_id)
        .all()
    ) if trips else {}

    trip_rows = []
    for trip in trips:
        approved_seats = int(approved_seats_by_trip.get(trip.id, 0) or 0)
        price_per_seat = max(int(trip.price or 0), 0)
        trip_rows.append({
            "id": trip.id,
            "from_location": trip.from_location,
            "to_location": trip.to_location,
            "price_per_seat": price_per_seat,
            "approved_seats": approved_seats,
            "earnings": price_per_seat * approved_seats,
            "completed_at": _utc_iso(trip.completed_at),
        })

    trip_rows.sort(
        key=lambda row: row["completed_at"] or "",
        reverse=True,
    )
    return jsonify({"trips": trip_rows})


@app.route("/api/trips", methods=["POST"])
def create_trip():
    payload = request.get_json(silent=True) or {}
    required = ("driver_id", "from_location", "to_location")
    if any(not str(payload.get(field, "")).strip() for field in required):
        return jsonify({"ok": False, "error": "Missing required fields"}), 400

    trip = Trip(
        driver_id=str(payload["driver_id"]),
        driver_name=str(payload.get("driver_name", "")),
        driver_phone=str(payload.get("driver_phone", "")),
        from_location=str(payload["from_location"]),
        to_location=str(payload["to_location"]),
        price=int(payload.get("price") or 0),
        available_seats=int(payload.get("available_seats") or 0),
        departure_time=str(payload.get("departure_time", "")),
        duration_minutes=int(payload.get("duration_minutes") or 0),
        car_brand=str(payload.get("car_brand", "")),
        car_model=str(payload.get("car_model", "")),
        car_color=str(payload.get("car_color", "")),
        car_plate=str(payload.get("car_plate", "")),
        status="active",
    )
    db.session.add(trip)
    db.session.commit()
    socketio.emit("new_trip", trip.to_dict())
    return jsonify({"ok": True, "trip": trip.to_dict()}), 201


@app.route("/api/trips/<string:trip_id>", methods=["DELETE"])
def delete_trip_rest(trip_id: str):
    """Deletes the trip PERMANENTLY from the server database and broadcasts
    `trip_deleted` to ALL connected clients.

    Flow: `_delete_trip_by_id` runs `db.session.delete(trip)` +
    `db.session.commit()`, then `socketio.emit('trip_deleted', {'id': ...})`
    fires to every passenger/driver so the trip instantly disappears from
    all client lists and never reappears on refresh.
    """
    deleted = _delete_trip_by_id(trip_id)
    if not deleted:
        return jsonify({"ok": False, "error": "Trip not found"}), 404
    return jsonify({"ok": True, "id": trip_id})


@app.route("/api/bookings", methods=["GET"])
def get_bookings():
    """Returns durable bookings for a driver or passenger."""
    driver_id = request.args.get("driver_id", "").strip()
    passenger_phone = request.args.get("passenger_phone", "").strip()
    if not driver_id and not passenger_phone:
        return jsonify({"bookings": []})
    query = Booking.query
    if driver_id:
        query = query.filter_by(driver_id=driver_id)
    if passenger_phone:
        query = query.filter_by(passenger_phone=passenger_phone)
    bookings = query.order_by(Booking.created_at.desc()).all()
    return jsonify({"bookings": [booking.to_dict() for booking in bookings]})


def _create_booking(payload):
    """Books one seat, stores the booking, and notifies connected clients."""
    trip_key = str(payload.get("trip_id", "") or "").strip()
    trip = db.session.get(Trip, trip_key) if trip_key else None
    if trip is None:
        return None, ("Trip not found", 404)
    try:
        requested_seats = int(payload.get("requested_seats", 1))
    except (TypeError, ValueError):
        return None, ("Invalid seat count", 400)
    if requested_seats < 1:
        return None, ("Invalid seat count", 400)
    if trip.status != "active" or trip.available_seats < requested_seats:
        return None, ("No seats available", 409)

    trip.available_seats -= requested_seats
    if trip.available_seats == 0:
        trip.status = "booked"
    booking = Booking(
        trip_id=trip.id,
        driver_id=trip.driver_id,
        passenger_name=str(payload.get("passenger_name", "")).strip(),
        passenger_phone=str(payload.get("passenger_phone", "")).strip(),
        from_location=trip.from_location,
        to_location=trip.to_location,
        requested_seats=requested_seats,
        status="pending",
    )
    db.session.add(booking)
    db.session.commit()

    socketio.emit("trip_updated", trip.to_dict())
    socketio.emit("passenger_booked", booking.to_dict())
    return {"booking": booking.to_dict(), "trip": trip.to_dict()}, None


@app.route("/api/bookings", methods=["POST"])
def create_booking():
    payload = request.get_json(silent=True) or {}
    result, error = _create_booking(payload)
    if error:
        message, status = error
        return jsonify({"ok": False, "error": message}), status
    return jsonify({"ok": True, **result}), 201


@app.route("/api/bookings/<string:booking_id>/decision", methods=["POST"])
def decide_booking(booking_id: str):
    payload = request.get_json(silent=True) or {}
    booking = db.session.get(Booking, booking_id)
    if booking is None:
        return jsonify({"ok": False, "error": "Booking not found"}), 404
    if str(payload.get("driver_id", "")).strip() != booking.driver_id:
        return jsonify({"ok": False, "error": "Not authorized"}), 403
    decision = str(payload.get("decision", "")).strip().lower()
    if decision not in {"approved", "rejected"}:
        return jsonify({"ok": False, "error": "Invalid decision"}), 400
    booking.status = decision
    db.session.commit()
    socketio.emit("booking_decision", booking.to_dict())
    return jsonify({"ok": True, "booking": booking.to_dict()})


@app.route("/api/reviews", methods=["POST"])
def create_review():
    payload = request.get_json(silent=True) or {}
    booking_id = str(payload.get("booking_id", "")).strip()
    passenger_phone = str(payload.get("passenger_phone", "")).strip()
    booking = db.session.get(Booking, booking_id)
    if booking is None or booking.status != "approved":
        return jsonify({"ok": False, "error": "Approved booking not found"}), 404
    if passenger_phone != booking.passenger_phone:
        return jsonify({"ok": False, "error": "Not authorized"}), 403

    trip = db.session.get(Trip, booking.trip_id)
    if trip is None or trip.status != "completed":
        return jsonify({"ok": False, "error": "Trip is not completed"}), 409

    try:
        rating = int(payload.get("rating", 0))
    except (TypeError, ValueError):
        rating = 0
    if rating < 1 or rating > 5:
        return jsonify({"ok": False, "error": "Rating must be between 1 and 5"}), 400
    if Review.query.filter_by(booking_id=booking.id).first() is not None:
        return jsonify({"ok": False, "error": "Review already submitted"}), 409

    review = Review(
        trip_id=trip.id,
        booking_id=booking.id,
        driver_id=booking.driver_id,
        passenger_phone=booking.passenger_phone,
        rating=rating,
        text=str(payload.get("text", "")).strip(),
    )
    db.session.add(review)
    db.session.commit()

    average = db.session.query(func.avg(Review.rating)).filter_by(
        driver_id=trip.driver_id,
    ).scalar() or 0
    review_payload = {
        "driver_id": trip.driver_id,
        "rating": float(average),
        "review": review.to_dict(),
    }
    socketio.emit("review_created", review_payload, room=f"driver:{trip.driver_id}")
    return jsonify({"ok": True, **review_payload}), 201


# ---------------------------------------------------------------------------
# Socket.IO handlers
# ---------------------------------------------------------------------------

@socketio.on("connect")
def on_connect():
    user_id = request.args.get("user_id", "").strip()
    role = request.args.get("role", "").strip()
    if user_id and role:
        join_room(f"{role}:{user_id}")
    print(f"[socket] client connected: {request.sid}")


@socketio.on("disconnect")
def on_disconnect():
    print(f"[socket] client disconnected: {request.sid}")


@socketio.on("post_trip")
def handle_post_trip(data):
    """Driver publishes a new trip; broadcast it to everyone."""
    data = data or {}
    trip = Trip(
        driver_id=str(data.get("driver_id", data.get("driver_phone", ""))),
        driver_name=str(data.get("driver_name", "")),
        driver_phone=str(data.get("driver_phone", "")),
        from_location=str(data.get("from_location", "")),
        to_location=str(data.get("to_location", "")),
        price=int(data.get("price") or 0),
        available_seats=int(data.get("available_seats") or 0),
        departure_time=str(data.get("departure_time", "")),
        duration_minutes=int(data.get("duration_minutes") or 0),
        car_brand=str(data.get("car_brand", "")),
        car_model=str(data.get("car_model", "")),
        car_color=str(data.get("car_color", "")),
        car_plate=str(data.get("car_plate", "")),
        status="active",
    )
    db.session.add(trip)
    db.session.commit()
    socketio.emit("new_trip", trip.to_dict())
    return {"ok": True, "trip": trip.to_dict()}


@socketio.on("get_trips")
def handle_get_trips(data):
    """Passenger requests the active trips (optionally filtered by from/to)."""
    data = data or {}
    query = Trip.query.filter(Trip.status == "active")
    from_loc = str(data.get("from", "")).strip()
    to_loc = str(data.get("to", "")).strip()
    # STRICT route filtering with `ilike` (same as the REST endpoint).
    trips = _filter_trips_by_route(
        query.order_by(Trip.created_at.desc()).all(), from_loc, to_loc
    )
    emit("trips_list", {"trips": [t.to_dict() for t in trips]})


@socketio.on("book_trip")
def handle_book_trip(data):
    """Passenger books a seat on a trip."""
    result, error = _create_booking(data or {})
    if error:
        message, _ = error
        return {"ok": False, "error": message}
    booking = result["booking"]
    trip = result["trip"]
    emit(
        "booking_confirmed",
        {
            "ok": True,
            "trip_id": trip["id"],
            "passenger_name": booking["passenger_name"],
        },
    )
    return {"ok": True, "trip": trip}


@socketio.on("delete_trip")
def handle_delete_trip(data):
    """Driver deletes a trip; remove it from the database and broadcast
    `trip_deleted` with {"id": ...} to ALL connected users."""
    trip_id = None
    if isinstance(data, dict):
        trip_id = data.get("trip_id") or data.get("id")
    elif data is not None:
        trip_id = data
    if trip_id is None:
        return {"ok": False, "error": "trip_id is required"}
    deleted = _delete_trip_by_id(trip_id)
    if deleted:
        return {"ok": True, "id": str(trip_id)}
    return {"ok": False, "error": "Trip not found"}


@socketio.on("end_trip_broadcast")
def handle_end_trip_broadcast(data):
    data = data or {}
    trip_id = str(data.get("trip_id", "")).strip()
    driver_id = str(data.get("driver_id", "")).strip()
    trip = db.session.get(Trip, trip_id)
    if trip is None or trip.driver_id != driver_id:
        return {"ok": False, "error": "Not authorized"}
    if trip.status == "completed":
        return {"ok": True, "trip_id": trip.id}

    trip.status = "completed"
    trip.completed_at = datetime.now(timezone.utc)
    bookings = Booking.query.filter_by(
        trip_id=trip.id,
        status="approved",
    ).all()
    db.session.commit()

    for booking in bookings:
        socketio.emit(
            "trip_completed",
            {
                "trip_id": trip.id,
                "booking_id": booking.id,
                "driver_id": trip.driver_id,
                "driver_name": trip.driver_name,
                "completed_at": _utc_iso(trip.completed_at),
            },
            room=f"passenger:{booking.passenger_phone}",
        )
    socketio.emit(
        "trip_completed",
        {
            "trip_id": trip.id,
            "driver_id": trip.driver_id,
            "completed_at": _utc_iso(trip.completed_at),
        },
        room=f"driver:{trip.driver_id}",
    )
    return {"ok": True, "trip_id": trip.id}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    socketio.run(app, host="0.0.0.0", port=port, debug=False)

