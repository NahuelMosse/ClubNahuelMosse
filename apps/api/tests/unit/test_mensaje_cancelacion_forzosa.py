from datetime import UTC, datetime

from app.dominio.notificaciones import ReservaAnulada, mensaje_cancelacion_forzosa


def _anulada(reserva_id: int = 7, motivo: str = "mantenimiento de la cancha") -> ReservaAnulada:
    return ReservaAnulada(
        reserva_id=reserva_id,
        # Mié 11 a las 20:00 en el club (UTC−3)
        inicio=datetime(2026, 11, 11, 23, 0, tzinfo=UTC),
        deporte="Futbol",
        tipo="F5",
        sede="Sede Ramos Mejía",
        motivo=motivo,
    )


def test_una_reserva_dice_deporte_sede_dia_hora_y_motivo() -> None:
    aviso = mensaje_cancelacion_forzosa([_anulada()])

    assert aviso.titulo == "El club anuló tu reserva"
    assert aviso.cuerpo == (
        "Fútbol 5 · Sede Ramos Mejía · Mié 11, 20:00. Motivo: mantenimiento de la cancha."
    )
    assert aviso.datos == {"tipo": "cancelacion_forzosa", "reserva_id": "7"}


def test_varias_reservas_dicen_cuantas_son_y_no_apuntan_a_una() -> None:
    aviso = mensaje_cancelacion_forzosa([_anulada(1), _anulada(2), _anulada(3)])

    assert aviso.titulo == "El club anuló 3 de tus reservas"
    assert aviso.cuerpo == "Tenés 3 reservas anuladas por el club. Mirá el detalle en tu historial."
    assert aviso.datos == {"tipo": "cancelacion_forzosa"}


def test_el_motivo_de_mas_de_doscientos_caracteres_se_recorta() -> None:
    motivo = "x" * 200

    cuerpo = mensaje_cancelacion_forzosa([_anulada(motivo=motivo)]).cuerpo
    assert cuerpo.endswith(f"Motivo: {motivo}.")

    cuerpo = mensaje_cancelacion_forzosa([_anulada(motivo=motivo + "y")]).cuerpo
    assert cuerpo.endswith(f"Motivo: {'x' * 199}….")
