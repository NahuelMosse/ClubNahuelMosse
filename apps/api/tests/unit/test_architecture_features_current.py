"""The API contract is compared with today's main: NOT-05 added `recordatorio_cinco` and schemas."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
from tests.unit.test_api_in_english_contract_current import (
    contract_differs_from_main,
)


def test_the_contract_is_main_s_except_for_the_four_schema_names() -> None:
    """the contract has the same routes, methods, codes and shapes as main's, except for the four schema names
    @ARQ-04-S3"""
    assert contract_differs_from_main() == {}
