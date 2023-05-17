
-- 		BUILDING MY PORTFOLIO TRACKER

-- 		Setting the Portfolio variable
-- 		Setting 1-10 asset variables fro later use
-- 		Setting currencu varaible for ease of use further down


SET 
@p_name = 'PT1',
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
@asset_10 = (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name ORDER BY isin LIMIT 1 OFFSET 9),
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

SELECT @a1_currency;
SELECT currency FROM asset WHERE isin = @asset_1;
-- 		Now we retrieve the relevant forex pairs for the portfolio
-- 		First we find the currencies in the portfolio

CREATE TEMPORARY TABLE temp_portfolio_currencies AS
SELECT DISTINCT a.currency
FROM asset a 
RIGHT JOIN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name) p
ON p.isin = a.isin
WHERE a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name);

SELECT*
FROM temp_portfolio_currencies;


-- 		Then we find the relevant forex pairs	

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

SELECT*
FROM temp_p_forex_pairs;

-- And we crete a temporary table to count the forex_pairs for use in further queries

CREATE TEMPORARY TABLE p_forex_count AS
SELECT count(*) num_forex_pairs
FROM temp_p_forex_pairs;

SELECT*
FROM p_forex_count;

-- 		Now we find the last_update for each asset and forex pair in our respective price tables
-- 		I will set a variable with that date for ease of use as las_price_update

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

SELECT @last_date;


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

SELECT @first_date;

-- LATEST PRICES TEMPORARY TABLE


-- 		Getting started on creating the main Dashboard table

CREATE TEMPORARY TABLE p_dashboard (
LAST_UPDATE DATE,
TICKER VARCHAR(10),
NAME VARCHAR(50),
ASSET_CLASS VARCHAR(50),




SELECT @last_date DATE, a.ticker TICKER, a.asset_name NAME, a.asset_class ASSET_CLASS, 
pa.isin ISIN, inv.shares SHARES, ROUND(pr.close, 2) PRICE, a.currency CURRENCY, 
CASE 
		WHEN a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name) 
			THEN (SELECT ROUND(close, 4)
				FROM forex_prices 
                WHERE DATE = @last_date
                AND forex_pair = (SELECT forex_pair 
					FROM temp_p_forex_pairs 
                    WHERE forex_pair LIKE CONCAT('%', a.currency, '%'))
				)       
		ELSE 1
END FX_RATE, 
ROUND(inv.shares * pr.close, 2) AS `VALUE IN HOME CURRENCY`-- ,
-- inv.shares * pr.close * -- STUCK HERE------------------------------HOW CAN I CALCULATE THE AVLUE IN EURO WITHOUT REPEATING THE WHOLE QUERY?

-- , a.currency CURRENCY, curr_prices.close CURRENT_PRICE,
FROM asset a
-- FILTER ASSET DATA FOR NLY PORTFOLIO ASSETS
RIGHT JOIN (SELECT isin
	FROM portfolio_assets
	WHERE portfolio_name = @p_name) pa
ON pa.isin = a.isin
-- GET THE CURRENT HOLDINGS OF EACH ASSET
LEFT JOIN (SELECT SUM(amount) Shares, isin
	FROM inv_transactions
    GROUP BY isin) inv
ON inv.isin = a.isin
-- GET THE PRICE FOR THE RESPECTIVE DATE
LEFT JOIN (SELECT close, isin
	FROM asset_prices
    WHERE date = @last_date) pr
ON pr.isin = a.isin;
-- GET FOREX_PAIR PRICE FOR RESPECTIVE DATE


-- NEXT UP IS THE PORTFOLIO HISTORY BY DATE
-- WORK FROM HERE...

DROP TABLE portfolio_hist;


CREATE TEMPORARY TABLE portfolio_hist (
	date DATE PRIMARY KEY,
   	a1_isin VARCHAR(20),
    a1_amount INT,
    a1_price FLOAT,
    a1_local_value FLOAT,
    a1_forex_pair VARCHAR(10),
    a1_fx_rate FLOAT,
    a1_portfolio_value FLOAT,
	
    a2_isin VARCHAR(20),
    a2_amount INT,
    a2_price FLOAT,
    a2_local_value FLOAT,
	a2_forex_pair VARCHAR(10),
    a2_fx_rate FLOAT,
    a2_portfolio_value FLOAT,
	
    a3_isin VARCHAR(20),
    a3_amount INT,
    a3_price FLOAT,
    a3_local_value FLOAT,
	a3_forex_pair VARCHAR(10),
    a3_fx_rate FLOAT,
    a3_portfolio_value FLOAT,    
	
    a4_isin VARCHAR(20),
    a4_amount INT,
    a4_price FLOAT,
    a4_local_value FLOAT,
    a4_forex_pair VARCHAR(10),
    a4_fx_rate FLOAT,
    a4_portfolio_value FLOAT,
-- -------------------------------- REVISE FROM HERE 
/*
    a5_isin VARCHAR(20),
    a5_amount INT,
    a5_price FLOAT,
    a5_local_value FLOAT,
    a5_fx_rate FLOAT,
    a5_portfolio_value FLOAT,

    a6_isin VARCHAR(20),
    a6_amount INT,
    a6_price FLOAT,
    a6_local_value FLOAT,
    a6_fx_rate FLOAT,
    a6_portfolio_value FLOAT,
    
    a7_isin VARCHAR(20),
    a7_amount INT,
    a7_price FLOAT,
    a7_local_value FLOAT,
    a7_fx_rate FLOAT,
    a7_portfolio_value FLOAT,
    
    a8_isin VARCHAR(20),
    a8_amount INT,
    a8_price FLOAT,
    a8_local_value FLOAT,
    a8_fx_rate FLOAT,
    a8_portfolio_value FLOAT,
    
    a9_isin VARCHAR(20),
    a9_amount INT,
    a9_price FLOAT,
    a9_local_value FLOAT,
    a9_fx_rate FLOAT,
    a9_portfolio_value FLOAT,
    
    a10_isin VARCHAR(20),
    a10_amount INT,
    a10_price FLOAT,
    a10_local_value FLOAT,
    a10_fx_rate FLOAT,
    a10_portfolio_value FLOAT,
    */
    total_value FLOAT)
;    
    
        
INSERT INTO portfolio_hist (date)
SELECT date
		FROM calendar c
		WHERE date BETWEEN @first_date -- ALTERNATIVE AND MORE PRECISE BUT RUNS FOR 10 SEC.: (SELECT min(date) FROM inv_transactions WHERE isin IN (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name))
        AND @last_date
;


UPDATE portfolio_hist ph
SET 
a1_isin 		= 	@asset_1,		
a1_amount 		= 	(SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_1
					AND inv.date BETWEEN @first_date AND ph.date),
a1_price		= 	(SELECT close 
					FROM asset_prices ap
					WHERE isin = @asset_1
					AND ph.date = ap.date),
a1_local_value	= 	a1_amount * a1_price,
a1_forex_pair	=	IF(@a1_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a1_currency), CONCAT(@a1_currency, @p_currency)))),
a1_fx_rate			= 	IF( @a1_currency = @p_currency, 1, (SELECT close
																FROM forex_prices
																WHERE forex_pair = ph.a1_forex_pair
																AND date = ph.date)),
a1_portfolio_value 	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @p_currency) THEN a1_amount * a1_price * a1_fx_rate
                            ELSE a1_amount * a1_price / a1_fx_rate
						END,

a2_isin 		= 	@asset_2,		
a2_amount 		= 	(SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_2
					AND inv.date BETWEEN @first_date AND ph.date),
a2_price		= 	(SELECT close 
					FROM asset_prices ap
					WHERE isin = @asset_2
					AND ph.date = ap.date),
a2_local_value	= 	a2_amount * a2_price,
a2_forex_pair	=	IF(@a2_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a2_currency), CONCAT(@a2_currency, @p_currency)))),
a2_fx_rate			= 	IF( @a2_currency = @p_currency, 1, (SELECT close
																FROM forex_prices
																WHERE forex_pair = ph.a2_forex_pair
																AND date = ph.date)),
a2_portfolio_value 	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @p_currency) THEN a2_amount * a2_price * a2_fx_rate
                            ELSE a2_amount * a2_price / a2_fx_rate
						END,

a3_isin 		= 	@asset_3,		
a3_amount 		= 	(SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_3
					AND inv.date BETWEEN @first_date AND ph.date),
a3_price		= 	(SELECT close 
					FROM asset_prices ap
					WHERE isin = @asset_3
					AND ph.date = ap.date),
a3_local_value	= 	a3_amount * a3_price,
a3_forex_pair	=	IF(@a3_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a3_currency), CONCAT(@a3_currency, @p_currency)))),
a3_fx_rate			= 	IF( @a3_currency = @p_currency, 1, (SELECT close
																FROM forex_prices
																WHERE forex_pair = ph.a3_forex_pair
																AND date = ph.date)),
a3_portfolio_value 	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @p_currency) THEN a3_amount * a3_price * a3_fx_rate
                            ELSE a3_amount * a3_price / a3_fx_rate
						END,
                        
a4_isin 		= 	@asset_4,		
a4_amount 		= 	(SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_4
					AND inv.date BETWEEN @first_date AND ph.date),
a4_price		= 	(SELECT close 
					FROM asset_prices ap
					WHERE isin = @asset_4
					AND ph.date = ap.date),
a4_local_value	= 	a4_amount * a4_price,
a4_forex_pair	=	IF(@a4_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a4_currency), CONCAT(@a4_currency, @p_currency)))),
a4_fx_rate			= 	IF( @a4_currency = @p_currency, 1, (SELECT close
																FROM forex_prices
																WHERE forex_pair = ph.a4_forex_pair
																AND date = ph.date)),
a4_portfolio_value 	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @p_currency) THEN a4_amount * a4_price * a4_fx_rate
                            ELSE a4_amount * a4_price / a4_fx_rate
						END,

total_value			= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value;


SELECT*
FROM portfolio_hist
WHERE year(date) >= 2022;



-- NEXT STOP ACCOUNT HISTORY TABLE

DROP TABLE acc_hist; 

CREATE TABLE acc_hist(
date DATE PRIMARY KEY,
buy FLOAT DEFAULT 0,
sell FLOAT DEFAULT 0,
transaction_cost FLOAT DEFAULT 0,
x_connection FLOAT DEFAULT 0,
interest FLOAT DEFAULT 0,
deposit FLOAT DEFAULT 0,
withdrawl FLOAT DEFAULT 0,
tot_change FLOAT DEFAULT 0,
balance FLOAT DEFAULT 0
);

INSERT INTO acc_hist (date)
SELECT date 
FROM calendar
WHERE date BETWEEN '2022-01-01' AND current_date()
ORDER BY date desc;

UPDATE acc_hist ah
SET 
buy 				= (SELECT IFNULL((SELECT SUM(local_value) FROM inv_transactions WHERE date = ah.date AND local_value < 0 GROUP BY date),0)),
sell 				= (SELECT IFNULL((SELECT COALESCE(SUM(local_value), 0)  FROM inv_transactions WHERE date = ah.date AND local_value > 0 GROUP BY date),0)),
transaction_cost 	= (SELECT IFNULL((SELECT COALESCE(SUM(transaction_cost), 0)  FROM inv_transactions WHERE date = ah.date GROUP BY date),0)),
x_connection		= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0)  FROM acc_transactions WHERE date = ah.date AND type = 'exchange connection fee' GROUP BY date),0)),
interest			= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ah.date AND type = 'interest' GROUP BY date),0)),
deposit				= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ah.date AND type = 'deposit' GROUP BY date),0)),
withdrawl			= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ah.date AND type = 'withdrawl' GROUP BY date),0)),
tot_change 			= ah.buy + ah.sell + ah.transaction_cost + ah.x_connection + ah.interest + ah.deposit + ah.withdrawl,
balance 			= (SELECT IFNULL((SELECT SUM(tot_change) FROM (SELECT * FROM acc_hist) AS t WHERE date < ah.date) + tot_change, tot_change))--  (SELECT SUM(tot_change) FROM acc_hist WHERE date < acc_hist.date) + tot_change
;

-- OK- THE PROBLEM SEEMS TO BE THAT THERE ARE NULL VALUES EVERYWHERE SO THE TOT_CHANGE DOES NOT CALCULATE BECAUSE OF THAT. 

SELECT type FROM portfolio_tracker.acc_transactions
GROUP BY type;
SELECT * FROM acc_hist
;-- WHERE tot_change != '';





















-- 		Getting started on creating the main Dashboard table - PORTFOLIO OverVIEW!!!

CREATE TEMPORARY TABLE p_overview (
last_update DATE NULL,
ticker VARCHAR(10) NULL,
name VARCHAR(50) NULL,
asset_class VARCHAR(50) NULL,
isin VARCHAR(20) NULL,
amount INT NULL,
price FLOAT NULL,
currency VARCHAR(10) NULL,
fx_rate FLOAT NULL,
value FLOAT NULL
);

DROP TABLE p_overview;

UPDATE p_overview po
JOIN portfolio_assets pa ON po.isin = pa.isin AND pa.portfolio_name = @p_name
SET 
po.last_update = @last_date;




UPDATE p_overview
SET 
isin			= (SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name),
last_update 	= @last_date;
ticker 			= 
name 			=
asset_class


;
SELECT*
FROM p_overview;

SELECT isin FROM portfolio_assets WHERE portfolio_name = @p_name;



SELECT 
@last_date last_update,
a.ticker ticker,
a.asset_name name,


FROM 




SELECT @last_date DATE, a.ticker TICKER, a.asset_name NAME, a.asset_class ASSET_CLASS, 
pa.isin ISIN, inv.shares SHARES, ROUND(pr.close, 2) PRICE, a.currency CURRENCY, 
CASE 
		WHEN a.currency != (SELECT p_currency FROM portfolio WHERE p_name = @p_name) 
			THEN (SELECT ROUND(close, 4)
				FROM forex_prices 
                WHERE DATE = @last_date
                AND forex_pair = (SELECT forex_pair 
					FROM temp_p_forex_pairs 
                    WHERE forex_pair LIKE CONCAT('%', a.currency, '%'))
				)       
		ELSE 1
END FX_RATE, 
ROUND(inv.shares * pr.close, 2) AS `VALUE IN HOME CURRENCY`-- ,
-- inv.shares * pr.close * -- STUCK HERE------------------------------HOW CAN I CALCULATE THE AVLUE IN EURO WITHOUT REPEATING THE WHOLE QUERY?

-- , a.currency CURRENCY, curr_prices.close CURRENT_PRICE,
FROM asset a
-- FILTER ASSET DATA FOR NLY PORTFOLIO ASSETS
RIGHT JOIN (SELECT isin
	FROM portfolio_assets
	WHERE portfolio_name = @p_name) pa
ON pa.isin = a.isin
-- GET THE CURRENT HOLDINGS OF EACH ASSET
LEFT JOIN (SELECT SUM(amount) Shares, isin
	FROM inv_transactions
    GROUP BY isin) inv
ON inv.isin = a.isin
-- GET THE PRICE FOR THE RESPECTIVE DATE
LEFT JOIN (SELECT close, isin
	FROM asset_prices
    WHERE date = @last_date) pr
ON pr.isin = a.isin;
-- GET FOREX_PAIR PRICE FOR RESPECTIVE DATE








