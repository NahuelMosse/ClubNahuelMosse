"""Los errores del negocio viven en dominio; acá se reexportan para los casos de uso."""

from app.dominio.errores import (
    DatosInvalidos as DatosInvalidos,
    Duplicado as Duplicado,
    NoAutenticado as NoAutenticado,
    Demorado as Demorado,
    CuentaExistente as CuentaExistente,
    Prohibido as Prohibido,
    NoDisponible as NoDisponible,
    NumeroOcupado as NumeroOcupado,
    HorarioOcupado as HorarioOcupado,
    NoEncontrada as NoEncontrada,
    Cambiado as Cambiado,
    ReservasAfuera as ReservasAfuera,
    AgendaCambiada as AgendaCambiada,
    ConReservasFuturas as ConReservasFuturas,
)
