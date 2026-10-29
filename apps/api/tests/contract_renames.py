"""The rename map from main's Spanish HTTP contract to the English one, taken from
docs/technical/glosario-ingles.md («Rutas de la API» and «Campos JSON»).

It is the only copy of the map in the tests: a test that compares a frozen snapshot of the
contract of main with the published one translates the snapshot through `comparable`.
"""

from typing import Any

PATHS = {
    "/health": "/health",
    "/registro": "/register",
    "/yo": "/me",
    "/yo/contrasena": "/me/password",
    "/recuperacion": "/password-recovery",
    "/recuperacion/consulta": "/password-recovery/check",
    "/enlace/recuperar": "/link/recover",
    "/sedes": "/venues",
    "/sedes/{sede_id}": "/venues/{venue_id}",
    "/espacios": "/spaces",
    "/espacios/catalogo": "/spaces/catalog",
    "/espacios/nombre": "/spaces/name",
    "/espacios/disponibles": "/spaces/available",
    "/espacios/{espacio_id}": "/spaces/{space_id}",
    "/espacios/{espacio_id}/horarios": "/spaces/{space_id}/slots",
    "/reservas": "/bookings",
    "/reservas/{reserva_id}/cancelar": "/bookings/{booking_id}/cancel",
    "/reservas/{reserva_id}/modificar": "/bookings/{booking_id}/modify",
    "/reservas/{reserva_id}/anular": "/bookings/{booking_id}/void",
    "/reservas/todas": "/bookings/all",
    "/reservas/todas/{reserva_id}": "/bookings/all/{booking_id}",
    "/dispositivos": "/devices",
    "/dispositivos/baja": "/devices/unregister",
    "/notificaciones": "/notifications",
    "/notificaciones/leer-todas": "/notifications/read-all",
    "/notificaciones/{notificacion_id}/leer": "/notifications/{notification_id}/read",
}

PARAMETERS = {
    "sede_id": "venue_id",
    "espacio_id": "space_id",
    "reserva_id": "booking_id",
    "notificacion_id": "notification_id",
    "deporte": "sport",
    "tipo": "kind",
    "fecha": "date",
    "horas": "hours",
    "desde": "since",
    "hasta": "until",
    "cuando": "when",
    "estado": "status",
    "pagina": "page",
}

# Names of JSON fields and of the keys of an error body.
FIELDS = {
    "errores": "errors",
    "cambio": "change",
    "nombre": "name",
    "apellido": "last_name",
    "correo": "email",
    "contrasena": "password",
    "fecha_nacimiento": "birth_date",
    "rol": "role",
    "actual": "current_password",
    "nueva": "new_password",
    "codigo": "code",
    "direccion": "address",
    "apertura": "opens_at",
    "cierre": "closes_at",
    "dias": "open_days",
    "confirmar": "confirm",
    "canchas": "space_count",
    "deportes": "sports",
    "sede_id": "venue_id",
    "sede": "venue",
    "espacio_id": "space_id",
    "espacio": "space",
    "deporte": "sport",
    "tipo": "kind",
    "tipos": "kinds",
    "clave": "key",
    "numero": "number",
    "techada": "covered",
    "iluminada": "lit",
    "precio_por_hora": "price_per_hour",
    "inicio": "starts_at",
    "fin": "ends_at",
    "fecha": "date",
    "fechas": "dates",
    "desde": "start_hour",
    "hasta": "until",
    "horas": "hours",
    "hoy": "today",
    "abre": "opens",
    "franjas": "slots",
    "horario": "slot",
    "disponible": "available",
    "no_disponibles": "unavailable",
    "estado": "status",
    "motivo": "reason",
    "anulable": "voidable",
    "usuario_id": "user_id",
    "usuario": "user",
    "creado_en": "created_at",
    "cancelada_en": "canceled_at",
    "cancelada_por_nombre": "canceled_by_name",
    "espacio_de_baja": "space_deactivated",
    "aviso_envio": "notice_delivery",
    "aviso_en": "notice_at",
    "reserva": "booking",
    "reserva_id": "booking_id",
    "reservas": "bookings",
    "pagina": "page",
    "por_pagina": "per_page",
    "contadores": "counters",
    "todas": "all",
    "activas": "active",
    "completadas": "completed",
    "anuladas": "voided",
    "espacios": "spaces",
    "sedes": "venues",
    "reservas_afuera": "bookings_outside",
    "notificaciones": "notifications",
    "no_leidas": "unread",
    "titulo": "title",
    "cuerpo": "body",
    "creada_en": "created_at",
    "leida": "read",
    "plataforma": "platform",
    "permiso": "permission_granted",
    "mensaje": "message",
    "campos": "fields",
}
# `nombre` is the first name of a person and the name of a venue, a space or a sport.
PERSON_SCHEMAS = {
    "OwnProfile",
    "RegistrationRequest",
    "ProfileEditRequest",
    "PerfilPropio",
    "PedidoRegistro",
    "PedidoDeEdicionDePerfil",
}

VALUES = {
    "activa": "active",
    "cancelada": "canceled",
    "anulada": "voided",
    "completada": "completed",
    "usuario": "user",
    "recordatorio": "reminder",
    "recordatorio_cinco": "five_minute_reminder",
    "cancelacion_forzosa": "forced_cancellation",
    "cancelacion_usuario": "user_cancellation",
    "pendiente": "pending",
    "enviando": "sending",
    "enviada": "sent",
    "sin_permiso": "no_permission",
    "sin_canal": "no_channel",
    "fallida": "failed",
    "proximas": "upcoming",
    "historial": "history",
}

# What a Spanish name is when it travels in a contract: none of these is published any more.
SPANISH_NAMES = set(FIELDS) | set(PARAMETERS)
SPANISH_VALUES = set(VALUES)

_NOISE = {"title", "description", "examples", "example"}


def new_field(name: str, owner: str = "") -> str:
    if name == "nombre" and owner in PERSON_SCHEMAS:
        return "first_name"
    return FIELDS.get(name, name)


def _value(value: Any) -> Any:
    return VALUES.get(value, value) if isinstance(value, str) else value


def _tree(node: Any, schemas: dict[str, Any], owner: str, *, renamed: bool) -> Any:
    """The structure of a schema with its $ref resolved, without the human text, and with the
    names of main translated when [renamed]."""
    if isinstance(node, list):
        return [_tree(n, schemas, owner, renamed=renamed) for n in node]
    if not isinstance(node, dict):
        return node
    if "$ref" in node:
        name = node["$ref"].rsplit("/", 1)[1]
        return _tree(schemas[name], schemas, name, renamed=renamed)
    result: dict[str, Any] = {}
    for key, value in node.items():
        if key in _NOISE:
            continue
        if key == "properties":
            result[key] = {
                (new_field(k, owner) if renamed else k): _tree(v, schemas, owner, renamed=renamed)
                for k, v in value.items()
            }
        elif key == "required":
            names = [new_field(k, owner) if renamed else k for k in value]
            result[key] = sorted(names)
        elif key in ("enum", "default", "const") and renamed:
            result[key] = sorted(_value(v) for v in value) if key == "enum" else _value(value)
        elif key == "enum":
            result[key] = sorted(value)
        else:
            result[key] = _tree(value, schemas, owner, renamed=renamed)
    return result


def _operation(op: dict[str, Any], schemas: dict[str, Any], *, renamed: bool) -> dict[str, Any]:
    parameters = []
    for p in op.get("parameters", []):
        name = PARAMETERS.get(p["name"], p["name"]) if renamed else p["name"]
        schema = _tree(p["schema"], schemas, "", renamed=renamed)
        parameters.append((name, p["in"], p.get("required", False), schema))
    body = op.get("requestBody", {}).get("content", {})
    return {
        "parameters": sorted(parameters, key=lambda p: (p[1], p[0])),
        "body": _tree(body, schemas, "", renamed=renamed),
        "responses": {
            code: _tree(r.get("content", {}), schemas, "", renamed=renamed)
            for code, r in op["responses"].items()
        },
        "security": op.get("security"),
    }


def comparable(contract: dict[str, Any], *, renamed: bool) -> dict[tuple[str, str], Any]:
    """Every operation of an OpenAPI document by (METHOD, path), reduced to what the contract
    promises: parameters, body, responses and security. With [renamed], the document is main's
    and its names are translated by the glossary."""
    schemas = contract.get("components", {}).get("schemas", {})
    operations = {}
    for path, methods in contract["paths"].items():
        for method, op in methods.items():
            key = (method.upper(), PATHS[path] if renamed else path)
            operations[key] = _operation(op, schemas, renamed=renamed)
    return operations
