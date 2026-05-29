-- Align diesel_prices reference table with AppConfig default (₹100/L) for trip estimates.
UPDATE diesel_prices
SET price_per_litre = 100,
    updated_at = NOW()
WHERE price_per_litre < 100;
