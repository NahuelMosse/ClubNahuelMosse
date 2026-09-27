class DatosInvalidos(Exception):
    def __init__(self, errores: dict[str, str]) -> None:
        super().__init__("datos inválidos")
        self.errores = errores


class Duplicado(Exception):
    """Ya existe una cuenta activa con alguno de estos campos."""

    def __init__(self, campos: list[str]) -> None:
        super().__init__(f"duplicado: {', '.join(campos)}")
        self.campos = campos
