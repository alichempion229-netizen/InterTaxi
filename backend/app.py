"""Flask-SocketIO backend for the InterTaxi real-time taxi application.

Drivers post trips (announcements) which are stored in SQLite and broadcast
to all connected passengers. Passengers can search active trips and book
seats on them.

Run with:
    python app.py
"""

import eventlet
eventlet.monkey_patch()
import io
import json
import os
import logging
import shutil
import tempfile
import uuid
import warnings
from datetime import datetime, timezone
from flask import Flask, request, render_template_string, send_from_directory
from flask_cors import CORS
from flask_socketio import SocketIO, emit
from sqlalchemy import MetaData, Table, inspect, text
from models import db, Trip, Booking, UserProfile
from PIL import Image, ImageOps, UnidentifiedImageError

# ---------------------------------------------------------------------------
# App & DB setup
# ---------------------------------------------------------------------------
app = Flask(__name__)
basedir = os.path.abspath(os.path.dirname(__file__))

# Prefer DATABASE_URL (e.g. Render PostgreSQL) so data survives redeploys on
# the ephemeral Render filesystem; fall back to a local SQLite file.
database_url = os.environ.get('DATABASE_URL', '').strip()
if database_url.startswith('postgres://'):
    # Older SQLAlchemy versions reject the `postgres://` scheme.
    database_url = database_url.replace('postgres://', 'postgresql://', 1)
app.config['SQLALCHEMY_DATABASE_URI'] = database_url or (
    'sqlite:///' + os.path.join(basedir, 'intertaxi.db')
)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['MAX_CONTENT_LENGTH'] = 25 * 1024 * 1024
CORS(app)
UPLOAD_ROOT = os.environ.get('UPLOAD_ROOT', os.path.join(basedir, 'uploads'))
MAX_TRIP_PHOTO_BYTES = 8 * 1024 * 1024

db.init_app(app)


def create_tables():
    """Create tables if they do not exist (idempotent).

    Runs at import time so it also executes under gunicorn (`app:app`),
    not only via `python app.py`.
    """
    with app.app_context():
        db.create_all()
        existing_columns = {
            column['name']
            for column in inspect(db.engine).get_columns('trips')
        }
        if 'duration_minutes' not in existing_columns:
            db.session.execute(
                text(
                    "ALTER TABLE trips "
                    "ADD COLUMN duration_minutes INTEGER DEFAULT 0 NOT NULL"
                )
            )
            db.session.commit()
        new_columns = {
            'car_brand': "VARCHAR(80) NULL",
            'car_model': "VARCHAR(80) NULL",
            'car_color': "VARCHAR(40) NULL",
            'car_plate': "VARCHAR(40) NULL",
            'car_photo_front': "VARCHAR(512) NULL",
            'car_photo_rear': "VARCHAR(512) NULL",
            'car_photo_side': "VARCHAR(512) NULL",
            'car_thumb_front': "VARCHAR(512) NULL",
            'car_thumb_rear': "VARCHAR(512) NULL",
            'car_thumb_side': "VARCHAR(512) NULL",
            'owner_uid': "VARCHAR(128) NULL",
            'started_at': "TIMESTAMP NULL",
        }
        for column_name, definition in new_columns.items():
            if column_name not in existing_columns:
                db.session.execute(
                    text(
                        f'ALTER TABLE trips ADD COLUMN '
                        f'{column_name} {definition}'
                    )
                )
        db.session.commit()
        if db.engine.dialect.name == 'sqlite':
            trip_info = db.session.execute(text('PRAGMA table_info(trips)')).fetchall()
            nullable_car_columns = {'car_brand', 'car_model', 'car_color', 'car_plate'}
            if any(row[1] in nullable_car_columns and row[3] for row in trip_info):
                bind = db.engine
                existing_trip = Table('trips', MetaData(), autoload_with=bind)
                migration_metadata = MetaData()
                migration_name = 'trips_nullable_migration'
                if inspect(bind).has_table(migration_name):
                    Table(migration_name, MetaData(), autoload_with=bind).drop(bind)
                migrated_trip = existing_trip.to_metadata(
                    migration_metadata,
                    name=migration_name,
                )
                for column_name in nullable_car_columns:
                    migrated_trip.c[column_name].nullable = True
                for index in tuple(migrated_trip.indexes):
                    migrated_trip.indexes.remove(index)
                migrated_trip.create(bind)
                quote = bind.dialect.identifier_preparer.quote
                column_names = [column.name for column in existing_trip.columns]
                quoted_columns = ', '.join(quote(name) for name in column_names)
                schema_objects = db.session.execute(
                    text(
                        "SELECT sql FROM sqlite_master "
                        "WHERE tbl_name = 'trips' "
                        "AND type IN ('index', 'trigger') AND sql IS NOT NULL"
                    )
                ).scalars().all()
                db.session.commit()
                with bind.begin() as connection:
                    connection.execute(
                        text(
                            f'INSERT INTO {quote(migration_name)} ({quoted_columns}) '
                            f'SELECT {quoted_columns} FROM {quote("trips")}'
                        )
                    )
                    connection.execute(text('DROP TABLE trips'))
                    connection.execute(
                        text(
                            f'ALTER TABLE {quote(migration_name)} '
                            f'RENAME TO {quote("trips")}'
                        )
                    )
                    for schema_sql in schema_objects:
                        connection.execute(text(schema_sql))
        if db.engine.dialect.name == 'postgresql':
            trip_columns = {
                column['name']: column
                for column in inspect(db.engine).get_columns('trips')
            }
            for column_name in ('car_brand', 'car_model', 'car_color', 'car_plate'):
                if not trip_columns[column_name]['nullable']:
                    db.session.execute(
                        text(
                            f'ALTER TABLE trips ALTER COLUMN {column_name} '
                            'DROP NOT NULL'
                        )
                    )
        booking_columns = {
            'status': "VARCHAR(16) DEFAULT 'pending' NOT NULL",
            'decision_message': "VARCHAR(255) DEFAULT '' NOT NULL",
            'requested_seats': "INTEGER DEFAULT 1 NOT NULL",
            'passenger_uid': 'VARCHAR(128) NULL',
        }
        booking_existing = {
            column['name']
            for column in inspect(db.engine).get_columns('bookings')
        }
        for column_name, definition in booking_columns.items():
            if column_name not in booking_existing:
                db.session.execute(
                    text(
                        f'ALTER TABLE bookings ADD COLUMN '
                        f'{column_name} {definition}'
                    )
                )
        profile_existing = {
            column['name']
            for column in inspect(db.engine).get_columns('user_profiles')
        }
        for column_name in ('avatar_url', 'push_token'):
            if column_name not in profile_existing:
                db.session.execute(
                    text(
                        f'ALTER TABLE user_profiles ADD COLUMN '
                        f'{column_name} VARCHAR(512) NULL'
                    )
                )
        db.session.commit()


create_tables()

# Роҳи асосии сервер, то дар браузер хатогӣ надиҳад
@app.route('/')
def home():
    return {"status": "online", "message": "InterTaxi Backend is running!"}, 200

socketio = SocketIO(app, cors_allowed_origins='*', async_mode='eventlet')

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)


def _firebase_uid_for_token(token):
    """Verify a Firebase ID token using Google's public signing certificates.

    This checks the token signature and Firebase project audience without
    requiring a service-account credential on the backend.
    """
    from google.auth.transport.requests import Request
    from google.oauth2 import id_token

    project_id = os.environ.get('FIREBASE_PROJECT_ID', 'intertaxi-5b711')
    claims = id_token.verify_firebase_token(
        token, Request(), audience=project_id
    )
    uid = str(claims.get('sub', '')).strip()
    if not uid:
        raise ValueError('Firebase token has no uid')
    return uid


def _firebase_uid_from_request():
    authorization = request.headers.get('Authorization', '')
    scheme, _, token = authorization.partition(' ')
    if scheme.lower() != 'bearer' or not token.strip():
        return None, ({'ok': False, 'error': 'Authentication required'}, 401)
    try:
        return _firebase_uid_for_token(token.strip()), None
    except ImportError:
        return None, ({'ok': False, 'error': 'Authentication is unavailable'}, 503)
    except Exception as error:
        logger.warning('Rejected invalid Firebase ID token', exc_info=True)
        return None, ({'ok': False, 'error': 'Not authorized'}, 401)


def send_push(user_id, title, body, data=None):
    profile = db.session.get(UserProfile, str(user_id)) if user_id else None
    if profile is None or not profile.push_token:
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials, messaging

        try:
            firebase_admin.get_app()
        except ValueError:
            service_account = os.environ.get('FIREBASE_SERVICE_ACCOUNT_JSON', '').strip()
            if not service_account:
                return False
            firebase_admin.initialize_app(
                credentials.Certificate(json.loads(service_account))
            )
        messaging.send(messaging.Message(
            token=profile.push_token,
            notification=messaging.Notification(title=title, body=body),
            data={str(key): str(value) for key, value in (data or {}).items()},
            android=messaging.AndroidConfig(
                priority='high',
                notification=messaging.AndroidNotification(channel_id='intertaxi'),
            ),
        ))
        return True
    except Exception:
        logger.exception('Could not send push notification to %s', user_id)
        return False


# ---------------------------------------------------------------------------
# REST endpoints
# ---------------------------------------------------------------------------
@app.route('/')
def index():
    """Show all trips in a simple HTML page for debugging."""
    trips = Trip.query.order_by(Trip.created_at.desc()).all()
    html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>InterTaxi - Trips</title>
        <meta http-equiv="refresh" content="5">
        <style>
            body { font-family: Arial; margin: 20px; background: #f5f5f5; }
            h1 { color: #0066FF; }
            .trip { background: white; padding: 15px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
            .route { font-size: 18px; font-weight: bold; }
            .details { color: #666; margin-top: 5px; }
            .status { display: inline-block; padding: 3px 8px; border-radius: 4px; font-size: 12px; font-weight: bold; }
            .active { background: #4CAF50; color: white; }
            .booked { background: #999; color: white; }
            .empty { text-align: center; padding: 40px; color: #999; }
            .stats { background: #0066FF; color: white; padding: 10px 15px; border-radius: 8px; margin-bottom: 20px; }
        </style>
    </head>
    <body>
        <h1>🚗 InterTaxi - Live Trips</h1>
        <div class="stats">
            Total trips: ''' + str(len(trips)) + ''' | Auto-refresh: 5s
        </div>
        <a href="/api/trips" style="color:#0066FF;">View JSON API</a>
        <hr>
    '''
    if not trips:
        html += '<div class="empty"><h2>No trips posted yet</h2><p>Post a trip from the Flutter app and refresh this page</p></div>'
    else:
        for t in trips:
            html += f'''
            <div class="trip">
                <span class="status {'active' if t.status == 'active' else 'booked'}">{t.status.upper()}</span>
                <div class="route">📍 {t.from_location} → {t.to_location}</div>
                <div class="details">
                    💰 Price: {t.price} Somoni &nbsp;|&nbsp; 🪑 Seats: {t.available_seats}<br>
                    🕐 Departure: {t.departure_time}<br>
                    👤 Driver: {t.driver_name or 'N/A'} &nbsp;|&nbsp; 📞 {t.driver_phone or 'N/A'}
                </div>
            </div>
            '''
    html += '</body></html>'
    return render_template_string(html)


def _create_trip(data, fallback_driver_id='rest', owner_uid=None):
    """Validate payload and persist a new trip announcement.

    Shared by the Socket.IO ``post_trip`` handler and the REST
    ``POST /api/trips`` endpoint so both paths behave identically.

    Returns a ``(trip_or_None, error_or_None)`` tuple.
    """
    if not isinstance(data, dict):
        return None, 'Invalid payload — expected JSON object'

    required = ['from_location', 'to_location', 'departure_time', 'price', 'available_seats']
    missing = [f for f in required if f not in data or not str(data[f]).strip()]
    if missing:
        return None, f'Missing required fields: {", ".join(missing)}'

    try:
        price = int(data['price'])
        seats = int(data['available_seats'])
        if price <= 0 or seats <= 0:
            raise ValueError
    except (ValueError, TypeError):
        return None, 'Price and available_seats must be positive integers'

    trip = Trip(
        driver_id=data.get('driver_id', fallback_driver_id),
        owner_uid=owner_uid,
        driver_name=data.get('driver_name', '').strip(),
        driver_phone=data.get('driver_phone', '').strip(),
        from_location=data['from_location'].strip(),
        to_location=data['to_location'].strip(),
        departure_time=data['departure_time'],
        duration_minutes=int(data.get('duration_minutes') or 0),
        car_brand=str(data.get('car_brand') or '').strip() or None,
        car_model=str(data.get('car_model') or '').strip() or None,
        car_color=str(data.get('car_color') or '').strip() or None,
        car_plate=str(data.get('car_plate') or '').strip() or None,
        price=price,
        available_seats=seats,
        status='active',
    )
    db.session.add(trip)
    db.session.commit()
    return trip, None


@app.route('/api/trips', methods=['GET'])
def get_trips_rest():
    """Return all active trips as JSON."""
    trips = Trip.query.filter_by(status='active').order_by(Trip.created_at.desc()).all()
    return {'trips': [t.to_dict() for t in trips]}, 200


@app.route('/api/trips', methods=['POST'])
def create_trip_rest():
    """Create a trip announcement via a plain HTTP POST (JSON body).

    This is the REST fallback used by the Flutter app so driver
    announcements reach the backend (and the web UI at ``/``) even when
    no Socket.IO connection is active.
    """
    owner_uid, auth_error = _firebase_uid_from_request()
    if auth_error:
        return auth_error

    data = request.get_json(silent=True) or {}
    trip, error = _create_trip(data, owner_uid=owner_uid)
    if error:
        return {'error': error}, 400
    logger.info(
        f'REST trip posted: {trip.id} | '
        f'{trip.from_location} -> {trip.to_location}'
    )
    # Notify connected passengers in real time as well.
    socketio.emit('new_trip', trip.to_dict())
    return {'trip': trip.to_dict()}, 201


@app.route('/api/trips/<trip_id>/photos', methods=['POST'])
def upload_trip_photos(trip_id):
    owner_uid, auth_error = _firebase_uid_from_request()
    if auth_error:
        return auth_error
    trip = db.session.get(Trip, trip_id)
    if trip is None:
        return {'ok': False, 'error': 'Trip not found'}, 404
    if trip.owner_uid != owner_uid:
        return {'ok': False, 'error': 'Not authorized'}, 403

    labels = ('front', 'rear', 'side')
    uploads = {label: request.files.get(label) for label in labels}
    if any(upload is None for upload in uploads.values()):
        return {'ok': False, 'error': 'All three photos are required'}, 400

    safe_trip_id = trip.id.replace('/', '_').replace('\\', '_')
    trip_directory = os.path.join(UPLOAD_ROOT, f'trip_{safe_trip_id}')
    os.makedirs(UPLOAD_ROOT, exist_ok=True)
    staging_directory = tempfile.mkdtemp(
        prefix=f'.trip_{safe_trip_id}_', dir=UPLOAD_ROOT
    )
    timestamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    generated_paths = {}
    try:
        for label, upload in uploads.items():
            image_bytes = upload.stream.read(MAX_TRIP_PHOTO_BYTES + 1)
            if len(image_bytes) > MAX_TRIP_PHOTO_BYTES:
                return {'ok': False, 'error': 'Each photo must be 8 MB or smaller'}, 413
            try:
                with warnings.catch_warnings():
                    warnings.simplefilter('error', Image.DecompressionBombWarning)
                    image = Image.open(io.BytesIO(image_bytes))
                    if image.format not in {'JPEG', 'PNG', 'WEBP'}:
                        return {'ok': False, 'error': 'Photos must be JPG, PNG, or WebP images'}, 400
                    image.load()
                    image = ImageOps.exif_transpose(image).convert('RGB')
                image.thumbnail((1280, 1280), Image.Resampling.LANCZOS)
                full_name = f'{label}_{timestamp}.webp'
                thumb_name = f'{label}_{timestamp}_thumb.webp'
                image.save(
                    os.path.join(staging_directory, full_name),
                    format='WEBP', quality=80, method=6,
                )
                thumbnail = image.copy()
                thumbnail.thumbnail((360, 360), Image.Resampling.LANCZOS)
                thumbnail.save(
                    os.path.join(staging_directory, thumb_name),
                    format='WEBP', quality=70, method=6,
                )
                generated_paths[label] = (
                    f'/uploads/trip_{safe_trip_id}/{full_name}',
                    f'/uploads/trip_{safe_trip_id}/{thumb_name}',
                )
            except (
                Image.DecompressionBombError,
                Image.DecompressionBombWarning,
                OSError,
                UnidentifiedImageError,
                ValueError,
            ):
                return {'ok': False, 'error': 'A photo is not a valid supported image'}, 400

        shutil.rmtree(trip_directory, ignore_errors=True)
        os.replace(staging_directory, trip_directory)
        trip.car_photo_front, trip.car_thumb_front = generated_paths['front']
        trip.car_photo_rear, trip.car_thumb_rear = generated_paths['rear']
        trip.car_photo_side, trip.car_thumb_side = generated_paths['side']
        db.session.commit()
        updated_trip = trip.to_dict()
        socketio.emit('trip_updated', updated_trip)
        return {'ok': True, 'trip': updated_trip}, 200
    except Exception:
        db.session.rollback()
        app.logger.exception('Trip photo upload failed for trip %s', trip_id)
        return {'ok': False, 'error': 'Photo upload failed'}, 500
    finally:
        if os.path.isdir(staging_directory):
            shutil.rmtree(staging_directory, ignore_errors=True)


@app.route('/api/users/<user_id>', methods=['GET'])
def get_user_profile(user_id):
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    if owner_uid != user_id:
        return {'ok': False, 'error': 'Not authorized'}, 403
    profile = db.session.get(UserProfile, user_id)
    return {'user': profile.to_dict() if profile else {'uid': user_id, 'avatar_url': None}}, 200


@app.route('/api/users/<user_id>/avatar', methods=['POST'])
def upload_user_avatar(user_id):
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    if owner_uid != user_id:
        return {'ok': False, 'error': 'Not authorized'}, 403
    uploaded = request.files.get('file')
    if uploaded is None:
        return {'ok': False, 'error': 'Image file is required'}, 400
    try:
        image = Image.open(uploaded.stream)
        image = ImageOps.exif_transpose(image).convert('RGB')
        image.thumbnail((512, 512), Image.Resampling.LANCZOS)
        directory = os.path.join(UPLOAD_ROOT, 'avatars')
        os.makedirs(directory, exist_ok=True)
        filename = f'{user_id}_{int(datetime.now(timezone.utc).timestamp() * 1000)}.webp'
        image.save(os.path.join(directory, filename), 'WEBP', quality=80)
    except (Image.DecompressionBombError, OSError, UnidentifiedImageError, ValueError):
        return {'ok': False, 'error': 'Invalid image'}, 400
    avatar_url = f'/uploads/avatars/{filename}'
    profile = db.session.get(UserProfile, user_id) or UserProfile(uid=user_id)
    profile.avatar_url = avatar_url
    db.session.add(profile)
    db.session.commit()
    return {'ok': True, 'avatar_url': f'{request.url_root.rstrip("/")}{avatar_url}'}, 200


@app.route('/api/users/<user_id>/push-token', methods=['POST'])
def save_push_token(user_id):
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error
    if owner_uid != user_id:
        return {'ok': False, 'error': 'Not authorized'}, 403
    token = str((request.get_json(silent=True) or {}).get('token', '')).strip()
    if not token:
        return {'ok': False, 'error': 'Push token is required'}, 400
    profile = db.session.get(UserProfile, user_id) or UserProfile(uid=user_id)
    profile.push_token = token
    db.session.add(profile)
    db.session.commit()
    return {'ok': True}, 200


@app.route('/uploads/<path:filename>', methods=['GET'])
def uploaded_trip_photo(filename):
    response = send_from_directory(
        UPLOAD_ROOT,
        filename,
        mimetype='image/webp',
        max_age=31536000,
        conditional=True,
    )
    response.headers['Cache-Control'] = 'public, max-age=31536000, immutable'
    return response


@app.route('/api/trips/<trip_id>/start', methods=['POST'])
def start_trip_rest(trip_id):
    """Start an owned trip after verifying the Firebase bearer token."""
    owner_uid, error = _firebase_uid_from_request()
    if error:
        return error

    trip = db.session.get(Trip, trip_id)
    if trip is None:
        return {'ok': False, 'error': 'Trip not found'}, 404
    if trip.owner_uid != owner_uid:
        print(
            f"START 403 token_uid={owner_uid!r} trip_id={trip.id!r} "
            f"driver_id={getattr(trip, 'driver_id', None)!r} "
            f"owner_uid={trip.owner_uid!r} status={trip.status!r}",
            flush=True,
        )
        return {'ok': False, 'error': 'Not authorized'}, 403
    if trip.status not in {'active', 'booked'}:
        return {'ok': False, 'error': 'Trip cannot be started'}, 409
    if trip.started_at is None:
        trip.started_at = datetime.utcnow()
        db.session.commit()
    return {
        'ok': True,
        'trip_id': trip.id,
        'started_at': trip.started_at.isoformat() + 'Z',
    }, 200


@app.route('/api/trips/search', methods=['GET'])
def search_trips_rest():
    """Search active trips by from/to location (case-insensitive partial match)."""
    from_loc = request.args.get('from', '').strip()
    to_loc = request.args.get('to', '').strip()
    query = Trip.query.filter_by(status='active')
    if from_loc:
        query = query.filter(Trip.from_location.ilike(f'%{from_loc}%'))
    if to_loc:
        query = query.filter(Trip.to_location.ilike(f'%{to_loc}%'))
    trips = query.order_by(Trip.departure_time.asc()).all()
    return {'trips': [t.to_dict() for t in trips]}, 200


@app.route('/api/trips/<trip_id>/book', methods=['POST'])
def book_trip_rest(trip_id):
    """Book one seat on a trip (REST fallback)."""
    trip = Trip.query.get(trip_id)
    if not trip:
        return {'error': 'Trip not found'}, 404
    if trip.status != 'active' or trip.available_seats <= 0:
        return {'error': 'No seats available'}, 400
    trip.available_seats -= 1
    if trip.available_seats == 0:
        trip.status = 'booked'
    db.session.commit()
    socketio.emit('trip_updated', trip.to_dict())
    return {'trip': trip.to_dict()}, 200


def _create_booking(data, passenger_uid=None):
    """Persist a booking and notify connected drivers after commit."""
    if not isinstance(data, dict):
        return None, 'Invalid payload — expected JSON object'
    trip_id = str(data.get('trip_id', '')).strip()
    trip = db.session.get(Trip, trip_id) if trip_id else None
    if not trip:
        return None, 'Trip not found'

    passenger_phone = str(data.get('passenger_phone', '')).strip()
    if not passenger_phone:
        return None, 'Passenger phone is required'
    duplicate = Booking.query.filter_by(
        trip_id=trip.id,
        passenger_phone=passenger_phone,
    ).first()
    if duplicate is not None:
        return None, 'Шумо аллакай дархост фиристодед, лутфан мунтазир монед.'
    try:
        requested_seats = int(data.get('requested_seats', 1))
    except (TypeError, ValueError):
        requested_seats = 0
    if requested_seats < 1:
        return None, 'Шумораи ҷойҳо нодуруст аст'
    pending_seats = db.session.query(
        db.func.coalesce(db.func.sum(Booking.requested_seats), 0)
    ).filter_by(trip_id=trip.id, status='pending').scalar()
    if trip.status != 'active' or trip.available_seats - int(pending_seats or 0) < requested_seats:
        return None, 'No seats available on this trip'

    booking = Booking(
        trip_id=trip.id,
        driver_id=trip.driver_id,
        passenger_name=str(data.get('passenger_name', '')).strip(),
        passenger_phone=passenger_phone,
        passenger_uid=passenger_uid,
        from_location=trip.from_location,
        to_location=trip.to_location,
        requested_seats=requested_seats,
    )
    db.session.add(booking)
    db.session.commit()
    socketio.emit('trip_updated', trip.to_dict())
    socketio.emit('passenger_booked', booking.to_dict())
    send_push(
        trip.owner_uid,
        'New booking request',
        f'{booking.passenger_name or booking.passenger_phone} requested a seat',
        {'type': 'alert', 'event': 'booking_request', 'booking_id': booking.id},
    )
    return {'booking': booking.to_dict(), 'trip': trip.to_dict()}, None


@app.route('/api/bookings', methods=['GET'])
def get_bookings_rest():
    driver_id = request.args.get('driver_id', '').strip()
    passenger_phone = request.args.get('passenger_phone', '').strip()
    if not driver_id and not passenger_phone:
        return {'bookings': []}, 200
    query = Booking.query
    if driver_id:
        query = query.filter_by(driver_id=driver_id)
    if passenger_phone:
        query = query.filter_by(passenger_phone=passenger_phone)
    bookings = query.order_by(Booking.created_at.desc()).all()
    return {'bookings': [booking.to_dict() for booking in bookings]}, 200


@app.route('/api/bookings', methods=['POST'])
def create_booking_rest():
    passenger_uid = None
    if request.headers.get('Authorization'):
        passenger_uid, auth_error = _firebase_uid_from_request()
        if auth_error:
            return auth_error
    result, error = _create_booking(
        request.get_json(silent=True) or {}, passenger_uid=passenger_uid
    )
    if error:
        status = 404 if error == 'Trip not found' else 409
        return {'ok': False, 'error': error}, status
    return {'ok': True, **result}, 201


@app.route('/api/bookings', methods=['DELETE'])
def delete_bookings_rest():
    driver_id = request.args.get('driver_id', '').strip()
    passenger_phone = request.args.get('passenger_phone', '').strip()
    if not driver_id and not passenger_phone:
        return {'ok': False, 'error': 'User identifier is required'}, 400
    query = Booking.query
    if driver_id:
        query = query.filter_by(driver_id=driver_id)
    if passenger_phone:
        query = query.filter_by(passenger_phone=passenger_phone)
    deleted = query.delete(synchronize_session=False)
    db.session.commit()
    return {'ok': True, 'deleted': deleted}, 200


@app.route('/api/bookings/<booking_id>/decision', methods=['POST'])
def decide_booking_rest(booking_id):
    """Driver accepts or rejects a passenger booking."""
    data = request.get_json(silent=True) or {}
    decision = str(data.get('decision', '')).strip().lower()
    driver_id = str(data.get('driver_id', '')).strip()
    booking = db.session.get(Booking, booking_id)
    if booking is None:
        return {'ok': False, 'error': 'Booking not found'}, 404
    if driver_id and booking.driver_id != driver_id:
        return {'ok': False, 'error': 'Booking does not belong to this driver'}, 403
    if decision not in ('approved', 'rejected'):
        return {'ok': False, 'error': 'Invalid decision'}, 400
    if booking.status != 'pending':
        return {'ok': False, 'error': 'Booking already decided'}, 409

    trip = db.session.get(Trip, booking.trip_id)
    if decision == 'approved':
        if trip is None or trip.status != 'active' or trip.available_seats < booking.requested_seats:
            return {'ok': False, 'error': 'Ҷойҳои кофӣ дар мошин намонд'}, 409
        trip.available_seats -= booking.requested_seats
        if trip.available_seats == 0:
            trip.status = 'booked'

    booking.status = decision
    booking.decision_message = (
        'Аъло, шумо ҷойро аллакай брон кардед, метавонед ба терминал ҳозир шавед.'
        if decision == 'approved'
        else 'Ба шумо рафтан иҷозат дода нашуд.'
    )
    if decision == 'rejected':
        pass
    db.session.commit()
    payload = booking.to_dict()
    if trip is not None:
        socketio.emit('trip_updated', trip.to_dict())
    socketio.emit('booking_decision', payload)
    send_push(
        booking.passenger_uid,
        'Booking update',
        booking.decision_message or booking.status,
        {'type': 'alert', 'event': 'booking_decision', 'booking_id': booking.id},
    )
    return {
        'ok': True,
        'booking': payload,
        'trip': trip.to_dict() if trip is not None else None,
    }, 200


@app.route('/api/trips/<trip_id>', methods=['DELETE'])
def delete_trip_rest(trip_id):
    """PERMANENTLY delete a trip announcement (REST).

    This is the primary delete path used by the Flutter driver app: the row
    is removed from the database and a `trip_deleted` event is broadcast to
    ALL connected clients so every driver/passenger list updates instantly.
    """
    trip = Trip.query.get(trip_id)
    if not trip:
        return {'ok': False, 'error': 'Trip not found'}, 404
    db.session.delete(trip)
    db.session.commit()
    logger.info(f'Trip deleted via REST: {trip_id}')
    socketio.emit('trip_deleted', {'id': str(trip_id)})
    return {'ok': True, 'id': str(trip_id)}, 200


@app.route('/api/health', methods=['GET'])
def health():
    """Health check endpoint for Render / uptime monitors."""
    return {
        'status': 'ok',
        'active_trips': Trip.query.filter_by(status='active').count(),
        'booking_notifications': 'durable-v2',
    }, 200


# ---------------------------------------------------------------------------
# Socket.IO events
# ---------------------------------------------------------------------------
@socketio.on('connect')
def handle_connect():
    """Send the current list of active trips to the newly connected client."""
    logger.info(f'Client connected: {request.sid}')
    trips = Trip.query.filter_by(status='active').order_by(Trip.created_at.desc()).all()
    emit('trips_list', {'trips': [t.to_dict() for t in trips]})


@socketio.on('disconnect')
def handle_disconnect():
    logger.info(f'Client disconnected: {request.sid}')


@socketio.on('post_trip')
def handle_post_trip(data):
    """Driver posts a new trip announcement.

    Expected payload:
        driver_id, driver_name, driver_phone,
        from_location, to_location, departure_time,
        price (int), available_seats (int)
    """
    log_data = dict(data) if isinstance(data, dict) else data
    if isinstance(log_data, dict):
        log_data.pop('token', None)
        log_data.pop('id_token', None)
    logger.info(f'📥 post_trip received: {log_data}')

    token = (
        (data.get('token') or data.get('id_token'))
        if isinstance(data, dict)
        else None
    )
    if not token:
        emit('error', {'message': 'Authentication required'})
        return
    try:
        owner_uid = _firebase_uid_for_token(str(token))
    except Exception:
        emit('error', {'message': 'Authentication required'})
        return

    trip_data = {
        key: value for key, value in data.items()
        if key not in {'token', 'id_token'}
    }
    trip, error = _create_trip(
        trip_data,
        fallback_driver_id=request.sid,
        owner_uid=owner_uid,
    )
    if error:
        emit('error', {'message': error})
        return

    logger.info(f'New trip posted: {trip.id} | {trip.from_location} -> {trip.to_location}')

    # Broadcast to ALL connected clients (including the poster)
    emit('new_trip', trip.to_dict(), broadcast=True)


@socketio.on('delete_trip')
def handle_delete_trip(data):
    """Driver deletes one of their trips.

    Expected payload: {'trip_id': '<uuid>'} (also accepts the bare id).
    The trip is removed from the database and `trip_deleted` with
    {'id': ...} is broadcast to ALL connected clients (drivers AND
    passengers) so their lists update in real time.
    """
    trip_id = None
    if isinstance(data, dict):
        trip_id = data.get('trip_id') or data.get('id')
    elif data is not None:
        trip_id = data

    trip_id = str(trip_id).strip() if trip_id is not None else ''
    if not trip_id:
        return {'ok': False, 'error': 'trip_id is required'}

    trip = Trip.query.get(trip_id)
    if not trip:
        return {'ok': False, 'error': 'Trip not found'}

    db.session.delete(trip)
    db.session.commit()
    logger.info(f'Trip deleted via socket: {trip_id}')
    socketio.emit('trip_deleted', {'id': trip_id})
    return {'ok': True, 'id': trip_id}


@socketio.on('get_trips')
def handle_get_trips(data=None):
    """Return active trips, optionally filtered by from/to location.

    Optional payload:
        from (str): partial origin match
        to (str): partial destination match
    """
    query = Trip.query.filter_by(status='active')

    if isinstance(data, dict):
        from_filter = data.get('from', '').strip()
        to_filter = data.get('to', '').strip()
        if from_filter:
            query = query.filter(Trip.from_location.ilike(f'%{from_filter}%'))
        if to_filter:
            query = query.filter(Trip.to_location.ilike(f'%{to_filter}%'))

    trips = query.order_by(Trip.departure_time.asc()).all()
    emit('trips_list', {'trips': [t.to_dict() for t in trips]})


@socketio.on('book_trip')
def handle_book_trip(data):
    """Passenger books one seat on a trip.

    Expected payload:
        trip_id (str)
        passenger_name (str, optional)
        passenger_phone (str, optional)
    """
    if not isinstance(data, dict):
        emit('error', {'message': 'Invalid payload — expected JSON object'})
        return

    result, error = _create_booking(data)
    if error:
        emit('error', {'message': error})
        return
    booking = result['booking']
    trip = result['trip']

    logger.info(
        f'Trip {trip["id"]} booked by {booking["passenger_name"] or "unknown"}'
    )

    # Confirm to the booker
    emit('booking_confirmed', {
        'trip_id': trip['id'],
        'trip': trip,
        'passenger_name': booking['passenger_name'],
        'passenger_phone': booking['passenger_phone'],
    })

    # Broadcast updated trip to everyone so lists stay in sync
    emit('trip_updated', trip, broadcast=True)

    # Return an acknowledgement for clients that use Socket.IO booking
    # directly; REST clients already receive the persisted booking response.
    return {'ok': True, 'booking': booking, 'trip': trip}


# ---------------------------------------------------------------------------
# Legacy order events (kept so the older order-based screens keep working)
# ---------------------------------------------------------------------------
@socketio.on('new_order')
def handle_new_order(data):
    """Broadcast a passenger ride request to all drivers."""
    if not isinstance(data, dict):
        emit('error', {'message': 'Invalid payload — expected JSON object'})
        return
    order = dict(data)
    if not order.get('order_id'):
        order['order_id'] = str(uuid.uuid4())
    socketio.emit('new_order', order)


@socketio.on('accept_order')
def handle_accept_order(data):
    """Broadcast that a driver accepted an order."""
    if isinstance(data, dict):
        socketio.emit('accept_order', dict(data))


@socketio.on('update_location')
def handle_update_location(data):
    """Relay driver GPS updates to everyone else (location streams)."""
    if isinstance(data, dict):
        socketio.emit('update_location', dict(data), skip_sid=request.sid)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if __name__ == '__main__':
    print('\n' + '='*60)
    print('  InterTaxi Flask Server Started!')
    print('  Web UI:     http://localhost:5000')
    print('  API:       http://localhost:5000/api/trips')
    print('  Socket.IO: http://localhost:5000')
    print('='*60 + '\n')

    port = int(os.environ.get("PORT", 5000))
    socketio.run(app, host='0.0.0.0', port=port, debug=False)
