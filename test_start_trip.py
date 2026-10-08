"""Tests for Firebase-authenticated trip start on the deployed Flask app."""
import os
import sys
import tempfile
import unittest

_test_database_directory = tempfile.TemporaryDirectory(prefix="intertaxi-start-")
_test_database_path = os.path.join(_test_database_directory.name, "start.sqlite")
os.environ["DATABASE_URL"] = f"sqlite:///{_test_database_path.replace(os.sep, '/')}"
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import app as backend  # noqa: E402


class StartTripTest(unittest.TestCase):
    def setUp(self):
        with backend.app.app_context():
            backend.db.drop_all()
            backend.db.create_all()
        self.client = backend.app.test_client()
        self.original_token_verifier = backend._firebase_uid_for_token
        backend._firebase_uid_for_token = lambda token: token

    def tearDown(self):
        backend._firebase_uid_for_token = self.original_token_verifier
        with backend.app.app_context():
            backend.db.session.remove()

    @staticmethod
    def headers(uid):
        return {"Authorization": f"Bearer {uid}"}

    def create_trip(self, uid="driver-a"):
        response = self.client.post(
            "/api/trips",
            headers=self.headers(uid),
            json={
                "driver_id": "992900000001",
                "driver_name": "Test Driver",
                "driver_phone": "992900000001",
                "from_location": "Kulob",
                "to_location": "Dushanbe",
                "departure_time": "2026-10-08T08:00:00",
                "price": 100,
                "available_seats": 2,
            },
        )
        self.assertEqual(response.status_code, 201, response.get_json())
        return response.get_json()["trip"]

    def test_authenticated_owner_starts_trip_and_timestamp_persists(self):
        trip = self.create_trip()
        response = self.client.post(
            f"/api/trips/{trip['id']}/start", headers=self.headers("driver-a")
        )
        self.assertEqual(response.status_code, 200, response.get_json())
        self.assertTrue(response.get_json()["ok"])
        self.assertEqual(response.get_json()["trip_id"], trip["id"])
        self.assertTrue(response.get_json()["started_at"])
        with backend.app.app_context():
            persisted = backend.db.session.get(backend.Trip, trip["id"])
            self.assertEqual(persisted.owner_uid, "driver-a")
            self.assertIsNotNone(persisted.started_at)

    def test_start_requires_authentication_and_trip_ownership(self):
        trip = self.create_trip()
        no_auth = self.client.post(f"/api/trips/{trip['id']}/start")
        wrong_owner = self.client.post(
            f"/api/trips/{trip['id']}/start", headers=self.headers("driver-b")
        )
        self.assertEqual(no_auth.status_code, 401, no_auth.get_json())
        self.assertEqual(wrong_owner.status_code, 403, wrong_owner.get_json())

    def test_missing_trip_returns_404_after_authentication(self):
        response = self.client.post(
            "/api/trips/missing-trip/start", headers=self.headers("driver-a")
        )
        self.assertEqual(response.status_code, 404, response.get_json())


if __name__ == "__main__":
    unittest.main()
