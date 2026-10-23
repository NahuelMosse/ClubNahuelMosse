"""Los errores del negocio viven en dominio; acá se reexportan para los casos de uso."""

from app.dominio.errores import (
    AgendaCambiada as AgendaCambiada,
)
from app.dominio.errores import (
    Cambiado as Cambiado,
)
from app.dominio.errores import (
    ConReservasFuturas as ConReservasFuturas,
)
from app.dominio.errores import (
    CuentaExistente as CuentaExistente,
)
from app.dominio.errores import (
    DatosInvalidos as DatosInvalidos,
)
from app.dominio.errores import (
    Demorado as Demorado,
)
from app.dominio.errores import (
    Duplicado as Duplicado,
)
from app.dominio.errores import (
    HorarioOcupado as HorarioOcupado,
)
from app.dominio.errores import (
    NoAutenticado as NoAutenticado,
)
from app.dominio.errores import (
    NoDisponible as NoDisponible,
)
from app.dominio.errores import (
    NoEncontrada as NoEncontrada,
)
from app.dominio.errores import (
    NumeroOcupado as NumeroOcupado,
)
from app.dominio.errores import (
    Prohibido as Prohibido,
)
from app.dominio.errores import (
    ReservasAfuera as ReservasAfuera,
)
