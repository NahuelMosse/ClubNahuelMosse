"""Modelo inicial: usuario, sede, espacio y reserva.

Revision ID: 0001
Revises:
"""

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS btree_gist")
    op.execute(
        """
        CREATE FUNCTION marcar_modificado() RETURNS trigger AS $$
        BEGIN
            NEW.modificado_en := now();
            RETURN NEW;
        END $$ LANGUAGE plpgsql
        """
    )

    op.execute(
        """
        CREATE TABLE usuario (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            firebase_uid text NOT NULL UNIQUE,
            correo text NOT NULL,
            nombre text NOT NULL CHECK (btrim(nombre) <> ''),
            apellido text NOT NULL CHECK (btrim(apellido) <> ''),
            dni text NOT NULL UNIQUE CHECK (dni ~ '^[0-9]{7,8}$'),
            fecha_nacimiento date NOT NULL,
            rol text NOT NULL DEFAULT 'usuario' CHECK (rol IN ('usuario', 'admin')),
            activo boolean NOT NULL DEFAULT true,
            dado_de_baja_en timestamptz,
            creado_en timestamptz NOT NULL DEFAULT now(),
            modificado_en timestamptz NOT NULL DEFAULT now()
        )
        """
    )
    op.execute("CREATE UNIQUE INDEX usuario_correo_unico ON usuario (lower(correo))")
    op.execute(
        """
        CREATE FUNCTION correo_inmutable() RETURNS trigger AS $$
        BEGIN
            IF NEW.correo IS DISTINCT FROM OLD.correo THEN
                RAISE EXCEPTION 'el correo de un usuario no se puede cambiar'
                    USING ERRCODE = 'check_violation';
            END IF;
            RETURN NEW;
        END $$ LANGUAGE plpgsql
        """
    )
    op.execute(
        "CREATE TRIGGER usuario_correo_inmutable BEFORE UPDATE ON usuario"
        " FOR EACH ROW EXECUTE FUNCTION correo_inmutable()"
    )

    op.execute(
        """
        CREATE TABLE sede (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            nombre text NOT NULL CHECK (btrim(nombre) <> ''),
            calle text NOT NULL CHECK (btrim(calle) <> ''),
            altura integer NOT NULL CHECK (altura > 0),
            apertura time NOT NULL,
            cierre time NOT NULL,
            dias smallint[] NOT NULL,
            activa boolean NOT NULL DEFAULT true,
            creado_por bigint REFERENCES usuario (id),
            modificado_por bigint REFERENCES usuario (id),
            dado_de_baja_por bigint REFERENCES usuario (id),
            dado_de_baja_en timestamptz,
            creado_en timestamptz NOT NULL DEFAULT now(),
            modificado_en timestamptz NOT NULL DEFAULT now(),
            CHECK (apertura < cierre),
            CHECK (date_part('minute', apertura) = 0 AND date_part('second', apertura) = 0),
            CHECK (date_part('minute', cierre) = 0 AND date_part('second', cierre) = 0),
            CHECK (cardinality(dias) BETWEEN 1 AND 7 AND dias <@ ARRAY[1,2,3,4,5,6,7]::smallint[])
        )
        """
    )

    op.execute(
        """
        CREATE TABLE espacio (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            sede_id bigint NOT NULL REFERENCES sede (id),
            deporte text NOT NULL CHECK (btrim(deporte) <> ''),
            tipo text NOT NULL CHECK (btrim(tipo) <> ''),
            numero integer NOT NULL CHECK (numero > 0),
            nombre text NOT NULL UNIQUE,
            techada boolean NOT NULL,
            iluminada boolean NOT NULL,
            precio_por_hora integer NOT NULL CHECK (precio_por_hora > 0),
            activo boolean NOT NULL DEFAULT true,
            creado_por bigint REFERENCES usuario (id),
            modificado_por bigint REFERENCES usuario (id),
            dado_de_baja_por bigint REFERENCES usuario (id),
            dado_de_baja_en timestamptz,
            creado_en timestamptz NOT NULL DEFAULT now(),
            modificado_en timestamptz NOT NULL DEFAULT now(),
            UNIQUE (sede_id, deporte, tipo, numero)
        )
        """
    )

    op.execute(
        """
        CREATE TABLE reserva (
            id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            usuario_id bigint NOT NULL REFERENCES usuario (id),
            espacio_id bigint NOT NULL REFERENCES espacio (id),
            inicio timestamptz NOT NULL,
            fin timestamptz NOT NULL,
            precio_por_hora integer NOT NULL CHECK (precio_por_hora > 0),
            total integer NOT NULL CHECK (total > 0),
            estado text NOT NULL DEFAULT 'activa'
                CHECK (estado IN ('activa', 'cancelada', 'anulada')),
            cancelada_en timestamptz,
            cancelada_por bigint REFERENCES usuario (id),
            motivo text,
            creado_en timestamptz NOT NULL DEFAULT now(),
            modificado_en timestamptz NOT NULL DEFAULT now(),
            CHECK (date_trunc('hour', inicio) = inicio AND date_trunc('hour', fin) = fin),
            CHECK (fin - inicio BETWEEN interval '1 hour' AND interval '4 hours'),
            CHECK (estado <> 'anulada' OR btrim(coalesce(motivo, '')) <> ''),
            EXCLUDE USING gist (espacio_id WITH =, tstzrange(inicio, fin) WITH &&)
                WHERE (estado = 'activa')
        )
        """
    )

    for tabla in ("usuario", "sede", "espacio", "reserva"):
        op.execute(
            f"CREATE TRIGGER {tabla}_modificado BEFORE UPDATE ON {tabla}"
            " FOR EACH ROW EXECUTE FUNCTION marcar_modificado()"
        )

    op.execute(
        """
        CREATE VIEW reserva_con_estado AS
        SELECT reserva.*,
               CASE WHEN estado = 'activa' AND fin <= now() THEN 'completada' ELSE estado END
                   AS estado_actual
        FROM reserva
        """
    )


def downgrade() -> None:
    op.execute("DROP VIEW reserva_con_estado")
    for tabla in ("reserva", "espacio", "sede", "usuario"):
        op.execute(f"DROP TABLE {tabla}")
    op.execute("DROP FUNCTION correo_inmutable()")
    op.execute("DROP FUNCTION marcar_modificado()")
