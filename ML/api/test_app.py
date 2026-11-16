import json
import sys
import unittest
from pathlib import Path

# Pastikan folder ML/api ada di PYTHONPATH
sys.path.insert(0, str(Path(__file__).resolve().parent))

from app import app


class FlaskAppTestCase(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        self.client.testing = True

    def test_health_check(self):
        """TC-Health: Memastikan endpoint /health merespons status OK dan metadata model."""
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["status"], "ok")
        self.assertIn("models_loaded", data)
        self.assertTrue(data["models_loaded"]["regression"])
        self.assertTrue(data["models_loaded"]["classification"])
        self.assertTrue(data["models_loaded"]["clustering"])
        self.assertEqual(data["dataset_source"], "lettuce_dataset_training.csv")

    def test_predict_valid_payload_tc005(self):
        """TC-005: Verifikasi respons API untuk request JSON valid (Regresi + Klasifikasi + Klusterisasi)."""
        payload = {
            "umur_hst": 20,
            "suhu": 25.0,
            "kelembapan": 70.0,
            "tds": 650.0,
            "ph": 6.2,
        }
        response = self.client.post(
            "/predict",
            data=json.dumps(payload),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.get_json()

        # 1. Verifikasi Regresi
        self.assertIn("days_left", data)
        self.assertIn("harvest_date", data)
        self.assertIn("estimated_total_hst", data)
        self.assertGreaterEqual(data["days_left"], 0)

        # 2. Verifikasi Klasifikasi
        self.assertIn("classification", data)
        self.assertIn("growth_stage", data["classification"])
        self.assertIn("stage_id", data["classification"])

        # 3. Verifikasi Klusterisasi
        self.assertIn("clustering", data)
        self.assertIn("cluster_id", data["clustering"])
        self.assertIn("profile", data["clustering"])

    def test_predict_incomplete_payload_tc006(self):
        """TC-006: Verifikasi respons API saat data tidak lengkap."""
        payload = {
            "umur_hst": 20,
            "suhu": 23.5,
            # 'kelembapan', 'tds', 'ph' sengaja dihilangkan
        }
        response = self.client.post(
            "/predict",
            data=json.dumps(payload),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 422)
        data = response.get_json()
        self.assertIn("error", data)
        self.assertIn("errors", data)

    def test_predict_out_of_range_payload_tc004(self):
        """TC-004: Verifikasi validasi saat nilai input di luar rentang wajar."""
        payload = {
            "umur_hst": -5,  # Di luar rentang
            "suhu": 23.5,
            "kelembapan": 75.0,
            "tds": 700.0,
            "ph": 15.0,  # Di luar rentang
        }
        response = self.client.post(
            "/predict",
            data=json.dumps(payload),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 422)
        data = response.get_json()
        self.assertTrue(any("umur_hst" in err for err in data["errors"]))
        self.assertTrue(any("ph" in err for err in data["errors"]))

    def test_register_device_valid(self):
        """Pengujian registrasi FCM device token ke /devices."""
        payload = {
            "fcm_token": "sample-fcm-token-xyz123",
            "platform": "android",
        }
        response = self.client.post(
            "/devices",
            data=json.dumps(payload),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 200)
        data = response.get_json()
        self.assertEqual(data["status"], "registered")

    def test_register_device_empty_token(self):
        """Pengujian registrasi FCM device token tanpa token."""
        response = self.client.post(
            "/devices",
            data=json.dumps({}),
            content_type="application/json",
        )
        self.assertEqual(response.status_code, 400)


if __name__ == "__main__":
    unittest.main()
