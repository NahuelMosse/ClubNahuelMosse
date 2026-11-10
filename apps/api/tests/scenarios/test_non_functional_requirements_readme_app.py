"""The README of the app is enough to configure and run it, with the configuration in `lib/common/`."""

from tests.readme_checks import APP, assert_app_readme_covers_setup_and_run


def test_the_app_readme_is_enough_to_configure_and_run_it() -> None:
    """following only the README of the app, the app is configured and run @RNF-01-H07-01 @assumption:RNF-01-SUP-05"""
    assert_app_readme_covers_setup_and_run(APP / "lib" / "common" / "config.dart")
