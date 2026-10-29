const maxPricePerHour = 9999999;

/// Whether the typed price per hour [price] (`null` if empty) is between $ 1 and
/// [maxPricePerHour].
bool validPricePerHour(int? price) =>
    price != null && price >= 1 && price <= maxPricePerHour;
