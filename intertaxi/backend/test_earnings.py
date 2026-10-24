"""Focused tests for authenticated, idempotent driver earnings."""
import os
import sys
import tempfile
import unittest
import atexit
from datetime import datetime, timedelta, timezone

_test_database_directory = tempfile.TemporaryDirectory(prefix="intertaxi-earnings-")
_test_database_path = os.path.join(_test_database_directory.name, "earnings.sqlite")
os.environ["DATABASE_URL"] = f"sqlite:///{_test_database_path.replace(os.sep, '/')}"
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import app as backend  # noqa: E402


def _cleanup_test_database():
    with backend.app.app_context():
        backend.db.session.remove()
        backend.db.engine.dispose()
    _test_database_directory.cleanup()


atexit.register(_cleanup_test_database)


class EarningsTest(unittest.TestCase):
    def setUp(self):
        with backend.app.app_context():
            backend.db.drop_all()
            backend.db.create_all()
        self.client = backend.app.test_client()
        self.original_token_verifier = backend._firebase_uid_for_token
        backend._firebase_uid_for_token = lambda token: token.removeprefix("test-")

    def tearDown(self):
        backend._firebase_uid_for_token = self.original_token_verifier
        with backend.app.app_context():
            backend.db.session.remove()

    @staticmethod
    def headers(uid=None):
        return {"Authorization": f"Bearer test-{uid}"} if uid else {}

    def create_trip(self, uid="driver-a", phone="992900000001"):
        response = self.client.post(
            "/api/trips",
            headers=self.headers(uid),
            json={
                "driver_id": phone,
                "driver_phone": phone,
                "driver_name": "Test Driver",
                "from_location": "Кӯлоб",
                "to_location": "Душанбе",
                "price": 125,
                "available_seats": 3,
            },
        )
        self.assertEqual(response.status_code, 201, response.get_json())
        return response.get_json()["trip"]

    def test_completion_records_one_private_earning_and_filters_by_period(self):
        trip = self.create_trip()
        trip_id = trip["id"]

        self.assertEqual(
            self.client.get("/api/earnings?period=all", headers=self.headers("driver-a"))
            .get_json()["total"],
            0,
        )
        self.assertEqual(
            self.client.post(
                f"/api/trips/{trip_id}/start", headers=self.headers("driver-b")
            ).status_code,
            403,
        )
        self.assertEqual(
            self.client.post(f"/api/trips/{trip_id}/start").status_code,
            401,
        )
        self.assertEqual(
            self.client.post(
                f"/api/trips/{trip_id}/complete", headers=self.headers("driver-a")
            ).status_code,
            409,
        )

        started = self.client.post(
            f"/api/trips/{trip_id}/start", headers=self.headers("driver-a")
        )
        self.assertEqual(started.status_code, 200, started.get_json())
        self.assertTrue(started.get_json()["ok"])
        self.assertEqual(started.get_json()["trip_id"], trip_id)
        self.assertTrue(started.get_json()["started_at"])
        with backend.app.app_context():
            persisted_trip = backend.db.session.get(backend.Trip, trip_id)
            self.assertEqual(persisted_trip.owner_uid, "driver-a")
            self.assertIsNotNone(persisted_trip.started_at)
        with backend.app.app_context():
            backend.db.session.add(backend.Booking(
                trip_id=trip_id,
                driver_id="992900000001",
                passenger_phone="992900000002",
                requested_seats=2,
                status="pending",
            ))
            backend.db.session.commit()
            booking_id = backend.Booking.query.filter_by(trip_id=trip_id).one().id

        forged_approval = self.client.post(
            f"/api/bookings/{booking_id}/decision",
            headers=self.headers("driver-b"),
            json={"driver_id": "992900000001", "decision": "approved"},
        )
        self.assertEqual(forged_approval.status_code, 403)
        approved_booking = self.client.post(
            f"/api/bookings/{booking_id}/decision",
            headers=self.headers("driver-a"),
            json={"decision": "approved"},
        )
        self.assertEqual(approved_booking.status_code, 200, approved_booking.get_json())

        first = self.client.post(
            f"/api/trips/{trip_id}/complete", headers=self.headers("driver-a")
        )
        second = self.client.post(
            f"/api/trips/{trip_id}/complete", headers=self.headers("driver-a")
        )
        self.assertEqual(first.status_code, 200, first.get_json())
        self.assertEqual(second.status_code, 200, second.get_json())

        all_time = self.client.get(
            "/api/earnings?period=all", headers=self.headers("driver-a")
        ).get_json()
        self.assertEqual(all_time["total"], 250)
        self.assertEqual(len(all_time["trips"]), 1)
        self.assertEqual(all_time["trips"][0]["trip_id"], trip_id)
        self.assertEqual(all_time["trips"][0]["earnings"], 250)

        with backend.app.app_context():
            backend.db.session.remove()
            persisted = backend.Earning.query.filter_by(trip_id=trip_id).one()
            self.assertEqual(persisted.amount, 250)

        other_driver = self.client.get(
            "/api/drivers/992900000001/earnings?period=all",
            headers=self.headers("driver-b"),
        ).get_json()
        self.assertEqual(other_driver["total"], 0)
        self.assertEqual(other_driver["trips"], [])
        self.assertEqual(
            self.client.get("/api/earnings?period=all").status_code,
            401,
        )

        with backend.app.app_context():
            earned = backend.Earning.query.filter_by(trip_id=trip_id).one()
            now = datetime.now(timezone.utc).replace(tzinfo=None)
            sample_times = [
                now,
                now - timedelta(days=8),
                now - timedelta(days=40),
                now - timedelta(days=400),
            ]
            for index, created_at in enumerate(sample_times[1:], start=1):
                backend.db.session.add(backend.Earning(
                    driver_id=earned.driver_id,
                    owner_uid="driver-a",
                    trip_id=f"date-sample-{index}",
                    amount=index * 10,
                    from_location="Восеъ",
                    to_location="Хуҷанд",
                    created_at=created_at,
                ))
            backend.db.session.commit()
            records = backend.Earning.query.filter_by(owner_uid="driver-a").all()

        local_now = datetime.now(timezone(timedelta(hours=5), "Asia/Dushanbe"))
        today = local_now.replace(hour=0, minute=0, second=0, microsecond=0)
        monday = today - timedelta(days=today.weekday())
        month = today.replace(day=1)
        year = today.replace(month=1, day=1)
        next_month = (
            month.replace(year=month.year + 1, month=1)
            if month.month == 12
            else month.replace(month=month.month + 1)
        )
        bounds = {
            "day": (today, today + timedelta(days=1)),
            "week": (monday, monday + timedelta(days=7)),
            "month": (month, next_month),
            "year": (year, year.replace(year=year.year + 1)),
        }
        for period, (start, end) in bounds.items():
            start_utc = start.astimezone(timezone.utc).replace(tzinfo=None)
            end_utc = end.astimezone(timezone.utc).replace(tzinfo=None)
            expected = sum(
                earning.amount
                for earning in records
                if start_utc <= earning.created_at < end_utc
            )
            result = self.client.get(
                f"/api/earnings?period={period}",
                headers=self.headers("driver-a"),
            )
            self.assertEqual(result.status_code, 200, result.get_json())
            self.assertEqual(result.get_json()["total"], expected, period)

        invalid = self.client.get(
            "/api/earnings?period=decade", headers=self.headers("driver-a")
        )
        self.assertEqual(invalid.status_code, 400)


if __name__ == "__main__":
    unittest.main()
