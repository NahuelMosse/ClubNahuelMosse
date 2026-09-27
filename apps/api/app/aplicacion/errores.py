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
