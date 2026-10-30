from typing import Any

from fastapi import FastAPI

BODY_ERRORS = {
    "400": "El cuerpo no se puede leer",
    "408": "El cuerpo no llegó entero en 5 segundos",
    "413": "El cuerpo supera 1 MB",
}
BODY_ERROR_SCHEMA = {
    "type": "object",
    "properties": {"errors": {"type": "object", "additionalProperties": {"type": "string"}}},
    "required": ["errors"],
}
BODY_ERROR_CONTENT = {"application/json": {"schema": {"$ref": "#/components/schemas/BodyError"}}}


class DocumentedApp(FastAPI):
    """BodyLimit and input_validation answer outside each route, so FastAPI does not know them."""

    def openapi(self) -> dict[str, Any]:
        if self.openapi_schema is None:
            schema = super().openapi()
            schema["components"]["schemas"]["BodyError"] = BODY_ERROR_SCHEMA
            for methods in schema["paths"].values():
                for operation in methods.values():
                    if "requestBody" not in operation:
                        continue
                    for status, description in BODY_ERRORS.items():
                        operation["responses"][status] = {
                            "description": description,
                            "content": BODY_ERROR_CONTENT,
                        }
            self.openapi_schema = schema
        return self.openapi_schema
