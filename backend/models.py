"""Database models for the InterTaxi backend."""

import uuid
from datetime import datetime
from flask import has_request_context, request
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class UserProfile(db.Model):
    __tablename__ = 'user_profiles'

    uid = db.Column(db.String(128), primary_key=True)
    avatar_url = db.Column(db.String(512), nullable=True)
    push_token = db.Column(db.String(512), nullable=True)

    def to_dict(self):
        return {'uid': self.uid, 'avatar_url': _upload_url(self.avatar_url)}


class Trip(db.Model):
    """Represents a driver's trip announcement.

    Fields:
        id: Unique identifier (UUID string).
        driver_id: Socket.IO user identifier of the posting driver.
        driver_name: Display name of the driver.
        driver_phone: Contact phone number of the driver.
        from_location: Origin city / location name.
        to_location: Destination city / location name.
        departure_time: ISO-8601 datetime string of scheduled departure.
        price: Price per seat (integer, in somoni).
        available_seats: Number of seats currently available.
        status: Either 'active' or 'booked'.
        created_at: Timestamp when the record was created.
    """

    __tablename__ = 'trips'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    driver_id = db.Column(db.String(128), nullable=False, index=True)
    driver_name = db.Column(db.String(128), nullable=False, default='')
    driver_phone = db.Column(db.String(32), nullable=False, default='')
    from_location = db.Column(db.String(256), nullable=False)
    to_location = db.Column(db.String(256), nullable=False)
    departure_time = db.Column(db.String(64), nullable=False)
    duration_minutes = db.Column(db.Integer, nullable=False, default=0)
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
    price = db.Column(db.Integer, nullable=False, default=0)
    available_seats = db.Column(db.Integer, nullable=False, default=0)
    status = db.Column(db.String(16), nullable=False, default='active')
    owner_uid = db.Column(db.String(128), nullable=True, index=True)
    started_at = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def to_dict(self):
        """Serialize the trip to a plain dictionary for JSON / Socket.IO."""
        car_photos = [
            self.car_photo_front,
            self.car_photo_rear,
            self.car_photo_side,
        ]
        car_photo_thumbs = [
            self.car_thumb_front,
            self.car_thumb_rear,
            self.car_thumb_side,
        ]
        return {
            'id': self.id,
            'driver_id': self.driver_id,
            'driver_name': self.driver_name,
            'driver_phone': self.driver_phone,
            'driver_avatar_url': UserProfile.query.filter_by(uid=self.owner_uid).with_entities(UserProfile.avatar_url).scalar() if self.owner_uid else None,
            'from_location': self.from_location,
            'to_location': self.to_location,
            'departure_time': self.departure_time,
            'duration_minutes': self.duration_minutes,
            'car_brand': self.car_brand,
            'car_model': self.car_model,
            'car_color': self.car_color,
            'car_plate': self.car_plate,
            'car_photo_front': _upload_url(self.car_photo_front),
            'car_photo_rear': _upload_url(self.car_photo_rear),
            'car_photo_side': _upload_url(self.car_photo_side),
            'car_thumb_front': _upload_url(self.car_thumb_front),
            'car_thumb_rear': _upload_url(self.car_thumb_rear),
            'car_thumb_side': _upload_url(self.car_thumb_side),
            'car_photos': [_upload_url(path) for path in car_photos],
            'car_photo_thumbs': [_upload_url(path) for path in car_photo_thumbs],
            'price': self.price,
            'available_seats': self.available_seats,
            'status': self.status,
            'started_at': self.started_at.isoformat() + 'Z' if self.started_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else '',
        }


def _upload_url(path):
    if not path:
        return ''
    if has_request_context():
        return f'{request.url_root.rstrip("/")}/{path.lstrip("/")}'
    return path


class Booking(db.Model):
    """A passenger booking stored for the driver's Messages page."""

    __tablename__ = 'bookings'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    trip_id = db.Column(db.String(36), nullable=False, index=True)
    driver_id = db.Column(db.String(128), nullable=False, index=True)
    passenger_name = db.Column(db.String(128), nullable=False, default='')
    passenger_phone = db.Column(db.String(32), nullable=False, default='')
    passenger_uid = db.Column(db.String(128), nullable=True, index=True)
    from_location = db.Column(db.String(256), nullable=False, default='')
    to_location = db.Column(db.String(256), nullable=False, default='')
    status = db.Column(db.String(16), nullable=False, default='pending')
    decision_message = db.Column(db.String(255), nullable=False, default='')
    requested_seats = db.Column(db.Integer, nullable=False, default=1)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'trip_id': self.trip_id,
            'driver_id': self.driver_id,
            'passenger_name': self.passenger_name,
            'passenger_phone': self.passenger_phone,
            'passenger_avatar_url': UserProfile.query.filter_by(uid=self.passenger_uid).with_entities(UserProfile.avatar_url).scalar() if self.passenger_uid else None,
            'from_location': self.from_location,
            'to_location': self.to_location,
            'status': self.status,
            'decision_message': self.decision_message,
            'requested_seats': self.requested_seats,
            'created_at': self.created_at.isoformat() if self.created_at else '',
        }
