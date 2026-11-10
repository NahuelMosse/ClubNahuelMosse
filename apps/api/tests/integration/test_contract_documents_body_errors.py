"""The published contract documents the body errors the app answers outside each route."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
from app.main import create_app

BODY_ERRORS = ("400", "408", "413")


def test_every_operation_with_a_json_body_documents_400_408_and_413() -> None:
    """every operation with a JSON body documents 400, 408 and 413 @ENG-18-S2 @assumption:ENG-18-ASM-13"""
    with_body = [
        (path, method, operation)
        for path, methods in create_app().openapi()["paths"].items()
        for method, operation in methods.items()
        if "requestBody" in operation
    ]
    assert with_body
    for path, method, operation in with_body:
        for status in BODY_ERRORS:
            response = operation["responses"].get(status)
            assert response is not None, (method, path, status)
            schema = response["content"]["application/json"]["schema"]
            assert schema == {"$ref": "#/components/schemas/BodyError"}, (method, path, status)
