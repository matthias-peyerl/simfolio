
DELIMITER //
CREATE PROCEDURE user_update()
BEGIN
	UPDATE sim_accounts
    SET
    inicial_balance = @inicial_balance 
    WHERE acc_holder = @username;
    
END //
;

DELIMITER //
CREATE PROCEDURE sim_prepare()
BEGIN

DROP TABLE IF EXISTS temp_portfolio_currencies;
DROP TABLE IF EXISTS temp_p_forex_pairs;
DROP TABLE IF EXISTS p_forex_count;
DROP TABLE IF EXISTS sim_looper;
DROP TABLE IF EXISTS sim_temp;

SET
@p_currency = (SELECT p_currency FROM portfolio WHERE p_name = @p_name),
@p_leverage = (SELECT leverage FROM strategies WHERE strategy_name = @strategy),
@p_min_rebalancing = (SELECT min_rebalancing FROM strategies WHERE strategy_name = @strategy),
@p_rel_rebalancing = (SELECT rel_rebalancing FROM strategies WHERE strategy_name = @strategy),
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

SET
@a1_allocation = (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_1),
@a2_allocation = (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_2),
@a3_allocation = (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_3),
@a4_allocation = (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_4);


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
AND forex_pair LIKE CONCAT('%', (SELECT p_currency FROM portfolio WHERE p_name = @p_name), '%');

CREATE TEMPORARY TABLE p_forex_count AS
SELECT count(*) num_forex_pairs
FROM temp_p_forex_pairs;

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
LIMIT 1)first_date);

END //
;

DELIMITER //
CREATE PROCEDURE sim_step1() -- Creating the table and filling in date and price data 
BEGIN
CREATE TEMPORARY TABLE sim_temp ( -- Temporary table for a simulation
    date DATE PRIMARY KEY,
    p_name VARCHAR(100),
   	a1_isin VARCHAR(20),
    a1_price FLOAT,
    a1_forex_pair VARCHAR(10),
    a1_fx_rate FLOAT,    
    a1_portfolio_price FLOAT,
    
    a1_amount INT,
    a1_medium_price FLOAT,
    a1_local_value FLOAT,
    a1_portfolio_value FLOAT,
        
	a1_local_change_d FLOAT,
	a1_local_change_w FLOAT,
	a1_local_change_m FLOAT,
	a1_local_change_q FLOAT,
	a1_local_change_y FLOAT,
	a1_portfolio_change_d FLOAT,
	a1_portfolio_change_w FLOAT,
	a1_portfolio_change_m FLOAT,
	a1_portfolio_change_q FLOAT,
	a1_portfolio_change_y FLOAT,
    
    a2_isin VARCHAR(20),
    a2_price FLOAT,
    a2_forex_pair VARCHAR(20),
    a2_fx_rate FLOAT,    
    a2_portfolio_price FLOAT,
    
    a2_amount INT,
    a2_medium_price FLOAT,
    a2_local_value FLOAT,
    a2_portfolio_value FLOAT,

    a2_local_change_d FLOAT,
	a2_local_change_w FLOAT,
	a2_local_change_m FLOAT,
	a2_local_change_q FLOAT,
	a2_local_change_y FLOAT,
	a2_portfolio_change_d FLOAT,
	a2_portfolio_change_w FLOAT,
	a2_portfolio_change_m FLOAT,
	a2_portfolio_change_q FLOAT,
	a2_portfolio_change_y FLOAT,

    a3_isin VARCHAR(30),
    a3_price FLOAT,
    a3_forex_pair VARCHAR(30),
    a3_fx_rate FLOAT,    
    a3_portfolio_price FLOAT,
        
    a3_amount INT,
    a3_medium_price FLOAT,
    a3_local_value FLOAT,
    a3_portfolio_value FLOAT,

    a3_local_change_d FLOAT,
	a3_local_change_w FLOAT,
	a3_local_change_m FLOAT,
	a3_local_change_q FLOAT,
	a3_local_change_y FLOAT,
	a3_portfolio_change_d FLOAT,
	a3_portfolio_change_w FLOAT,
	a3_portfolio_change_m FLOAT,
	a3_portfolio_change_q FLOAT,
	a3_portfolio_change_y FLOAT,

	a4_isin VARCHAR(40),
    a4_price FLOAT,
    a4_forex_pair VARCHAR(40),
    a4_fx_rate FLOAT,    
    a4_portfolio_price FLOAT,
    
    a4_amount INT,
    a4_medium_price FLOAT,
    a4_local_value FLOAT,
    a4_portfolio_value FLOAT,

    a4_local_change_d FLOAT,
	a4_local_change_w FLOAT,
	a4_local_change_m FLOAT,
	a4_local_change_q FLOAT,
	a4_local_change_y FLOAT,
	a4_portfolio_change_d FLOAT,
	a4_portfolio_change_w FLOAT,
	a4_portfolio_change_m FLOAT,
	a4_portfolio_change_q FLOAT,
	a4_portfolio_change_y FLOAT,
  
    p_value FLOAT,
    
    a1_allocation FLOAT,
    a2_allocation FLOAT,
    a3_allocation FLOAT,
    a4_allocation FLOAT,
    
    -- ACCOUNT METRICS
    
    usd_exposure_usd FLOAT,
    usd_exposure_eur FLOAT,
    eur_exposure FLOAT,
    
    buy FLOAT DEFAULT 0,
	sell FLOAT DEFAULT 0,
	deposit FLOAT DEFAULT 0,
	withdrawl FLOAT DEFAULT 0,
	tot_change FLOAT DEFAULT 0,
	acc_balance FLOAT DEFAULT 0,
    tot_balance FLOAT DEFAULT 0,
    leverage_rate FLOAT
);

-- STEP 1 -> INTRODUCING CALENDAR DATES

INSERT INTO sim_temp (date)
	SELECT date 
	FROM calendar
	-- WHERE is_Weekday = 1
    WHERE date BETWEEN @first_date AND @last_date
	ORDER BY date desc;

-- STEP 2 -> INTRODUCING KNOWN VALUES

UPDATE sim_temp ph
SET 
p_name 				= 	@p_name,
a1_isin 			= 	@asset_1,	
a1_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date),
a1_forex_pair		=	IF(@a1_currency = @p_currency, @p_currency, (SELECT forex_pair FROM forex_pair WHERE forex_pair IN (CONCAT(@p_currency, @a1_currency), CONCAT(@a1_currency, @p_currency)))),
a1_fx_rate			= 	IF( @a1_currency = @p_currency, 1, (SELECT last_close FROM forex_prices WHERE forex_pair = ph.a1_forex_pair AND date = ph.date)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @p_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END, 
a2_isin 			= 	@asset_2,	
a2_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date),
a2_forex_pair		=	IF(@a2_currency = @p_currency, @p_currency, (SELECT forex_pair FROM forex_pair WHERE forex_pair IN (CONCAT(@p_currency, @a2_currency), CONCAT(@a2_currency, @p_currency)))),
a2_fx_rate			= 	IF( @a2_currency = @p_currency, 1, (SELECT last_close FROM forex_prices WHERE forex_pair = ph.a2_forex_pair AND date = ph.date)),
a2_portfolio_price	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @p_currency) THEN a2_price * a2_fx_rate
                            ELSE a2_price / a2_fx_rate
						END, 
a3_isin 			= 	@asset_3,	
a3_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date),
a3_forex_pair		=	IF(@a3_currency = @p_currency, @p_currency, (SELECT forex_pair FROM forex_pair WHERE forex_pair IN (CONCAT(@p_currency, @a3_currency), CONCAT(@a3_currency, @p_currency)))),
a3_fx_rate			= 	IF( @a3_currency = @p_currency, 1, (SELECT last_close FROM forex_prices WHERE forex_pair = ph.a3_forex_pair AND date = ph.date)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @p_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END, 
a4_isin 			= 	@asset_4,	
a4_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date),
a4_forex_pair		=	IF(@a4_currency = @p_currency, @p_currency, (SELECT forex_pair FROM forex_pair WHERE forex_pair IN (CONCAT(@p_currency, @a4_currency), CONCAT(@a4_currency, @p_currency)))),
a4_fx_rate			= 	IF( @a4_currency = @p_currency, 1, (SELECT last_close FROM forex_prices WHERE forex_pair = ph.a4_forex_pair AND date = ph.date)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @p_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END, 
deposit				= 0,
withdrawl			= 0;

-- STEP 3:  INTRODUCING FIRST LINE OF VALUES 

UPDATE sim_temp
SET 
a1_amount 				= FLOOR(@inicial_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_1 AND portfolio_name = @p_name)/100/a1_portfolio_price),
a2_amount 				= FLOOR(@inicial_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_2 AND portfolio_name = @p_name)/100/a2_portfolio_price),
a3_amount 				= FLOOR(@inicial_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_3 AND portfolio_name = @p_name)/100/a3_portfolio_price),
a4_amount 				= FLOOR(@inicial_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_4 AND portfolio_name = @p_name)/100/a4_portfolio_price),
a1_portfolio_value		= a1_amount * a1_portfolio_price,
a2_portfolio_value		= a2_amount * a2_portfolio_price,
a3_portfolio_value		= a3_amount * a3_portfolio_price,
a4_portfolio_value		= a4_amount * a4_portfolio_price,
p_value 				= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value,
buy 					= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value,
tot_change				= -(a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value),
acc_balance				= @inicial_balance + tot_change,
tot_balance				= p_value + acc_balance,
leverage_rate			= p_value / tot_balance
WHERE date 				= @first_date;

-- TO AVOID ISSUES WITH REOPENING TABLES (WHAT SQL REFUSES TO DO ON OCCASION) I CREATE A NEW COPY OF THE RESULTS TABLE AND DELETE THE OLD ONE. 
-- THAT ALSO HELPS TO AVOID HAVING TO ALWAYS DELETE THE TABLES ON STARTING OVER.
CREATE TABLE sim_looper LIKE sim_temp;
INSERT INTO sim_looper SELECT* FROM sim_temp;

END //
;

DELIMITER //
CREATE PROCEDURE sim_step2() -- Creating the portfolio simulation day by day
BEGIN

DECLARE counter INT DEFAULT 2; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date DATE DEFAULT ADDDATE(@first_date, 1);

WHILE counter <= (SELECT datediff(@last_date, @first_date)) DO
		
UPDATE sim_looper t1
JOIN (
SELECT 
date, 
LAG(a1_amount) OVER (ORDER BY date) prev_a1_amount,
LAG(a2_amount) OVER (ORDER BY date) prev_a2_amount,
LAG(a3_amount) OVER (ORDER BY date) prev_a3_amount,
LAG(a4_amount) OVER (ORDER BY date) prev_a4_amount,
LAG(acc_balance) OVER (ORDER BY date) prev_acc_balance,
LAG(tot_balance) OVER (ORDER BY date) prev_tot_balance,
LAG(a1_allocation) OVER (ORDER BY date) a1_prev_allocation,
LAG(a2_allocation) OVER (ORDER BY date) a2_prev_allocation,
LAG(a3_allocation) OVER (ORDER BY date) a3_prev_allocation,
LAG(a4_allocation) OVER (ORDER BY date) a4_prev_allocation
FROM sim_looper
) t2
ON t1.date = t2.date
SET 
t1.a1_amount 				= IF(ABS(t2.a1_prev_allocation - @a1_allocation) / @a1_allocation > @p_rel_rebalancing / 100,

FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a1_allocation / 100 / a1_portfolio_price),
                                    t2.prev_a1_amount),
                                    
                                    
t1.a2_amount 				= IF( ( -- ABS(a2_prev_allocation - @a2_allocation) > @p_min_rebalancing AND 
(ABS(a2_prev_allocation - @a2_alloaction) / @a2_allocation) > @p_rel_rebalancing / 100),
									FLOOR(t2.prev_tot_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * @a2_allocation/100/a2_portfolio_price),
                                    prev_a2_amount),
t1.a3_amount 				= IF( ( -- ABS(a3_prev_allocation - @a3_allocation) > @p_min_rebalancing AND 
(ABS(a3_prev_allocation - @a3_alloaction) / @a3_allocation) > @p_rel_rebalancing / 100),
									FLOOR(t2.prev_tot_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * @a3_allocation/100/a3_portfolio_price),
                                    prev_a3_amount),
t1.a4_amount 				= IF( ( -- ABS(a1_prev_allocation - @a4_allocation) > @p_min_rebalancing AND 
(ABS(a4_prev_allocation - @a4_alloaction) / @a4_allocation) > @p_rel_rebalancing / 100),
									FLOOR(t2.prev_tot_balance * COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1) * @a4_allocation/100/a4_portfolio_price),
                                    prev_a4_amount),
t1.a1_portfolio_value 		= a1_amount * a1_portfolio_price,
t1.a2_portfolio_value 		= a2_amount * a2_portfolio_price,
t1.a3_portfolio_value 		= a3_amount * a3_portfolio_price,
t1.a4_portfolio_value 		= a4_amount * a4_portfolio_price,
t1.p_value					= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value,
t1.buy 						=	(SELECT 	IF(a1_amount > t2.prev_a1_amount, -t1.a1_portfolio_price * (t1.a1_amount - t2.prev_a1_amount),0)+
											IF(a2_amount > t2.prev_a2_amount, -t1.a2_portfolio_price * (t1.a2_amount - t2.prev_a2_amount),0)+ 
											IF(a3_amount > t2.prev_a3_amount, -t1.a3_portfolio_price * (t1.a3_amount - t2.prev_a3_amount),0)+
											IF(a4_amount > t2.prev_a4_amount, -t1.a4_portfolio_price * (t1.a4_amount - t2.prev_a4_amount),0)),
t1.sell						=	(SELECT 	IF(a1_amount < t2.prev_a1_amount, -t1.a1_portfolio_price * (t1.a1_amount - t2.prev_a1_amount),0) +
											IF(a2_amount < t2.prev_a2_amount, -t1.a2_portfolio_price * (t1.a2_amount - t2.prev_a2_amount),0)+ 
											IF(a3_amount < t2.prev_a3_amount, -t1.a3_portfolio_price * (t1.a3_amount - t2.prev_a3_amount),0)+ 
											IF(a4_amount < t2.prev_a4_amount, -t1.a4_portfolio_price * (t1.a4_amount - t2.prev_a4_amount),0)),
t1.tot_change				=	t1.buy + t1.sell + t1.deposit + t1.withdrawl,
t1.acc_balance				=	CASE
								WHEN t1.date = @first_date THEN tot_change
								ELSE t2.prev_acc_balance + tot_change
								END,
t1.tot_balance				=	acc_balance + p_value

WHERE t1.date = loop_date;
        
        SET counter = counter + 1;
        SET loop_date = DATE_ADD(loop_date, INTERVAL 1 DAY);
        
	END WHILE;

END //
;

DELIMETER //
CREATE PROCEDURE sim_step3() -- Filling the table with the remaining data based on the simulation data
BEGIN

UPDATE sim_looper sl
SET
a1_local_value 		= a1_price * a1_amount,
a2_local_value 		= a2_price * a2_amount,
a3_local_value 		= a3_price * a3_amount,
a4_local_value 		= a4_price * a4_amount,

a1_allocation 		= (a1_portfolio_value / p_value)*100,
a2_allocation 		= (a2_portfolio_value / p_value)*100,
a3_allocation 		= (a3_portfolio_value / p_value)*100,
a4_allocation 		= (a4_portfolio_value / p_value)*100,

usd_exposure_usd	= IF(@a1_currency = 'USD', a1_local_value, 0)
					+ IF(@a2_currency = 'USD', a2_local_value, 0)
                    + IF(@a3_currency = 'USD', a3_local_value, 0)
                    + IF(@a4_currency = 'USD', a4_local_value, 0),

usd_exposure_eur	= usd_exposure_usd / (SELECT last_close FROM forex_prices WHERE forex_pair = 'EURUSD' AND date = sl.date),

eur_exposure		= IF(@a1_currency = 'EUR', a1_local_value, 0)
					+ IF(@a2_currency = 'EUR', a2_local_value, 0)
                    + IF(@a3_currency = 'EUR', a3_local_value, 0)
                    + IF(@a4_currency = 'EUR', a4_local_value, 0),

leverage_rate		= p_value / tot_balance -1 ;    




UPDATE sim_looper t1 
JOIN (SELECT 
date, 
a1_price, 
LAG(a1_price,1) OVER (ORDER BY date) AS a1_prev_price_1d, -- a1-normal lag 1 day 
LAG(a1_price,7) OVER (ORDER BY date) AS a1_prev_price_7d,
LAG(a1_price,30) OVER (ORDER BY date) AS a1_prev_price_30d,
LAG(a1_price,90) OVER (ORDER BY date) AS a1_prev_price_90d,
LAG(a1_price,365) OVER (ORDER BY date) AS a1_prev_price_365d,
a1_portfolio_price,
LAG(a1_portfolio_price,1) OVER (ORDER BY date) AS a1_prev_portfolio_price_1d, -- a1-normal lag 1 day 
LAG(a1_portfolio_price,7) OVER (ORDER BY date) AS a1_prev_portfolio_price_7d,
LAG(a1_portfolio_price,30) OVER (ORDER BY date) AS a1_prev_portfolio_price_30d,
LAG(a1_portfolio_price,90) OVER (ORDER BY date) AS a1_prev_portfolio_price_90d,
LAG(a1_portfolio_price,365) OVER (ORDER BY date) AS a1_prev_portfolio_price_365d,

a2_price, 
LAG(a2_price,1) OVER (ORDER BY date) AS a2_prev_price_1d, -- a2-normal lag 1 day 
LAG(a2_price,7) OVER (ORDER BY date) AS a2_prev_price_7d,
LAG(a2_price,30) OVER (ORDER BY date) AS a2_prev_price_30d,
LAG(a2_price,90) OVER (ORDER BY date) AS a2_prev_price_90d,
LAG(a2_price,365) OVER (ORDER BY date) AS a2_prev_price_365d,
a2_portfolio_price,
LAG(a2_portfolio_price,1) OVER (ORDER BY date) AS a2_prev_portfolio_price_1d, -- a2-normal lag 1 day 
LAG(a2_portfolio_price,7) OVER (ORDER BY date) AS a2_prev_portfolio_price_7d,
LAG(a2_portfolio_price,30) OVER (ORDER BY date) AS a2_prev_portfolio_price_30d,
LAG(a2_portfolio_price,90) OVER (ORDER BY date) AS a2_prev_portfolio_price_90d,
LAG(a2_portfolio_price,365) OVER (ORDER BY date) AS a2_prev_portfolio_price_365d,

a3_price, 
LAG(a3_price,1) OVER (ORDER BY date) AS a3_prev_price_1d, -- a3-normal lag 1 day 
LAG(a3_price,7) OVER (ORDER BY date) AS a3_prev_price_7d,
LAG(a3_price,30) OVER (ORDER BY date) AS a3_prev_price_30d,
LAG(a3_price,90) OVER (ORDER BY date) AS a3_prev_price_90d,
LAG(a3_price,365) OVER (ORDER BY date) AS a3_prev_price_365d,
a3_portfolio_price,
LAG(a3_portfolio_price,1) OVER (ORDER BY date) AS a3_prev_portfolio_price_1d, -- a3-normal lag 1 day 
LAG(a3_portfolio_price,7) OVER (ORDER BY date) AS a3_prev_portfolio_price_7d,
LAG(a3_portfolio_price,30) OVER (ORDER BY date) AS a3_prev_portfolio_price_30d,
LAG(a3_portfolio_price,90) OVER (ORDER BY date) AS a3_prev_portfolio_price_90d,
LAG(a3_portfolio_price,365) OVER (ORDER BY date) AS a3_prev_portfolio_price_365d,

a4_price, 
LAG(a4_price,1) OVER (ORDER BY date) AS a4_prev_price_1d, -- a4-normal lag 1 day 
LAG(a4_price,7) OVER (ORDER BY date) AS a4_prev_price_7d,
LAG(a4_price,30) OVER (ORDER BY date) AS a4_prev_price_30d,
LAG(a4_price,90) OVER (ORDER BY date) AS a4_prev_price_90d,
LAG(a4_price,365) OVER (ORDER BY date) AS a4_prev_price_365d,
a4_portfolio_price,
LAG(a4_portfolio_price,1) OVER (ORDER BY date) AS a4_prev_portfolio_price_1d, -- a4-normal lag 1 day 
LAG(a4_portfolio_price,7) OVER (ORDER BY date) AS a4_prev_portfolio_price_7d,
LAG(a4_portfolio_price,30) OVER (ORDER BY date) AS a4_prev_portfolio_price_30d,
LAG(a4_portfolio_price,90) OVER (ORDER BY date) AS a4_prev_portfolio_price_90d,
LAG(a4_portfolio_price,365) OVER (ORDER BY date) AS a4_prev_portfolio_price_365d

FROM sim_looper) t2
ON t1.date = t2.date
SET 
t1.a1_local_change_d 	= ((t1.a1_price - t2.a1_prev_price_1d) / t2.a1_prev_price_1d) * 100,
t1.a1_local_change_w 	= ((t1.a1_price - t2.a1_prev_price_7d) / t2.a1_prev_price_7d) * 100,
t1.a1_local_change_m 	= ((t1.a1_price - t2.a1_prev_price_7d) / t2.a1_prev_price_30d) * 100,
t1.a1_local_change_q 	= ((t1.a1_price - t2.a1_prev_price_7d) / t2.a1_prev_price_90d) * 100,
t1.a1_local_change_y 	= ((t1.a1_price - t2.a1_prev_price_7d) / t2.a1_prev_price_365d) * 100,
a1_portfolio_change_d 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_1d) / t2.a1_prev_portfolio_price_1d) * 100,
a1_portfolio_change_w 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_7d) / t2.a1_prev_portfolio_price_7d) * 100,
a1_portfolio_change_m 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_30d) / t2.a1_prev_portfolio_price_30d) * 100,
a1_portfolio_change_q 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_90d) / t2.a1_prev_portfolio_price_90d) * 100,
a1_portfolio_change_y 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_365d) / t2.a1_prev_portfolio_price_365d) * 100,

t1.a2_local_change_d 	= ((t1.a2_price - t2.a2_prev_price_1d) / t2.a2_prev_price_1d) * 100,
t1.a2_local_change_w 	= ((t1.a2_price - t2.a2_prev_price_7d) / t2.a2_prev_price_7d) * 100,
t1.a2_local_change_m 	= ((t1.a2_price - t2.a2_prev_price_7d) / t2.a2_prev_price_30d) * 100,
t1.a2_local_change_q 	= ((t1.a2_price - t2.a2_prev_price_7d) / t2.a2_prev_price_90d) * 100,
t1.a2_local_change_y 	= ((t1.a2_price - t2.a2_prev_price_7d) / t2.a2_prev_price_365d) * 100,
a2_portfolio_change_d 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_1d) / t2.a2_prev_portfolio_price_1d) * 100,
a2_portfolio_change_w 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_7d) / t2.a2_prev_portfolio_price_7d) * 100,
a2_portfolio_change_m 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_30d) / t2.a2_prev_portfolio_price_30d) * 100,
a2_portfolio_change_q 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_90d) / t2.a2_prev_portfolio_price_90d) * 100,
a2_portfolio_change_y 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_365d) / t2.a2_prev_portfolio_price_365d) * 100,

t1.a3_local_change_d 	= ((t1.a3_price - t2.a3_prev_price_1d) / t2.a3_prev_price_1d) * 100,
t1.a3_local_change_w 	= ((t1.a3_price - t2.a3_prev_price_7d) / t2.a3_prev_price_7d) * 100,
t1.a3_local_change_m 	= ((t1.a3_price - t2.a3_prev_price_7d) / t2.a3_prev_price_30d) * 100,
t1.a3_local_change_q 	= ((t1.a3_price - t2.a3_prev_price_7d) / t2.a3_prev_price_90d) * 100,
t1.a3_local_change_y 	= ((t1.a3_price - t2.a3_prev_price_7d) / t2.a3_prev_price_365d) * 100,
a3_portfolio_change_d 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_1d) / t2.a3_prev_portfolio_price_1d) * 100,
a3_portfolio_change_w 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_7d) / t2.a3_prev_portfolio_price_7d) * 100,
a3_portfolio_change_m 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_30d) / t2.a3_prev_portfolio_price_30d) * 100,
a3_portfolio_change_q 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_90d) / t2.a3_prev_portfolio_price_90d) * 100,
a3_portfolio_change_y 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_365d) / t2.a3_prev_portfolio_price_365d) * 100,

t1.a4_local_change_d 	= ((t1.a4_price - t2.a4_prev_price_1d) / t2.a4_prev_price_1d) * 100,
t1.a4_local_change_w 	= ((t1.a4_price - t2.a4_prev_price_7d) / t2.a4_prev_price_7d) * 100,
t1.a4_local_change_m 	= ((t1.a4_price - t2.a4_prev_price_7d) / t2.a4_prev_price_30d) * 100,
t1.a4_local_change_q 	= ((t1.a4_price - t2.a4_prev_price_7d) / t2.a4_prev_price_90d) * 100,
t1.a4_local_change_y 	= ((t1.a4_price - t2.a4_prev_price_7d) / t2.a4_prev_price_365d) * 100,
a4_portfolio_change_d 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_1d) / t2.a4_prev_portfolio_price_1d) * 100,
a4_portfolio_change_w 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_7d) / t2.a4_prev_portfolio_price_7d) * 100,
a4_portfolio_change_m 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_30d) / t2.a4_prev_portfolio_price_30d) * 100,
a4_portfolio_change_q 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_90d) / t2.a4_prev_portfolio_price_90d) * 100,
a4_portfolio_change_y 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_365d) / t2.a4_prev_portfolio_price_365d) * 100;

SELECT* 
FROM sim_looper;

END //
;

DELIMETER //
CREATE PROCEDURE sim_save()
BEGIN

DELETE
FROM sim_data
WHERE p_name = @p_name;

INSERT INTO sim_data (date, p_name, a1_isin, a1_price, a1_forex_pair, a1_fx_rate, a1_portfolio_price, a1_amount, a1_medium_price, a1_local_value, a1_portfolio_value, a1_local_change_d, a1_local_change_w, a1_local_change_m, a1_local_change_q, a1_local_change_y, a1_portfolio_change_d, a1_portfolio_change_w, a1_portfolio_change_m, a1_portfolio_change_q, a1_portfolio_change_y, a2_isin, a2_price, a2_forex_pair, a2_fx_rate, a2_portfolio_price, a2_amount, a2_medium_price, a2_local_value, a2_portfolio_value, a2_local_change_d, a2_local_change_w, a2_local_change_m, a2_local_change_q, a2_local_change_y, a2_portfolio_change_d, a2_portfolio_change_w, a2_portfolio_change_m, a2_portfolio_change_q, a2_portfolio_change_y, a3_isin, a3_price, a3_forex_pair, a3_fx_rate, a3_portfolio_price, a3_amount, a3_medium_price, a3_local_value, a3_portfolio_value, a3_local_change_d, a3_local_change_w, a3_local_change_m, a3_local_change_q, a3_local_change_y, a3_portfolio_change_d, a3_portfolio_change_w, a3_portfolio_change_m, a3_portfolio_change_q, a3_portfolio_change_y, a4_isin, a4_price, a4_forex_pair, a4_fx_rate, a4_portfolio_price, a4_amount, a4_medium_price, a4_local_value, a4_portfolio_value, a4_local_change_d, a4_local_change_w, a4_local_change_m, a4_local_change_q, a4_local_change_y, a4_portfolio_change_d, a4_portfolio_change_w, a4_portfolio_change_m, a4_portfolio_change_q, a4_portfolio_change_y, p_value, a1_allocation, a2_allocation, a3_allocation, a4_allocation, usd_exposure_usd, usd_exposure_eur, eur_exposure, buy, sell, deposit, withdrawl, tot_change, acc_balance, tot_balance, leverage_rate)
SELECT* FROM sim_looper;


END //
;

DELIMETER //
CREATE PROCEDURE run_simulation()
BEGIN 

CALL user_update;
CALL sim_prepare;
CALL sim_step1;
CALL sim_step2;
CALL sim_step3;

END //
;

DELIMETER //
CREATE PROCEDURE run_and_save()
BEGIN 

CALL user_update;
CALL sim_prepare;
CALL sim_step1;
CALL sim_step2;
CALL sim_step3;
CALL sim_save;

END //














DELIMETER
