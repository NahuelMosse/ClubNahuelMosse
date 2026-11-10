"""The conditions of the global history according to the text search."""

# ruff: noqa: E501  (test titles carry their tags and are not split)
import pytest

from app.modules.bookings.repository import _common_conditions
from app.modules.bookings.rules import HistoryFilters


@pytest.mark.parametrize("q", [None, "", "   "])
def test_without_a_search_or_with_a_blank_one_the_history_does_not_filter_by_text(
    q: str | None,
) -> None:
    """without a search or with a blank one the history does not filter by text @SIM-02-S1"""
    conditions, parameters = _common_conditions(HistoryFilters(q=q))

    assert not any(":q" in c for c in conditions)
    assert "q" not in parameters


def test_the_search_filters_by_member_venue_or_space_and_escapes_the_wildcards() -> None:
    """the search filters by member, venue or space and escapes the wildcards @SIM-02-S1"""
    conditions, parameters = _common_conditions(HistoryFilters(q=" 50%_a "))

    assert any(":q" in c for c in conditions)
    assert parameters["q"] == "%50\\%\\_a%"
