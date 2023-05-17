
-- 		1. CREATING PORTFOLIO HISTORY

-- 		1.1. CREATING A CURRENT HOLDINGS TABLE
-- 			Including
-- 			- Number of shares
-- 			- Current Value (in all currencies)
-- 			- Portfolio value
-- 			- Portfolio allocations

-- 		First we create an example Portfolio in the portfolio table:

INSERT INTO portfolio (
	portfolio_name, portfolio_currency,
	asset_1, allocation_1, 
	asset_2, allocation_2, 
	asset_3, allocation_3, 
	asset_4, allocation_4)
VALUES 
	('TT1', 'EUR', 
    'IE00BP3QZ825', 35, 
    'IE00BKPT2S34', 50, 
    'DE000A0H0728', 8.5, 
    'JE00B1VS3770', 7.5
);


-- FIRST WE SET UP A VARIABLE TO REFER TO ANY PORTFOLIO IN OUR PORTFOLIO LIST

SET @portfolio_name = 'TT1';

-- NOW WE GET THE LAST DATE IN WHICH WE HAVE PRICES FOR ALL ASSETS AND THE NECESSARY FOREX RATES OF THE PORTFOLIO

-- FIRST WE CREATE AND STORE A TOMPORARY TABLE WITH THE PORTFLIOS ASSETS


-- THIS DOES NOT WORK YET---- CHECK OUT THE LAST CHAT WITH YUR FRIEND FROM MARS


CREATE TEMPORARY TABLE @portfolio_name _assets AS
SELECT asset_1 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name 
UNION SELECT asset_2 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_3 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_4 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_5 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_6 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_7 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_8 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_9 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name
UNION SELECT asset_10 AS isin FROM portfolio WHERE portfolio_name = @portfolio_name;

-- FIRST WE GET ALL THE RELEVANT FOREX PAIRS FOR THE PORTFOLIO

-- CHECK CURRENCIES IN PORTFOLIO 
-- THAT ARE DIFFERENT FROM THE PORTFOLIO CURRENCY

SELECT DISTINCT a.currency
FROM asset a
INNER JOIN (
    SELECT asset_1 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_2 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_3 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_4 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_5 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_6 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_7 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_8 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_9 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name
    UNION
    SELECT asset_10 AS isin
    FROM portfolio
    WHERE portfolio_name = @portfolio_name) p 
ON a.isin = p.isin
WHERE a.currency != (SELECT portfolio_currency FROM portfolio WHERE portfolio_name = @portfolio_name)
;

-- FIND THE RELAVANT FOREX PAIRS FOR A PORTFOLIO:
-- WE NEED TO GO AROUND AND SEARCH FOR THE FOREX PAIRS OF EACH OF THE CURRENCIES AS FOUND THROUGH THE QUOTE AND BASE CURRENCY COLUMNS

SELECT 
    forex_pair
FROM
    forex_pair
WHERE
    forex_pair LIKE CONCAT('%', (SELECT portfolio_currency FROM portfolio WHERE portfolio_name = @portfolio_name), '%')
AND (base_currency IN (SELECT DISTINCT
                    a.currency
                FROM
                    asset a
                        INNER JOIN
                    (SELECT 
                        asset_1 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_2 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_3 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_4 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_5 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_6 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_7 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_8 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_9 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_10 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name) p ON a.isin = p.isin
                WHERE
                    a.currency != (SELECT 
                            portfolio_currency
                        FROM
                            portfolio
                        WHERE
                            portfolio_name = @portfolio_name))
OR  quote_currency IN (SELECT DISTINCT
						a.currency
                FROM
                    asset a
                        INNER JOIN
                    (SELECT 
                        asset_1 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_2 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_3 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_4 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_5 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_6 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_7 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_8 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_9 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_10 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name) p ON a.isin = p.isin
                WHERE
                    a.currency != (SELECT 
                            portfolio_currency
                        FROM
                            portfolio
                        WHERE
                            portfolio_name = @portfolio_name)))
    ;
    
-- NOW WE GET THE DIFFERENT ASSETS OF THE PORTFOLIO

 SELECT 
    asset_1 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_2 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_3 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_4 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_5 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_6 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_7 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_8 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_9 AS isin
FROM
    portfolio
WHERE
    portfolio_name = @portfolio_name 
UNION SELECT 
    asset_10 AS isin
FROM
    portfolio;






    








SELECT 
    forex_pair
FROM
    forex_pair
WHERE
    forex_pair LIKE CONCAT('%', (SELECT portfolio_currency FROM portfolio WHERE portfolio_name = @portfolio_name), '%')
        AND forex_pair LIKE CONCAT('%',
            (SELECT DISTINCT
                    a.currency
                FROM
                    asset a
                        INNER JOIN
                    (SELECT 
                        asset_1 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_2 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_3 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_4 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_5 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_6 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_7 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_8 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_9 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name UNION SELECT 
                        asset_10 AS isin
                    FROM
                        portfolio
                    WHERE
                        portfolio_name = @portfolio_name) p ON a.isin = p.isin
                WHERE
                    a.currency != (SELECT 
                            portfolio_currency
                        FROM
                            portfolio
                        WHERE
                            portfolio_name = @portfolio_name)),
            '%');





SELECT DISTINCT a.currency
FROM asset a
INNER JOIN portfolio p ON a.isin IN (p.asset_1, p.asset_2, p.asset_3, p.asset_4, p.asset_5, p.asset_6, p.asset_7, p.asset_8, p.asset_9, p.asset_10)
WHERE p.portfolio_name = @portfolio_name
  AND a.currency != (SELECT portfolio_currency FROM portfolio WHERE p.portfolio_name = @portfolio_name);







SELECT ap.isin
FROM portfolio AS p
JOIN asset_prices AS ap ON 
    ap.isin IN (p.asset_1, p.asset_2, p.asset_3, p.asset_4, p.asset_5,
                p.asset_6, p.asset_7, p.asset_8, p.asset_9, p.asset_10)
WHERE p.portfolio_name = 'TT1'
GROUP BY ap.isin;





CREATE TEMPORARY TABLE latest_date AS
SELECT min(last_date) latest_date
FROM (SELECT MAX(date) last_date, isin
FROM asset_prices
WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
GROUP BY isin
UNION
SELECT MAX(date), forex_pair
FROM forex_prices
GROUP BY forex_pair) min_date;

WITH ld AS
	(SELECT min(last_date) last_date
	FROM (SELECT MAX(date) last_date, isin
		FROM asset_prices
		WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
		GROUP BY isin
		UNION
		SELECT MAX(date), forex_pair
		FROM forex_prices
	GROUP BY forex_pair) min_date)
SELECT (SELECT min(ld.last_date) FROM ld) DATE, a.ticker TICKER, a.asset_name NAME, a.asset_class ASSET_CLASS, 
inv.isin ISIN, inv.shares SHARES, a.currency CURRENCY, curr_prices.close CURRENT_PRICE,
CASE 
	WHEN a.currency = 'USD' THEN fx.fx_rate 
    ELSE 1
END AS FX_RATE
-- FIRST TABLE IS THE ASSET TABLE WITH ALL THE DATA ABOUT THE INSTRUMENTS
FROM asset a
-- SECOND TABLE IS A RESULTS TABLE THAT FILTERS ALL TRANSACTIONS FOR THE INSTRUMENTS 
-- THAT ARE IN THE RESPECTIVE PORTFOLIO NAMED SPECIFICALLY -- > 'TT1'
RIGHT JOIN (SELECT inv.isin ISIN, sum(inv.amount) Shares
	FROM inv_transactions inv
	WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
    GROUP BY isin
    ORDER BY Shares) inv
ON a.isin = inv.isin
-- JOINING WITH THE FX PRICE DATA FROM THE LAST AVAILABLE DATE
JOIN (SELECT close fx_rate 
	FROM forex_prices
    WHERE date = (SELECT min(ld.last_date) FROM ld)) fx
-- JOINING WITH ASSET PRICE DATA SUBQUERY TABLE
JOIN (SELECT close, isin
	FROM asset_prices
    WHERE date = (SELECT min(ld.last_date) FROM ld)) curr_prices
ON curr_prices.isin = a.isin;



;

SELECT close, isin
	FROM asset_prices
    WHERE date = (SELECT latest_date FROM latest_date);




SELECT* 
FROM latest_date;

CREATE TEMPORARY TABLE latest_date AS
SELECT min(last_date) latest_date
FROM (SELECT MAX(date) last_date, isin
FROM asset_prices
WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
GROUP BY isin
UNION
SELECT MAX(date), forex_pair
FROM forex_prices
GROUP BY forex_pair) min_date;














SELECT close 
FROM forex_prices
WHERE date = (SELECT MAX(date) FROM forex_prices)
AND forex_pair = 'EURUSD';



-- NOT AN ELEGANT SOLUTION FOR SURE, TO REFER TO EACH ASSET SEPERATELY. 


-- TESTING IDEAS

-- 1 CREATING A TABLE A JOIN BETWEEN THE CALENDAR AND THE TRANSACTIONS TABLE WITH IFFERENT COUNTS FOR EACH INSTRUMENT

-- For a portfolio with: 
-- DE000A0H0728
-- IE00BKPT2S34
-- IE00BP3QZ825
-- JE00B1VS3770



CREATE TEMPORARY TABLE holdings_1 AS
SELECT c.date, isin, SUM(original_value) foreign_value, SUM(local_value) local_value, SUM(amount) num_shares
FROM (SELECT* FROM calendar WHERE date > '2022-10-01') c
	LEFT JOIN (SELECT date, isin, currency, original_value, local_value, amount
    FROM inv_transactions 
    WHERE isin = 'IE00BP3QZ825') i
	ON c.date = i.date
GROUP BY date, isin;


    
SELECT inv.isin ISIN, sum(inv.amount) Shares
	FROM inv_transactions inv
	WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
	OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
    GROUP BY isin
    ORDER BY Shares;
    
    
    
    
    
    
    
-- THAT WAS AN INTERESTING APPROACH THAT FOR SURE I WILL BE ABLE TO USE LATER!!!:
    

select p.portfolio_id, p.stock_id, p.dte, 
       Sum(t.share) 
       over (partition by p.portfolio_id, p.stock_id order by p.dte) as shares
from (select t.portfolio_id, s.stock_id, 
generate_series(t.min_td, current_date, interval '1 day') as dte
      from (select portfolio_id, min(transaction_date)::date as min_td
            from transactions t 
            group by portfolio_id
           ) t cross join
           (select distinct stock_id from transactions) s
     ) p left join
     transactions t
     on t.portfolio_id = p.portfolio_id and t.stock_id = p.stock_id and t.transaction_date::date = p.dte
order by 1, 2, 3;

 


--    -------------------------

WITH ld AS
	(SELECT min(last_date) last_date
	FROM (SELECT MAX(date) last_date, isin
		FROM asset_prices
		WHERE isin = (SELECT asset_1 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_2 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_3 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_4 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_5 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_6 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_7 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_8 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_9 FROM portfolio WHERE portfolio_name = 'TT1')
		OR isin = (SELECT asset_10 FROM portfolio WHERE portfolio_name = 'TT1')
		GROUP BY isin
		UNION
		SELECT MAX(date), forex_pair
		FROM forex_prices
	GROUP BY forex_pair) min_date)
SELECT min(ld.last_date)
FROM ld;


-- --- CHAT GPT INPUT: 

SELECT ap.isin
FROM portfolio AS p
JOIN asset_prices AS ap ON 
    ap.isin IN (p.asset_1, p.asset_2, p.asset_3, p.asset_4, p.asset_5,
                p.asset_6, p.asset_7, p.asset_8, p.asset_9, p.asset_10)
WHERE p.portfolio_name = 'TT1'
GROUP BY ap.isin;

SELECT ap.date
FROM portfolio p
JOIN asset_prices ap ON ap.isin IN (p.asset_1, p.asset_2, p.asset_3, p.asset_4, p.asset_5, p.asset_6, p.asset_7, p.asset_8, p.asset_9, p.asset_10)
JOIN forex_prices fp ON fp.forex_pair = 'EURUSD' AND fp.date = ap.date
WHERE p.portfolio_name = 'TT1'
GROUP BY ap.date
HAVING COUNT(DISTINCT ap.isin) = 4 AND COUNT(DISTINCT fp.forex_pair) = 1
ORDER BY ap.date DESC
LIMIT 1;

SELECT MIN(date) AS latest_date
FROM asset_prices ap
LEFT JOIN portfolio p ON ap.isin IN (p.asset_1, p.asset_2, p.asset_3, p.asset_4, p.asset_5, p.asset_6, p.asset_7, p.asset_8, p.asset_9, p.asset_10)
LEFT JOIN forex_prices fp ON fp.date = ap.date AND fp.forex_pair = 'EURUSD'
WHERE p.portfolio_name = 'TT1'
  AND (ap.close IS NULL OR fp.close IS NULL);