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
import io
import shutil
import tempfile
import unicodedata
import uuid
import warnings
from sqlalchemy.exc import IntegrityError
from datetime import datetime, timedelta, timezone

from flask import Flask, has_request_context, jsonify, request, send_from_directory
from flask_socketio import SocketIO, emit, join_room
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import MetaData, Table, func, inspect, text
from PIL import Image, ImageOps, UnidentifiedImageError

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
app.config["MAX_CONTENT_LENGTH"] = 25 * 1024 * 1024
UPLOAD_ROOT = os.path.join(app.root_path, "uploads")
MAX_TRIP_PHOTO_BYTES = 8 * 1024 * 1024

db = SQLAlchemy(app)

socketio = SocketIO(app, cors_allowed_origins="*")
EARNINGS_TIMEZONE = timezone(timedelta(hours=5), "Asia/Dushanbe")


def _utc_iso(value):
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc).isoformat()


def _public_upload_url(path):
    if not path:
        return ""
    if str(path).startswith(("http://", "https://")):
        return str(path)
    if has_request_context():
        return f"{request.url_root.rstrip('/')}/{str(path).lstrip('/')}"
    return str(path)


def _optional_trip_string(value):
    normalized = str(value or "").strip()
    return normalized or None


@app.after_request
def _allow_api_cors(response):
    response.headers.setdefault("Access-Control-Allow-Origin", "*")
    response.headers.setdefault(
        "Access-Control-Allow-Headers", "Authorization, Content-Type"
    )
    response.headers.setdefault(
        "Access-Control-Allow-Methods", "GET, POST, OPTIONS"
    )
    return response


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
    owner_uid = db.Column(db.String(128), index=True, nullable=True)
    driver_name = db.Column(db.String(120), default="", nullable=False)
    driver_phone = db.Column(db.String(32), default="", nullable=False)
    from_location = db.Column(db.String(120), nullable=False)
    to_location = db.Column(db.String(120), nullable=False)
    price = db.Column(db.Integer, default=0, nullable=False)
    available_seats = db.Column(db.Integer, default=0, nullable=False)
    departure_time = db.Column(db.String(32), default="", nullable=False)
    duration_minutes = db.Column(db.Integer, default=0, nullable=False)
    car_brand = db.Column(db.String(80), nullable=True)
    car_model = db.Column(db.String(80), nullable=True)
    car_color = db.Column(db.String(40), nullable=True)
    car_plate = db.Column(db.String(40), nullable=True)
    car_photo_front = db.Column(db.String(512), nullable=True)
    car_photo_rear = db.Column(db.String(512), nullable=True)
    car_photo_side = db.Column(db.String(512), nullable=True)
    car_thumb_front = db.Column(db.String(512), nullable=True)
    car_thumb_rear = db.Column(db.String(512), nullable=True)
    car_thumb_side = db.Column(db.String(512), nullable=True)
    status = db.Column(db.String(16), default="active", index=True, nullable=False)
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(
        db.DateTime,
        default=lambda: datetime.now(timezone.utc),
        nullable=False,
    )

    def to_dict(self):
        """Serializes to the exact JSON shape the Flutter client expects."""
        photo_paths = [
            self.car_photo_front,
            self.car_photo_rear,
            self.car_photo_side,
        ]
        thumb_paths = [
            self.car_thumb_front,
            self.car_thumb_rear,
            self.car_thumb_side,
        ]
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
            "car_photo_front": _public_upload_url(self.car_photo_front),
            "car_photo_rear": _public_upload_url(self.car_photo_rear),
            "car_photo_side": _public_upload_url(self.car_photo_side),
            "car_thumb_front": _public_upload_url(self.car_thumb_front),
            "car_thumb_rear": _public_upload_url(self.car_thumb_rear),
            "car_thumb_side": _public_upload_url(self.car_thumb_side),
            "car_photos": [_public_upload_url(path) for path in photo_paths],
            "car_photo_thumbs": [
                _public_upload_url(path) for path in thumb_paths
            ],
            "status": self.status,
            "completed_at": _utc_iso(self.completed_at),
            "created_at": self.created_at.isoformat() if self.created_at else "",
        }


class Earning(db.Model):
    """Immutable fare captured once when an owned trip is completed."""

    __tablename__ = "earnings"

    id = db.Column(db.String(64), primary_key=True, default=lambda: str(uuid.uuid4()))
    driver_id = db.Column(db.String(64), index=True, nullable=False)
    owner_uid = db.Column(db.String(128), index=True, nullable=False)
    trip_id = db.Column(db.String(64), unique=True, nullable=False)
    amount = db.Column(db.Integer, nullable=False)
    from_location = db.Column(db.String(120), default="", nullable=False)
    to_location = db.Column(db.String(120), default="", nullable=False)
    created_at = db.Column(db.DateTime, nullable=False)


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
    if db.engine.dialect.name == "sqlite":
        existing_columns = {
            row[1] for row in db.session.execute(text("PRAGMA table_info(trips)"))
        }
    else:
        existing_columns = {
            column["name"] for column in inspect(db.engine).get_columns("trips")
        }
    new_columns = {
        "duration_minutes": "INTEGER DEFAULT 0 NOT NULL",
        "car_brand": "VARCHAR(80) NULL",
        "car_model": "VARCHAR(80) NULL",
        "car_color": "VARCHAR(40) NULL",
        "car_plate": "VARCHAR(40) NULL",
        "car_photo_front": "VARCHAR(512) NULL",
        "car_photo_rear": "VARCHAR(512) NULL",
        "car_photo_side": "VARCHAR(512) NULL",
        "car_thumb_front": "VARCHAR(512) NULL",
        "car_thumb_rear": "VARCHAR(512) NULL",
        "car_thumb_side": "VARCHAR(512) NULL",
        "completed_at": "DATETIME NULL",
        "started_at": "DATETIME NULL",
        "owner_uid": "VARCHAR(128) NULL",
    }
    for column_name, definition in new_columns.items():
        if column_name not in existing_columns:
            db.session.execute(
                text(f"ALTER TABLE trips ADD COLUMN {column_name} {definition}")
            )
    db.session.commit()
    if db.engine.dialect.name == "sqlite":
        trip_info = list(
            db.session.execute(text("PRAGMA table_info(trips)")).fetchall()
        )
        nullable_columns = {"car_brand", "car_model", "car_color", "car_plate"}
        if any(row[1] in nullable_columns and row[3] for row in trip_info):
            bind = db.engine
            existing_trip = Table("trips", MetaData(), autoload_with=bind)
            migration_metadata = MetaData()
            migration_name = "trips_nullable_migration"
            stale = Table(migration_name, MetaData(), autoload_with=bind) if inspect(bind).has_table(migration_name) else None
            if stale is not None:
                stale.drop(bind)
            migrated_trip = existing_trip.to_metadata(
                migration_metadata,
                name=migration_name,
            )
            for column_name in nullable_columns:
                migrated_trip.c[column_name].nullable = True
            for index in tuple(migrated_trip.indexes):
                migrated_trip.indexes.remove(index)
            migrated_trip.create(bind)
            quote = bind.dialect.identifier_preparer.quote
            copy_columns = [column.name for column in existing_trip.columns]
            quoted_columns = ", ".join(quote(name) for name in copy_columns)
            schema_objects = db.session.execute(
                text(
                    "SELECT sql FROM sqlite_master "
                    "WHERE tbl_name = 'trips' AND type IN ('index', 'trigger') "
                    "AND sql IS NOT NULL"
                )
            ).scalars().all()
            db.session.commit()
            with bind.begin() as connection:
                connection.execute(
                    text(
                        f"INSERT INTO {quote(migration_name)} ({quoted_columns}) "
                        f"SELECT {quoted_columns} FROM {quote('trips')}"
                    )
                )
                connection.execute(text("DROP TABLE trips"))
                connection.execute(
                    text(
                        f"ALTER TABLE {quote(migration_name)} "
                        f"RENAME TO {quote('trips')}"
                    )
                )
                for schema_sql in schema_objects:
                    connection.execute(text(schema_sql))
            db.metadata.create_all(bind)
    elif db.engine.dialect.name == "postgresql":
        trip_columns = {
            column["name"]: column
            for column in inspect(db.engine).get_columns("trips")
        }
        for column_name in ("car_brand", "car_model", "car_color", "car_plate"):
            if not trip_columns[column_name]["nullable"]:
                db.session.execute(
                    text(
                        f"ALTER TABLE trips ALTER COLUMN {column_name} DROP NOT NULL"
                    )
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
    db.session.execute(
        text("CREATE INDEX IF NOT EXISTS ix_trips_owner_uid ON trips (owner_uid)")
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


def _normalize_location(value: str) -> str:
    """Normalizes route names before applying the passenger route filter."""
    return " ".join(
        unicodedata.normalize("NFC", str(value or "")).casefold().split()
    )


def _firebase_uid_for_token(token: str) -> str:
    """Verifies a Firebase ID token using server-side Admin credentials."""
    import firebase_admin
    from firebase_admin import auth, credentials

    try:
        firebase_admin.get_app()
    except ValueError:
        service_account_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()
        if service_account_json:
            credential = credentials.Certificate(json.loads(service_account_json))
        else:
            credential = credentials.ApplicationDefault()
        firebase_admin.initialize_app(
            credential,
            {"projectId": os.environ.get("FIREBASE_PROJECT_ID", "intertaxi-5b711")},
        )

    claims = auth.verify_id_token(token, check_revoked=True)
    uid = str(claims.get("uid", "")).strip()
    if not uid:
        raise ValueError("Firebase token has no uid")
    return uid


def _firebase_uid_from_request():
    authorization = request.headers.get("Authorization", "")
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        return None, (jsonify({"ok": False, "error": "Authentication required"}), 401)
    try:
        return _firebase_uid_for_token(token.strip()), None
    except ImportError:
        return None, (jsonify({"ok": False, "error": "Authentication is unavailable"}), 503)
    except Exception:
        app.logger.warning("Rejected invalid Firebase ID token", exc_info=True)
        return None, (jsonify({"ok": False, "error": "Not authorized"}), 401)


def _optional_firebase_uid_from_request():
    if not request.headers.get("Authorization"):
        return None, None
    return _firebase_uid_from_request()


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


@app.route("/api/earnings", methods=["GET"])
@app.route("/api/drivers/<string:driver_id>/earnings", methods=["GET"])
def get_driver_earnings(driver_id=None):
    """Returns only earnings owned by the authenticated Firebase user."""
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error

    period = request.args.get("period", "all").strip().lower()
    now = datetime.now(timezone.utc).astimezone(EARNINGS_TIMEZONE)
    start = None
    end = None
    if period == "day":
        start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
    elif period == "week":
        today = now.replace(hour=0, minute=0, second=0, microsecond=0)
        start = today - timedelta(days=today.weekday())
        end = start + timedelta(days=7)
    elif period == "month":
        start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        end = (
            start.replace(year=start.year + 1, month=1)
            if start.month == 12
            else start.replace(month=start.month + 1)
        )
    elif period == "year":
        start = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end = start.replace(year=start.year + 1)
    elif period != "all":
        return jsonify({"ok": False, "error": "Invalid earnings period"}), 400

    query = Earning.query.filter_by(owner_uid=owner_uid)
    if start is not None:
        start_utc = start.astimezone(timezone.utc).replace(tzinfo=None)
        end_utc = end.astimezone(timezone.utc).replace(tzinfo=None)
        query = query.filter(Earning.created_at >= start_utc)
        query = query.filter(Earning.created_at < end_utc)
    earnings = query.order_by(Earning.created_at.desc()).all()
    rows = [{
        "id": earning.id,
        "trip_id": earning.trip_id,
        "from_location": earning.from_location,
        "to_location": earning.to_location,
        "earnings": earning.amount,
        "amount": earning.amount,
        "completed_at": _utc_iso(earning.created_at),
        "created_at": _utc_iso(earning.created_at),
    } for earning in earnings]
    return jsonify({"total": sum(row["amount"] for row in rows), "trips": rows})


@app.route("/api/trips/<string:trip_id>/start", methods=["POST"])
def start_trip_rest(trip_id: str):
    owner_uid, error = _firebase_uid_from_request()
    if error:
        app.logger.warning(
            "Trip start rejected before ownership check: trip_id=%s status=%s",
            trip_id,
            error[1] if isinstance(error, tuple) and len(error) > 1 else "unknown",
        )
        return error
    app.logger.info("Trip start ownership check: token_uid=%s trip_id=%s", owner_uid, trip_id)
    trip = Trip.query.filter_by(id=trip_id).with_for_update().first()
    if trip is None:
        app.logger.warning("Trip start failed: trip not found trip_id=%s", trip_id)
        return jsonify({"ok": False, "error": "Trip not found"}), 404
    app.logger.info(
        "Trip start trip record: trip_id=%s driver_id=%s owner_uid=%s status=%s",
        trip_id, trip.driver_id, trip.owner_uid, trip.status,
    )
    if trip.owner_uid != owner_uid:
        app.logger.warning(
            "Trip start forbidden: trip_id=%s token_uid=%s trip_owner_uid=%s",
            trip_id,
            owner_uid,
            trip.owner_uid,
        )
        return jsonify({"ok": False, "error": "Not authorized"}), 403
    if trip.status not in {"active", "booked"}:
        app.logger.warning(
            "Trip start conflict: trip_id=%s status=%s", trip_id, trip.status
        )
        return jsonify({"ok": False, "error": "Trip cannot be started"}), 409
    if trip.started_at is None:
        trip.started_at = datetime.now(timezone.utc)
        db.session.commit()
    app.logger.info("Trip started: trip_id=%s owner_uid=%s", trip_id, owner_uid)
    return jsonify({"ok": True, "trip_id": trip.id, "started_at": _utc_iso(trip.started_at)})


def _complete_trip_for_owner(trip_id: str, owner_uid: str):
    trip = Trip.query.filter_by(id=trip_id).with_for_update().first()
    if trip is None:
        return None, False, (jsonify({"ok": False, "error": "Trip not found"}), 404)
    if trip.owner_uid != owner_uid:
        return None, False, (jsonify({"ok": False, "error": "Not authorized"}), 403)

    existing = Earning.query.filter_by(trip_id=trip.id).first()
    if trip.status == "completed":
        if existing is None:
            return None, False, (jsonify({"ok": False, "error": "Completion record is missing"}), 409)
        return trip, False, None
    if trip.started_at is None:
        return None, False, (jsonify({"ok": False, "error": "Trip has not been started"}), 409)

    approved_seats = db.session.query(
        func.coalesce(func.sum(Booking.requested_seats), 0),
    ).filter_by(trip_id=trip.id, status="approved").scalar()
    amount = max(int(trip.price or 0), 0) * int(approved_seats or 0)
    completed_at = datetime.now(timezone.utc)
    trip.status = "completed"
    trip.completed_at = completed_at
    db.session.add(Earning(
        driver_id=trip.driver_id,
        owner_uid=owner_uid,
        trip_id=trip.id,
        amount=amount,
        from_location=trip.from_location,
        to_location=trip.to_location,
        created_at=completed_at,
    ))
    try:
        db.session.commit()
    except IntegrityError:
        db.session.rollback()
        trip = db.session.get(Trip, trip_id)
        existing = Earning.query.filter_by(trip_id=trip_id).first()
        if trip is not None and trip.owner_uid == owner_uid and existing is not None:
            return trip, False, None
        return None, False, (jsonify({"ok": False, "error": "Trip completion conflict"}), 409)
    return trip, True, None


def _emit_trip_completed(trip):
    bookings = Booking.query.filter_by(trip_id=trip.id, status="approved").all()
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


@app.route("/api/trips/<string:trip_id>/complete", methods=["POST"])
def complete_trip_rest(trip_id: str):
    """Reliably complete a trip over REST when the driver's socket is offline."""
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    trip, created, error = _complete_trip_for_owner(trip_id, owner_uid)
    if error:
        return error
    if created:
        _emit_trip_completed(trip)
    return jsonify({"ok": True, "trip_id": trip.id})


@app.route("/api/trips", methods=["POST"])
def create_trip():
    payload = request.get_json(silent=True) or {}
    # A trip must have a verified owner so only its publishing driver can
    # later start, complete, decide bookings for, or cancel it.
    owner_uid, auth_error = _firebase_uid_from_request()
    if auth_error:
        return auth_error
    required = ("driver_id", "from_location", "to_location")
    if any(not str(payload.get(field, "")).strip() for field in required):
        return jsonify({"ok": False, "error": "Missing required fields"}), 400

    trip = Trip(
        driver_id=str(payload["driver_id"]),
        owner_uid=owner_uid,
        driver_name=str(payload.get("driver_name", "")),
        driver_phone=str(payload.get("driver_phone", "")),
        from_location=str(payload["from_location"]),
        to_location=str(payload["to_location"]),
        price=int(payload.get("price") or 0),
        available_seats=int(payload.get("available_seats") or 0),
        departure_time=str(payload.get("departure_time", "")),
        duration_minutes=int(payload.get("duration_minutes") or 0),
        car_brand=_optional_trip_string(payload.get("car_brand")),
        car_model=_optional_trip_string(payload.get("car_model")),
        car_color=_optional_trip_string(payload.get("car_color")),
        car_plate=_optional_trip_string(payload.get("car_plate")),
        status="active",
    )
    db.session.add(trip)
    db.session.commit()
    socketio.emit("new_trip", trip.to_dict())
    return jsonify({"ok": True, "trip": trip.to_dict()}), 201


@app.route("/api/trips/<string:trip_id>/photos", methods=["POST"])
def upload_trip_photos(trip_id: str):
    owner_uid, auth_error = _firebase_uid_from_request()
    if auth_error:
        return auth_error
    trip = db.session.get(Trip, trip_id)
    if trip is None:
        return jsonify({"ok": False, "error": "Trip not found"}), 404
    if trip.owner_uid != owner_uid:
        return jsonify({"ok": False, "error": "Not authorized"}), 403

    labels = ("front", "rear", "side")
    uploads = {label: request.files.get(label) for label in labels}
    if any(upload is None for upload in uploads.values()):
        return jsonify({"ok": False, "error": "All three photos are required"}), 400

    safe_trip_id = trip.id.replace("/", "_").replace("\\", "_")
    trip_directory = os.path.join(UPLOAD_ROOT, f"trip_{safe_trip_id}")
    os.makedirs(UPLOAD_ROOT, exist_ok=True)
    staging_directory = tempfile.mkdtemp(
        prefix=f".trip_{safe_trip_id}_", dir=UPLOAD_ROOT
    )
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    generated_paths = {}

    try:
        for label, upload in uploads.items():
            image_bytes = upload.stream.read(MAX_TRIP_PHOTO_BYTES + 1)
            if len(image_bytes) > MAX_TRIP_PHOTO_BYTES:
                return jsonify({"ok": False, "error": "Each photo must be 8 MB or smaller"}), 413
            try:
                with warnings.catch_warnings():
                    warnings.simplefilter("error", Image.DecompressionBombWarning)
                    image = Image.open(io.BytesIO(image_bytes))
                    if image.format not in {"JPEG", "PNG", "WEBP"}:
                        return jsonify({"ok": False, "error": "Photos must be JPG, PNG, or WebP images"}), 400
                    image.load()
                    image = ImageOps.exif_transpose(image).convert("RGB")
                image.thumbnail((1280, 1280), Image.Resampling.LANCZOS)
                full_name = f"{label}_{timestamp}.webp"
                thumb_name = f"{label}_{timestamp}_thumb.webp"
                image.save(
                    os.path.join(staging_directory, full_name),
                    format="WEBP",
                    quality=80,
                    method=6,
                )
                thumbnail = image.copy()
                thumbnail.thumbnail((360, 360), Image.Resampling.LANCZOS)
                thumbnail.save(
                    os.path.join(staging_directory, thumb_name),
                    format="WEBP",
                    quality=70,
                    method=6,
                )
                generated_paths[label] = (
                    f"/uploads/trip_{safe_trip_id}/{full_name}",
                    f"/uploads/trip_{safe_trip_id}/{thumb_name}",
                )
            except (Image.DecompressionBombError, Image.DecompressionBombWarning,
                    OSError, UnidentifiedImageError, ValueError):
                return jsonify({"ok": False, "error": "A photo is not a valid supported image"}), 400

        shutil.rmtree(trip_directory, ignore_errors=True)
        os.replace(staging_directory, trip_directory)
        trip.car_photo_front, trip.car_thumb_front = generated_paths["front"]
        trip.car_photo_rear, trip.car_thumb_rear = generated_paths["rear"]
        trip.car_photo_side, trip.car_thumb_side = generated_paths["side"]
        db.session.commit()
        updated_trip = trip.to_dict()
        socketio.emit("trip_updated", updated_trip)
        return jsonify({"ok": True, "trip": updated_trip})
    except Exception:
        db.session.rollback()
        app.logger.exception("Trip photo upload failed for trip %s", trip_id)
        return jsonify({"ok": False, "error": "Photo upload failed"}), 500
    finally:
        if os.path.isdir(staging_directory):
            shutil.rmtree(staging_directory, ignore_errors=True)


@app.route("/uploads/<path:filename>", methods=["GET"])
def uploaded_trip_photo(filename):
    response = send_from_directory(
        UPLOAD_ROOT,
        filename,
        mimetype="image/webp",
        max_age=31536000,
        conditional=True,
    )
    response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
    return response


@app.route("/api/trips/<string:trip_id>", methods=["DELETE"])
def delete_trip_rest(trip_id: str):
    """Deletes the trip PERMANENTLY from the server database and broadcasts
    `trip_deleted` to ALL connected clients.

    Flow: `_delete_trip_by_id` runs `db.session.delete(trip)` +
    `db.session.commit()`, then `socketio.emit('trip_deleted', {'id': ...})`
    fires to every passenger/driver so the trip instantly disappears from
    all client lists and never reappears on refresh.
    """
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    trip = db.session.get(Trip, trip_id)
    if trip is None:
        return jsonify({"ok": False, "error": "Trip not found"}), 404
    if trip.owner_uid != owner_uid:
        return jsonify({"ok": False, "error": "Not authorized"}), 403
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
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    payload = request.get_json(silent=True) or {}
    booking = db.session.get(Booking, booking_id)
    if booking is None:
        return jsonify({"ok": False, "error": "Booking not found"}), 404
    trip = db.session.get(Trip, booking.trip_id)
    if trip is None or trip.owner_uid != owner_uid:
        return jsonify({"ok": False, "error": "Not authorized"}), 403
    if trip.status == "completed":
        return jsonify({"ok": False, "error": "Trip is already completed"}), 409
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
        car_brand=_optional_trip_string(data.get("car_brand")),
        car_model=_optional_trip_string(data.get("car_model")),
        car_color=_optional_trip_string(data.get("car_color")),
        car_plate=_optional_trip_string(data.get("car_plate")),
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
    token = str(data.get("id_token", "")).strip() if isinstance(data, dict) else ""
    if not token:
        return {"ok": False, "error": "Authentication required"}
    try:
        owner_uid = _firebase_uid_for_token(token)
    except Exception:
        return {"ok": False, "error": "Not authorized"}
    trip = db.session.get(Trip, str(trip_id))
    if trip is not None and trip.owner_uid != owner_uid:
        return {"ok": False, "error": "Not authorized"}
    deleted = _delete_trip_by_id(trip_id)
    if deleted:
        return {"ok": True, "id": str(trip_id)}
    return {"ok": False, "error": "Trip not found"}


@socketio.on("end_trip_broadcast")
def handle_end_trip_broadcast(data):
    data = data or {}
    trip_id = str(data.get("trip_id", "")).strip()
    token = str(data.get("id_token", "")).strip()
    if not token:
        return {"ok": False, "error": "Authentication required"}
    try:
        owner_uid = _firebase_uid_for_token(token)
    except Exception:
        return {"ok": False, "error": "Not authorized"}
    trip, created, error = _complete_trip_for_owner(trip_id, owner_uid)
    if error:
        response, status = error
        return {"ok": False, "error": response.get_json().get("error"), "status": status}
    if created:
        _emit_trip_completed(trip)
    return {"ok": True, "trip_id": trip.id}


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    socketio.run(app, host="0.0.0.0", port=port, debug=False)

