
SET 
@p_name = 'PT1';

SET
@p_currency = (SELECT p_currency FROM portfolio WHERE p_name = @p_name),
@asset_1 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 0), 
@asset_2 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 1),
@asset_3 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 2),
@asset_4 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 3),
@asset_5 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 4),
@asset_6 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 5),
@asset_7 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 6),
@asset_8 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 7),
@asset_9 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 8),
@asset_10 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 9);

SET
@a1_currency = (SELECT currency FROM asset WHERE isin = @asset_1), 
@a2_currency = (SELECT currency FROM asset WHERE isin = @asset_2),
@a3_currency = (SELECT currency FROM asset WHERE isin = @asset_3),
@a4_currency = (SELECT currency FROM asset WHERE isin = @asset_4),
@a5_currency = (SELECT currency FROM asset WHERE isin = @asset_5),
@a6_currency = (SELECT currency FROM asset WHERE isin = @asset_6),
@a7_currency = (SELECT currency FROM asset WHERE isin = @asset_7),
@a8_currency = (SELECT currency FROM asset WHERE isin = @asset_8),
@a9_currency = (SELECT currency FROM asset WHERE isin = @asset_9),
@a10_currency = (SELECT currency FROM asset WHERE isin = @asset_10);

SELECT @p_name, @asset_1, @a1_currency, @asset_2, @a2_currency, @asset_3, @a3_currency, @asset_4, @a4_currency;







CREATE TEMPORARY TABLE temp_portfolio_currencies AS
SELECT DISTINCT a.currency
FROM asset a 
RIGHT JOIN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name) p
ON p.isin = a.isin
WHERE a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name)
;

CREATE TEMPORARY TABLE temp_p_forex_pairs AS
SELECT forex_pair
FROM forex_pair
WHERE (base_currency IN (SELECT DISTINCT a.currency 
	FROM asset a 
	RIGHT JOIN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name) p
	ON p.isin = a.isin
	WHERE a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name))
OR quote_currency IN (SELECT DISTINCT a.currency 
	FROM asset a 
	RIGHT JOIN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name) p
	ON p.isin = a.isin
	WHERE a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name)))
AND forex_pair LIKE CONCAT('%', (SELECT p_currency FROM portfolio WHERE p_name = @p_name), '%')
;

CREATE TEMPORARY TABLE p_forex_count AS
SELECT count(*) num_forex_pairs
FROM temp_p_forex_pairs;

SELECT*
FROM p_forex_count;

SELECT @last_date;


SET @last_date = (SELECT date
FROM
-- Here we get started in looking up the las available date
(SELECT date, count(instrument) prices_available 
FROM (SELECT date, close, isin instrument
	FROM asset_prices 
    WHERE isin IN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name)
	UNION
	SELECT date, close, forex_pair
	FROM forex_prices
    WHERE forex_pair IN (SELECT forex_pair FROM temp_p_forex_pairs)) instruments
GROUP BY date
-- Here we want to make sure the number of assets with that date is the total number of relavant assets (all assets have prices uploaded)
HAVING prices_available = (SELECT SUM(num_assets + num_forex_pairs) total_instr
	FROM (SELECT count(*) num_assets
		FROM portfolio_assets
		WHERE portfolio_name = @p_name) sub_1,
		(SELECT num_forex_pairs
		FROM p_forex_count) sub_2)
ORDER BY date desc
LIMIT 1)last_update)
;

SET @first_date = (SELECT date
FROM
-- Here we get started in looking up the las available date
(SELECT date, count(instrument) prices_available 
FROM (SELECT date, close, isin instrument
	FROM asset_prices 
    WHERE isin IN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name)
	UNION
	SELECT date, close, forex_pair
	FROM forex_prices
    WHERE forex_pair IN (SELECT forex_pair FROM temp_p_forex_pairs)) instruments
GROUP BY date
-- Here we want to make sure the number of assets with that date is the total number of relavant assets (all assets have prices uploaded)
HAVING prices_available = (SELECT SUM(num_assets + num_forex_pairs) total_instr
	FROM (SELECT count(*) num_assets
		FROM portfolio_assets
		WHERE portfolio_name = @p_name) sub_1,
		(SELECT num_forex_pairs
		FROM p_forex_count) sub_2)
ORDER BY date asc
LIMIT 1)first_price)
;


SELECT @last_date;



