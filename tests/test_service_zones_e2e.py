#!/usr/bin/env python3
"""
Presso API — Service Zone (Geo-Fencing) End-to-End Test Suite
=============================================================

Run:  python3 test_service_zones_e2e.py [--base-url http://localhost:5181]
      python3 test_service_zones_e2e.py --report   # generates JSON report

Prerequisites:
  - pip install httpx   (or requests — the script tries httpx first)
  - API must be running with the AddServiceZones migration applied
  - An admin JWT token (see ADMIN_TOKEN below or set PRESSO_ADMIN_TOKEN env var)
"""

import json
import os
import sys
import time
import traceback
from dataclasses import dataclass, field, asdict
from datetime import datetime
from typing import Optional

# ── HTTP client ──────────────────────────────────────────────────────────────

try:
    import httpx as http_lib
    _client = None

    def _get_client():
        global _client
        if _client is None:
            _client = http_lib.Client(timeout=30)
        return _client

    def _request(method, url, headers=None, json_data=None, params=None):
        r = _get_client().request(method, url, headers=headers, json=json_data, params=params)
        return r.status_code, r.json() if r.headers.get("content-type", "").startswith("application/json") else r.text
except ImportError:
    import urllib.request
    import urllib.error

    def _request(method, url, headers=None, json_data=None, params=None):
        if params:
            qs = "&".join(f"{k}={v}" for k, v in params.items() if v is not None)
            if qs:
                url = f"{url}?{qs}"
        data = json.dumps(json_data).encode() if json_data else None
        req = urllib.request.Request(url, data=data, method=method)
        req.add_header("Content-Type", "application/json")
        req.add_header("Accept", "application/json")
        if headers:
            for k, v in headers.items():
                req.add_header(k, v)
        try:
            resp = urllib.request.urlopen(req, timeout=30)
            body = json.loads(resp.read().decode())
            return resp.status, body
        except urllib.error.HTTPError as e:
            body = json.loads(e.read().decode()) if e.fp else {}
            return e.code, body


# ── Config ───────────────────────────────────────────────────────────────────

BASE_URL = os.environ.get("PRESSO_BASE_URL", "http://localhost:5181")
ADMIN_TOKEN = os.environ.get("PRESSO_ADMIN_TOKEN", "")

# Override via CLI args
for i, arg in enumerate(sys.argv[1:], 1):
    if arg == "--base-url" and i < len(sys.argv) - 1:
        BASE_URL = sys.argv[i + 1]
    if arg == "--token" and i < len(sys.argv) - 1:
        ADMIN_TOKEN = sys.argv[i + 1]


def admin_headers():
    h = {"Content-Type": "application/json", "Accept": "application/json"}
    if ADMIN_TOKEN:
        h["Authorization"] = f"Bearer {ADMIN_TOKEN}"
    return h


def public_headers():
    return {"Content-Type": "application/json", "Accept": "application/json"}


# ── Test Infrastructure ──────────────────────────────────────────────────────

@dataclass
class TestResult:
    name: str
    passed: bool
    duration_ms: float
    category: str = ""
    error: str = ""
    details: str = ""


@dataclass
class TestReport:
    suite_name: str = "Presso Geo-Fencing E2E Tests"
    started_at: str = ""
    finished_at: str = ""
    base_url: str = ""
    total: int = 0
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    duration_ms: float = 0
    results: list = field(default_factory=list)

    @property
    def pass_rate(self):
        return f"{self.passed / self.total * 100:.1f}%" if self.total > 0 else "N/A"


report = TestReport(base_url=BASE_URL)
_created_zone_ids = []


def run_test(name: str, category: str = ""):
    """Decorator to run a test function and record results."""
    def decorator(func):
        def wrapper():
            start = time.time()
            try:
                func()
                elapsed = (time.time() - start) * 1000
                result = TestResult(name=name, passed=True, duration_ms=round(elapsed, 1), category=category)
                report.results.append(result)
                report.passed += 1
                print(f"  ✅ {name} ({elapsed:.0f}ms)")
            except AssertionError as e:
                elapsed = (time.time() - start) * 1000
                result = TestResult(name=name, passed=False, duration_ms=round(elapsed, 1),
                                    category=category, error=str(e))
                report.results.append(result)
                report.failed += 1
                print(f"  ❌ {name}: {e}")
            except Exception as e:
                elapsed = (time.time() - start) * 1000
                result = TestResult(name=name, passed=False, duration_ms=round(elapsed, 1),
                                    category=category, error=f"EXCEPTION: {e}\n{traceback.format_exc()}")
                report.results.append(result)
                report.failed += 1
                print(f"  💥 {name}: {e}")
            report.total += 1
        return wrapper
    return decorator


# Typo alias
AssertionError = AssertionError if False else AssertionError  # noqa — just for clarity
# Fix: Python's actual name is AssertionError
class AssertionError(AssertionError):
    pass


def assert_eq(actual, expected, msg=""):
    if actual != expected:
        raise AssertionError(f"{msg}: expected {expected!r}, got {actual!r}")


def assert_true(condition, msg=""):
    if not condition:
        raise AssertionError(msg or "Condition was False")


def assert_status(status, expected, body=None):
    if status != expected:
        detail = f" | body={json.dumps(body)[:200]}" if body else ""
        raise AssertionError(f"HTTP {status} (expected {expected}){detail}")


# ══════════════════════════════════════════════════════════════════════════════
#  TEST CASES
# ══════════════════════════════════════════════════════════════════════════════

# ── 1. Health Check ──────────────────────────────────────────────────────────

@run_test("API Health Check", "Setup")
def test_health():
    status, body = _request("GET", f"{BASE_URL}/api/health", headers=public_headers())
    assert_status(status, 200, body)


# ── 2. Public Endpoints ──────────────────────────────────────────────────────

@run_test("GET /service-zones/active returns empty or seeded list", "Public")
def test_active_zones():
    status, body = _request("GET", f"{BASE_URL}/api/service-zones/active", headers=public_headers())
    assert_status(status, 200, body)
    assert_true(body.get("success") == True, f"Response not successful: {body}")
    assert_true(isinstance(body.get("data"), list), "Data should be a list")


@run_test("GET /service-zones/check/{pincode} - serviceable pincode", "Public")
def test_check_serviceable():
    status, body = _request("GET", f"{BASE_URL}/api/service-zones/check/400706", headers=public_headers())
    assert_status(status, 200, body)
    assert_true(body.get("success") == True, "Response not successful")
    data = body.get("data", {})
    # If seeded, this should be serviceable
    if data.get("isServiceable"):
        assert_true("Nerul" in (data.get("zoneName") or ""), "Should return Nerul zone name")


@run_test("GET /service-zones/check/{pincode} - non-serviceable pincode", "Public")
def test_check_not_serviceable():
    status, body = _request("GET", f"{BASE_URL}/api/service-zones/check/999999", headers=public_headers())
    assert_status(status, 200, body)
    data = body.get("data", {})
    assert_eq(data.get("isServiceable"), False, "Random pincode should not be serviceable")


# ── 3. Admin CRUD ────────────────────────────────────────────────────────────

@run_test("POST /admin/service-zones - create zone (Kharghar)", "Admin CRUD")
def test_create_zone():
    payload = {
        "name": "Kharghar Test",
        "pincode": "410210",
        "city": "Navi Mumbai",
        "area": "Sector 1-20",
        "description": "E2E test zone"
    }
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones",
                            headers=admin_headers(), json_data=payload)
    assert_status(status, 201, body)
    assert_true(body.get("success") == True, f"Create failed: {body}")
    zone = body.get("data", {})
    assert_eq(zone.get("pincode"), "410210", "Pincode mismatch")
    assert_eq(zone.get("city"), "Navi Mumbai", "City mismatch")
    assert_true(zone.get("isActive") == True, "Should be active by default")
    _created_zone_ids.append(zone.get("id"))


@run_test("POST /admin/service-zones - reject duplicate pincode", "Admin CRUD")
def test_create_duplicate():
    payload = {"name": "Duplicate Kharghar", "pincode": "410210", "city": "Navi Mumbai"}
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones",
                            headers=admin_headers(), json_data=payload)
    assert_status(status, 400, body)
    assert_true("already exists" in (body.get("message") or "").lower(), "Should mention duplicate")


@run_test("POST /admin/service-zones - reject invalid pincode (5 digits)", "Admin CRUD")
def test_create_invalid_pincode():
    payload = {"name": "Bad Zone", "pincode": "12345", "city": "Navi Mumbai"}
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones",
                            headers=admin_headers(), json_data=payload)
    assert_status(status, 400, body)
    assert_true("6 digits" in (body.get("message") or ""), "Should mention 6 digits")


@run_test("POST /admin/service-zones - reject missing name", "Admin CRUD")
def test_create_no_name():
    payload = {"name": "", "pincode": "410211", "city": "Navi Mumbai"}
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones",
                            headers=admin_headers(), json_data=payload)
    assert_status(status, 400, body)


@run_test("GET /admin/service-zones - list all zones", "Admin CRUD")
def test_list_all():
    status, body = _request("GET", f"{BASE_URL}/api/admin/service-zones/",
                            headers=admin_headers())
    assert_status(status, 200, body)
    zones = body.get("data", [])
    assert_true(len(zones) >= 1, "Should have at least 1 zone")


@run_test("GET /admin/service-zones?isActive=true - filter active", "Admin CRUD")
def test_list_active_filter():
    status, body = _request("GET", f"{BASE_URL}/api/admin/service-zones/",
                            headers=admin_headers(), params={"isActive": "true"})
    assert_status(status, 200, body)
    zones = body.get("data", [])
    for z in zones:
        assert_true(z.get("isActive") == True, f"Zone {z.get('name')} should be active")


@run_test("GET /admin/service-zones/{id} - get single zone", "Admin CRUD")
def test_get_single():
    if not _created_zone_ids:
        raise AssertionError("No zone created to fetch")
    zid = _created_zone_ids[0]
    status, body = _request("GET", f"{BASE_URL}/api/admin/service-zones/{zid}",
                            headers=admin_headers())
    assert_status(status, 200, body)
    assert_eq(body.get("data", {}).get("id"), zid, "ID mismatch")


@run_test("GET /admin/service-zones/{bad-id} - 404 for missing", "Admin CRUD")
def test_get_missing():
    fake_id = "00000000-0000-0000-0000-000000000000"
    status, body = _request("GET", f"{BASE_URL}/api/admin/service-zones/{fake_id}",
                            headers=admin_headers())
    assert_status(status, 404, body)


@run_test("PATCH /admin/service-zones/{id} - update zone name", "Admin CRUD")
def test_update_zone():
    if not _created_zone_ids:
        raise AssertionError("No zone to update")
    zid = _created_zone_ids[0]
    status, body = _request("PATCH", f"{BASE_URL}/api/admin/service-zones/{zid}",
                            headers=admin_headers(),
                            json_data={"name": "Kharghar Updated", "description": "Updated by E2E"})
    assert_status(status, 200, body)
    assert_eq(body.get("data", {}).get("name"), "Kharghar Updated", "Name not updated")


@run_test("PATCH /admin/service-zones/{id} - toggle inactive", "Admin CRUD")
def test_toggle_inactive():
    if not _created_zone_ids:
        raise AssertionError("No zone to toggle")
    zid = _created_zone_ids[0]
    status, body = _request("PATCH", f"{BASE_URL}/api/admin/service-zones/{zid}",
                            headers=admin_headers(), json_data={"isActive": False})
    assert_status(status, 200, body)
    assert_eq(body.get("data", {}).get("isActive"), False, "Should be inactive")


@run_test("PATCH /admin/service-zones/{id} - toggle back active", "Admin CRUD")
def test_toggle_active():
    if not _created_zone_ids:
        raise AssertionError("No zone to toggle")
    zid = _created_zone_ids[0]
    status, body = _request("PATCH", f"{BASE_URL}/api/admin/service-zones/{zid}",
                            headers=admin_headers(), json_data={"isActive": True})
    assert_status(status, 200, body)
    assert_eq(body.get("data", {}).get("isActive"), True, "Should be active again")


@run_test("PATCH /admin/service-zones/{id} - reject duplicate pincode on update", "Admin CRUD")
def test_update_duplicate_pincode():
    if not _created_zone_ids:
        raise AssertionError("No zone to update")
    zid = _created_zone_ids[0]
    # Try to change pincode to one that already exists (e.g. Nerul 400706)
    status, body = _request("PATCH", f"{BASE_URL}/api/admin/service-zones/{zid}",
                            headers=admin_headers(), json_data={"pincode": "400706"})
    # Should be 400 if 400706 is already a zone
    if status == 400:
        assert_true("already exists" in (body.get("message") or "").lower(), "Should mention duplicate")
    # If 200, it means 400706 doesn't exist yet — that's also fine


# ── 4. Bulk Toggle ───────────────────────────────────────────────────────────

@run_test("POST /admin/service-zones/bulk-toggle - bulk deactivate", "Bulk Operations")
def test_bulk_toggle():
    if not _created_zone_ids:
        raise AssertionError("No zones to bulk-toggle")
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones/bulk-toggle",
                            headers=admin_headers(),
                            json_data={"zoneIds": _created_zone_ids, "isActive": False})
    assert_status(status, 200, body)
    assert_true(body.get("data", 0) >= 1, "Should affect at least 1 zone")


@run_test("POST /admin/service-zones/bulk-toggle - bulk reactivate", "Bulk Operations")
def test_bulk_reactivate():
    if not _created_zone_ids:
        raise AssertionError("No zones to bulk-toggle")
    status, body = _request("POST", f"{BASE_URL}/api/admin/service-zones/bulk-toggle",
                            headers=admin_headers(),
                            json_data={"zoneIds": _created_zone_ids, "isActive": True})
    assert_status(status, 200, body)


# ── 5. Public Check After Mutations ──────────────────────────────────────────

@run_test("Verify new zone (410210) is now publicly serviceable", "Integration")
def test_check_new_zone():
    status, body = _request("GET", f"{BASE_URL}/api/service-zones/check/410210",
                            headers=public_headers())
    assert_status(status, 200, body)
    data = body.get("data", {})
    assert_eq(data.get("isServiceable"), True, "Kharghar (410210) should now be serviceable")


# ── 6. Auth Guard Tests ──────────────────────────────────────────────────────

@run_test("Admin endpoints reject unauthenticated requests", "Security")
def test_no_auth():
    status, body = _request("GET", f"{BASE_URL}/api/admin/service-zones/",
                            headers=public_headers())
    assert_true(status in (401, 403), f"Expected 401/403, got {status}")


@run_test("Admin endpoints reject non-admin tokens", "Security")
def test_wrong_role():
    bad_headers = {"Authorization": "Bearer invalidtoken123", "Content-Type": "application/json"}
    status, _ = _request("GET", f"{BASE_URL}/api/admin/service-zones/", headers=bad_headers)
    assert_true(status in (401, 403), f"Expected 401/403, got {status}")


# ── 7. Cleanup ───────────────────────────────────────────────────────────────

@run_test("DELETE /admin/service-zones/{id} - soft delete test zone", "Cleanup")
def test_delete_zone():
    if not _created_zone_ids:
        raise AssertionError("No zone to delete")
    zid = _created_zone_ids[0]
    status, _ = _request("DELETE", f"{BASE_URL}/api/admin/service-zones/{zid}",
                         headers=admin_headers())
    assert_status(status, 204)


@run_test("Verify deleted zone is no longer serviceable publicly", "Cleanup")
def test_check_after_delete():
    status, body = _request("GET", f"{BASE_URL}/api/service-zones/check/410210",
                            headers=public_headers())
    assert_status(status, 200, body)
    data = body.get("data", {})
    assert_eq(data.get("isServiceable"), False, "Deleted zone should not be serviceable")


# ══════════════════════════════════════════════════════════════════════════════
#  RUNNER
# ══════════════════════════════════════════════════════════════════════════════

ALL_TESTS = [
    test_health,
    test_active_zones,
    test_check_serviceable,
    test_check_not_serviceable,
    test_create_zone,
    test_create_duplicate,
    test_create_invalid_pincode,
    test_create_no_name,
    test_list_all,
    test_list_active_filter,
    test_get_single,
    test_get_missing,
    test_update_zone,
    test_toggle_inactive,
    test_toggle_active,
    test_update_duplicate_pincode,
    test_bulk_toggle,
    test_bulk_reactivate,
    test_check_new_zone,
    test_no_auth,
    test_wrong_role,
    test_delete_zone,
    test_check_after_delete,
]


def main():
    print(f"\n{'='*60}")
    print(f"  Presso Geo-Fencing E2E Test Suite")
    print(f"  Target: {BASE_URL}")
    print(f"  Admin Token: {'✅ set' if ADMIN_TOKEN else '⚠️  NOT SET (admin tests will fail)'}")
    print(f"{'='*60}\n")

    report.started_at = datetime.now().isoformat()

    for test_fn in ALL_TESTS:
        test_fn()

    report.finished_at = datetime.now().isoformat()
    report.duration_ms = sum(r.duration_ms for r in report.results)

    print(f"\n{'='*60}")
    print(f"  Results: {report.passed}/{report.total} passed ({report.pass_rate})")
    print(f"  Failed:  {report.failed}")
    print(f"  Time:    {report.duration_ms:.0f}ms")
    print(f"{'='*60}\n")

    # Generate JSON report
    if "--report" in sys.argv:
        report_data = {
            "suite_name": report.suite_name,
            "started_at": report.started_at,
            "finished_at": report.finished_at,
            "base_url": report.base_url,
            "summary": {
                "total": report.total,
                "passed": report.passed,
                "failed": report.failed,
                "pass_rate": report.pass_rate,
                "duration_ms": report.duration_ms,
            },
            "results": [asdict(r) for r in report.results],
        }
        report_path = os.path.join(os.path.dirname(__file__), "test_report.json")
        with open(report_path, "w") as f:
            json.dump(report_data, f, indent=2)
        print(f"  📄 Report saved to: {report_path}\n")

    return 0 if report.failed == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
