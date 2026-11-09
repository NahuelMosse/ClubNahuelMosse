"""El README de la app alcanza para configurarla y ejecutarla, con la configuración en `lib/common/`."""

from tests.readme_checks import APP, assert_app_readme_covers_setup_and_run


def test_el_readme_de_la_app_alcanza_para_configurar_y_ejecutarla() -> None:
    """siguiendo sólo el README de la app se configura y ejecuta la app @RNF-01-H07-01 @supuesto:RNF-01-SUP-05"""
    assert_app_readme_covers_setup_and_run(APP / "lib" / "common" / "config.dart")
