"""The locks a repository takes still hold inside `in_transaction`."""

import time
from concurrent.futures import ThreadPoolExecutor

from fastapi.testclient import TestClient
from sqlalchemy import Engine, text


def test_creating_a_space_waits_for_the_ongoing_deactivation_of_its_venue_and_rejects_it(
    api: TestClient, engine: Engine, admin_token: str, venue: tuple[str, str]
) -> None:
    """creating a space waits for the ongoing deactivation of its venue and rejects it
    @ARQ-02-S2 @assumption:ARQ-02-ASM-05"""
    venue_id, _ = venue
    space = {
        "venue_id": venue_id,
        "sport": "Futbol",
        "kind": "F5",
        "covered": False,
        "lit": True,
        "price_per_hour": 38000,
    }
    with engine.connect() as deactivation, ThreadPoolExecutor(max_workers=1) as pool:
        deactivation.execute(
            text("UPDATE venue SET active = false, deactivated_at = now() WHERE id = :id"),
            {"id": venue_id},
        )
        creation = pool.submit(
            api.post, "/spaces", headers={"Authorization": f"Bearer {admin_token}"}, json=space
        )
        time.sleep(1.5)
        waited = not creation.done()
        deactivation.commit()
        r = creation.result(timeout=30)

    assert waited
    assert r.status_code == 422
    assert r.json() == {"errors": {"venue_id": "The venue is no longer available"}}
