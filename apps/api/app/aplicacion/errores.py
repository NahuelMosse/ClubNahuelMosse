class DatosInvalidos(Exception):
    def __init__(self, errores: dict[str, str]) -> None:
        super().__init__("datos inválidos")
        self.errores = errores


class Duplicado(Exception):
    """Ya existe una cuenta activa con alguno de estos campos."""

    def __init__(self, campos: list[str]) -> None:
        super().__init__(f"duplicado: {', '.join(campos)}")
        self.campos = campos


class NoAutenticado(Exception):
    """El pedido no trae un token válido de una cuenta con perfil activo."""


class Demorado(Exception):
    """El proveedor de identidad frena por demasiados intentos seguidos."""


class CuentaExistente(Exception):
    """Ya hay una cuenta activa con ese correo y no se pidió ascenderla."""


class Prohibido(Exception):
    """Quien pide la operación no puede hacerla."""


class NoDisponible(Exception):
    """Lo que se pidió ya no existe o está dado de baja."""


class NumeroOcupado(Exception):
    """Otro alta ya tomó el número de espacio que se estaba mostrando."""

    def __init__(self, siguiente: int, nombre: str) -> None:
        super().__init__(f"número ocupado; el siguiente es {siguiente} ({nombre})")
        self.siguiente = siguiente
        self.nombre = nombre


class HorarioOcupado(Exception):
    """Otra reserva activa del mismo espacio se superpone con el horario pedido."""


class NoEncontrada(Exception):
    """No hay nada con ese número que sea de quien lo pide."""


class Cambiado(Exception):
    """Lo que se quería cambiar ya no está como se lo veía (otra persona o el tiempo lo
    cambiaron)."""
