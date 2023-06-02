
SELECT CEILING((DATEDIFF(@last_date, @first_date)-1)/@batch_size) ;
SELECT @last_date;


CALL run_simulation;

CALL user_update();
CALL sim_prepare();
CALL sim_table_creation();
CALL sim_relative_looper();
CALL sim_final_data_population();


DROP PROCEDURE sim_prepare;
DROP PROCEDURE sim_table_creation;
DROP PROCEDURE sim_relative_looper;
DROP PROCEDURE sim_final_data_population;
DROP PROCEDURE run_simulation;

SELECT * FROM sim_temp;

SELECT COUNT(*) FROM sim_temp
WHERE a1_amount IS NOT NULL;
DROP TABLE sim_temp;

SELECT* FROM sim_looper;
DROP TABLE sim_looper;



DELIMITER //
CREATE PROCEDURE sim_table_creation() -- Creating the table and filling in date and price data 
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
    a1_amount_change INT,
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
	a2_amount_change INT,
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
	a3_amount_change INT,
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
    a4_amount_change INT,
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
    transaction_costs FLOAT DEFAULT 0,
    interest FLOAT DEFAULT 0,
	deposit FLOAT DEFAULT 0,
	withdrawl FLOAT DEFAULT 0,
	tot_change FLOAT DEFAULT 0,
	acc_balance FLOAT DEFAULT 0,
    tot_balance FLOAT DEFAULT 0,
    leverage_rate FLOAT,
    
    tot_balance_change_d FLOAT,
	tot_balance_change_w FLOAT,
	tot_balance_change_m FLOAT,
	tot_balance_change_q FLOAT,
	tot_balance_change_y FLOAT
    
);

INSERT INTO sim_temp (date)
	SELECT date 
	FROM calendar
	-- WHERE is_Weekday = 1
    WHERE date = @first_date; 

-- INTRODUCING KNOWN LOOKUP VALUES

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
						END;

-- INTRODUCING FIRS ROW VALUES

UPDATE sim_temp
SET 
a1_amount 				= FLOOR(@inicial_balance * COALESCE(@p_leverage / 100 + 1,1) * @a1_allocation / 100 / a1_portfolio_price), -- CHECK AFTER CHANGES
a2_amount 				= FLOOR(@inicial_balance * COALESCE(@p_leverage / 100 + 1,1) * @a2_allocation / 100 / a2_portfolio_price), -- CHECK AFTER CHANGES
a3_amount 				= FLOOR(@inicial_balance * COALESCE(@p_leverage / 100 + 1,1) * @a3_allocation / 100 / a3_portfolio_price), -- CHECK AFTER CHANGES
a4_amount 				= FLOOR(@inicial_balance * COALESCE(@p_leverage / 100 + 1,1) * @a4_allocation / 100 / a4_portfolio_price), -- CHECK AFTER CHANGES
a1_amount_change		= a1_amount,
a2_amount_change		= a2_amount,
a3_amount_change		= a3_amount,
a4_amount_change		= a4_amount,
a1_portfolio_value		= a1_amount * a1_portfolio_price,
a2_portfolio_value		= a2_amount * a2_portfolio_price,
a3_portfolio_value		= a3_amount * a3_portfolio_price,
a4_portfolio_value		= a4_amount * a4_portfolio_price,
p_value 				= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value,
buy 					= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value,
transaction_costs		= -(IF(a1_amount_change != 0, 1, 0)
							+ IF(a2_amount_change != 0, 1, 0)
							+ IF(a3_amount_change != 0, 1, 0)
							+ IF(a4_amount_change != 0, 1, 0)) * @p_transaction_cost,
tot_change				= -(a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value) + transaction_costs,
acc_balance				= @inicial_balance + tot_change,
tot_balance				= p_value + acc_balance,
leverage_rate			= p_value / tot_balance,
a1_allocation 			= (a1_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a2_allocation 			= (a2_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a3_allocation 			= (a3_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a4_allocation 			= (a4_portfolio_value / (tot_balance*((@p_leverage+100)/100)))

WHERE date 				= @first_date;

-- CREATE TABLE sim_looper LIKE sim_temp;
-- INSERT INTO sim_looper SELECT* FROM sim_temp;

ALTER TABLE sim_temp
-- ALTER TABLE sim_looper 
ADD INDEX idx_date(date);

END //


-- 1. INTRODUCING FIRST DATE AND FIRST ROW VALUES
-- 2. LOOP WITH X + 1 DATES PER ROUNDTRIP
-- 		SELECT LATEST VALUES OF SIM_TABLE 
-- 			IF THEY ARE < @LAST_DATE --> WHILE MAX(DATE) < LAST_DATE, DO:
-- 				INTRODUCE THEM INTO THE NEW TABLE
-- 	 			INTRODUCE 100 MORE CALENDAR DAYS
-- 				INTRODUCE KNOWN VALUES
-- 				CALCULATE VALUES
-- 				DELETE FIRST ROW
-- 				UNITE THE TABLE WITH MAIN TABLE 		
-- 			ELSE STOP LOOP AND DELETE DATES THAT ARE > @LAST DATE	

DELIMITER //
CREATE PROCEDURE sim_relative_looper() -- Creating the portfolio simulation day by day
BEGIN

DECLARE outer_counter INT DEFAULT 1;
DECLARE inner_counter INT DEFAULT 1; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date DATE DEFAULT ADDDATE((SELECT MAX(date) FROM sim_temp GROUP BY date), 1);

CREATE TABLE sim_looper LIKE sim_temp;

-- START THE OUTER LOOP TO INTRODUCE A NEW BATCH AND THEN LOOP THROUH IT IN THE INNER LOOP
-- INTRODUCE NEW BATCH 

-- SETTING THE COUNTER FOR THE OUTER LOOP TO THE TOTAL DAYS DEVIDED BY BATCH SIZE ROUNDING UP (AND LATER DELETING ROWS WITH NULL VALUES)

WHILE outer_counter <= CEILING((DATEDIFF(@last_date, @first_date)-1)/@batch_size) DO

SET @max_date = (SELECT date FROM sim_temp ORDER BY date DESC LIMIT 1);

-- INSERT LAST ROW FROM EXISTING DATA IN TABLE
INSERT INTO sim_looper 
	SELECT* FROM sim_temp WHERE date = @max_date; 

-- INSERT BATCHSIZE DATES
INSERT INTO sim_looper (date)
	SELECT date 
	FROM calendar
    WHERE date BETWEEN adddate(@max_date, 1) 
				AND adddate(@max_date, @batch_size); 

-- INSERT KNOWN LOOKUP DATA
UPDATE sim_looper ph
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
						END;

-- CREATING THE INNER LOOP

WHILE inner_counter <= @batch_size AND loop_date <= @last_date DO
		
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
LAG(leverage_rate) OVER (ORDER BY date) prev_leverage_rate,
LAG(a1_allocation) OVER (ORDER BY date) a1_prev_allocation,
LAG(a2_allocation) OVER (ORDER BY date) a2_prev_allocation,
LAG(a3_allocation) OVER (ORDER BY date) a3_prev_allocation,
LAG(a4_allocation) OVER (ORDER BY date) a4_prev_allocation
FROM sim_looper
) t2
ON t1.date = t2.date
SET 
t1.a1_amount 				= IF(((SELECT close FROM asset_prices WHERE s = @asset_1 AND date = t1.date) IS NOT NULL
									AND ((ABS(t2.a1_prev_allocation * 100 - @a1_allocation) / @a1_allocation >= @p_rel_rebalancing / 100 
										AND ABS(t2.a1_prev_allocation * 100 - @a1_allocation) >= @p_min_rebalancing)
										OR ABS(prev_leverage_rate *100 - @p_leverage) >= @p_lev_rebalancing)),
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a1_allocation / 100 / a1_portfolio_price),
									t2.prev_a1_amount),                         										                                   
t1.a2_amount 				= IF(((SELECT close FROM asset_prices WHERE isin = @asset_2 AND date = t1.date) IS NOT NULL
									AND ((ABS(t2.a2_prev_allocation * 100 - @a2_allocation) / @a2_allocation >= @p_rel_rebalancing / 100 
										AND ABS(t2.a2_prev_allocation * 100 - @a2_allocation) >= @p_min_rebalancing)
										OR ABS(prev_leverage_rate *100 - @p_leverage) >= @p_lev_rebalancing)),
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a2_allocation / 100 / a2_portfolio_price),
                                    t2.prev_a2_amount),
t1.a3_amount 				= IF(((SELECT close FROM asset_prices WHERE isin = @asset_3 AND date = t1.date) IS NOT NULL
									AND ((ABS(t2.a3_prev_allocation * 100 - @a3_allocation) / @a3_allocation >= @p_rel_rebalancing / 100 
										AND ABS(t2.a3_prev_allocation * 100 - @a3_allocation) >= @p_min_rebalancing)
										OR ABS(prev_leverage_rate *100 - @p_leverage) >= @p_lev_rebalancing)),
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a3_allocation / 100 / a3_portfolio_price),
                                    t2.prev_a3_amount),
t1.a4_amount 				= IF(((SELECT close FROM asset_prices WHERE isin = @asset_4 AND date = t1.date) IS NOT NULL
									AND ((ABS(t2.a4_prev_allocation * 100 - @a4_allocation) / @a4_allocation >= @p_rel_rebalancing / 100 
										AND ABS(t2.a4_prev_allocation * 100 - @a4_allocation) >= @p_min_rebalancing)
										OR ABS(prev_leverage_rate *100 - @p_leverage) >= @p_lev_rebalancing)),
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a4_allocation / 100 / a4_portfolio_price),
                                    t2.prev_a4_amount),
a1_amount_change       		= a1_amount - prev_a1_amount,                             
a2_amount_change			= a2_amount - prev_a2_amount, 
a3_amount_change			= a3_amount - prev_a3_amount, 
a4_amount_change			= a4_amount - prev_a4_amount,                                    
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
transaction_costs 			= 	-(IF(a1_amount_change != 0, 1, 0)
								+ IF(a2_amount_change != 0, 1, 0)
								+ IF(a3_amount_change != 0, 1, 0)
								+ IF(a4_amount_change != 0, 1, 0)) * @p_transaction_cost,
-- THE INTEREST IS BEING CALCULATED ON A DAILY BASIS instead of a monthly one for ease of programing. The rate is set as the RFR + 1%, which is a realistic rate for a serious brokerage firm. 
interest					= 	IF(prev_acc_balance < 0, prev_acc_balance * (SELECT last_rate + @p_interest_augment 
																				FROM econ_indicators_values 
																				WHERE symbol = 'EUR-RFR' 
                                                                                AND date = t1.date)
                                                                                /100/365, 
                                                                                0),
t1.tot_change				=	t1.buy + t1.sell + t1.deposit + t1.withdrawl + t1.transaction_costs + t1.interest,
t1.acc_balance				=	CASE
								WHEN t1.date = @first_date THEN tot_change
								ELSE t2.prev_acc_balance + tot_change
								END,
t1.tot_balance				=	acc_balance + p_value,
leverage_rate				=	p_value / tot_balance -1,
a1_allocation 				= 	(a1_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a2_allocation 				= 	(a2_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a3_allocation 				= 	(a3_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a4_allocation 				= 	(a4_portfolio_value / (tot_balance*((@p_leverage+100)/100)))

WHERE t1.date = loop_date;
        
        SET inner_counter = inner_counter + 1;
        SET loop_date = DATE_ADD(loop_date, INTERVAL 1 DAY);
        
END WHILE;

INSERT INTO sim_temp
	SELECT* 
	FROM sim_looper
    WHERE date != @max_date;

DELETE
FROM sim_looper;

SET inner_counter = 1;
SET outer_counter = outer_counter + 1;

END WHILE;

DROP TABLE sim_looper;
DELETE FROM sim_temp
WHERE a1_amount IS NULL;

END //
;


DELIMETER //
CREATE PROCEDURE sim_final_data_population() -- Filling the table with the remaining data based on the simulation data
BEGIN

UPDATE sim_temp sl
SET
a1_local_value 		= a1_price * a1_amount,
a2_local_value 		= a2_price * a2_amount,
a3_local_value 		= a3_price * a3_amount,
a4_local_value 		= a4_price * a4_amount,

usd_exposure_usd	= IF(@a1_currency = 'USD', a1_local_value, 0)
					+ IF(@a2_currency = 'USD', a2_local_value, 0)
                    + IF(@a3_currency = 'USD', a3_local_value, 0)
                    + IF(@a4_currency = 'USD', a4_local_value, 0),

usd_exposure_eur	= usd_exposure_usd / (SELECT last_close FROM forex_prices WHERE forex_pair = 'EURUSD' AND date = sl.date),

eur_exposure		= IF(@a1_currency = 'EUR', a1_local_value, 0)
					+ IF(@a2_currency = 'EUR', a2_local_value, 0)
                    + IF(@a3_currency = 'EUR', a3_local_value, 0)
                    + IF(@a4_currency = 'EUR', a4_local_value, 0);

CREATE TABLE p_simulation LIKE sim_temp;     

INSERT INTO p_simulation
SELECT * FROM sim_temp;             

UPDATE p_simulation t1 
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
LAG(a4_portfolio_price,365) OVER (ORDER BY date) AS a4_prev_portfolio_price_365d,

tot_balance,
LAG(tot_balance,1) OVER (ORDER BY date) AS prev_tot_balance_1d, -- a4-normal lag 1 day 
LAG(tot_balance,7) OVER (ORDER BY date) AS prev_tot_balance_7d,
LAG(tot_balance,30) OVER (ORDER BY date) AS prev_tot_balance_30d,
LAG(tot_balance,90) OVER (ORDER BY date) AS prev_tot_balance_90d,
LAG(tot_balance,365) OVER (ORDER BY date) AS prev_tot_balance_365d
FROM p_simulation) t2
ON t1.date = t2.date
SET 
t1.a1_local_change_d 	= ((t1.a1_price - t2.a1_prev_price_1d) / t2.a1_prev_price_1d) * 100,
t1.a1_local_change_w 	= ((t1.a1_price - t2.a1_prev_price_7d) / t2.a1_prev_price_7d) * 100,
t1.a1_local_change_m 	= ((t1.a1_price - t2.a1_prev_price_30d) / t2.a1_prev_price_30d) * 100,
t1.a1_local_change_q 	= ((t1.a1_price - t2.a1_prev_price_90d) / t2.a1_prev_price_90d) * 100,
t1.a1_local_change_y 	= ((t1.a1_price - t2.a1_prev_price_365d) / t2.a1_prev_price_365d) * 100,
a1_portfolio_change_d 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_1d) / t2.a1_prev_portfolio_price_1d) * 100,
a1_portfolio_change_w 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_7d) / t2.a1_prev_portfolio_price_7d) * 100,
a1_portfolio_change_m 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_30d) / t2.a1_prev_portfolio_price_30d) * 100,
a1_portfolio_change_q 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_90d) / t2.a1_prev_portfolio_price_90d) * 100,
a1_portfolio_change_y 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_365d) / t2.a1_prev_portfolio_price_365d) * 100,

t1.a2_local_change_d 	= ((t1.a2_price - t2.a2_prev_price_1d) / t2.a2_prev_price_1d) * 100,
t1.a2_local_change_w 	= ((t1.a2_price - t2.a2_prev_price_7d) / t2.a2_prev_price_7d) * 100,
t1.a2_local_change_m 	= ((t1.a2_price - t2.a2_prev_price_30d) / t2.a2_prev_price_30d) * 100,
t1.a2_local_change_q 	= ((t1.a2_price - t2.a2_prev_price_90d) / t2.a2_prev_price_90d) * 100,
t1.a2_local_change_y 	= ((t1.a2_price - t2.a2_prev_price_365d) / t2.a2_prev_price_365d) * 100,
a2_portfolio_change_d 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_1d) / t2.a2_prev_portfolio_price_1d) * 100,
a2_portfolio_change_w 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_7d) / t2.a2_prev_portfolio_price_7d) * 100,
a2_portfolio_change_m 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_30d) / t2.a2_prev_portfolio_price_30d) * 100,
a2_portfolio_change_q 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_90d) / t2.a2_prev_portfolio_price_90d) * 100,
a2_portfolio_change_y 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_365d) / t2.a2_prev_portfolio_price_365d) * 100,

t1.a3_local_change_d 	= ((t1.a3_price - t2.a3_prev_price_1d) / t2.a3_prev_price_1d) * 100,
t1.a3_local_change_w 	= ((t1.a3_price - t2.a3_prev_price_7d) / t2.a3_prev_price_7d) * 100,
t1.a3_local_change_m 	= ((t1.a3_price - t2.a3_prev_price_30d) / t2.a3_prev_price_30d) * 100,
t1.a3_local_change_q 	= ((t1.a3_price - t2.a3_prev_price_90d) / t2.a3_prev_price_90d) * 100,
t1.a3_local_change_y 	= ((t1.a3_price - t2.a3_prev_price_365d) / t2.a3_prev_price_365d) * 100,
a3_portfolio_change_d 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_1d) / t2.a3_prev_portfolio_price_1d) * 100,
a3_portfolio_change_w 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_7d) / t2.a3_prev_portfolio_price_7d) * 100,
a3_portfolio_change_m 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_30d) / t2.a3_prev_portfolio_price_30d) * 100,
a3_portfolio_change_q 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_90d) / t2.a3_prev_portfolio_price_90d) * 100,
a3_portfolio_change_y 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_365d) / t2.a3_prev_portfolio_price_365d) * 100,

t1.a4_local_change_d 	= ((t1.a4_price - t2.a4_prev_price_1d) / t2.a4_prev_price_1d) * 100,
t1.a4_local_change_w 	= ((t1.a4_price - t2.a4_prev_price_7d) / t2.a4_prev_price_7d) * 100,
t1.a4_local_change_m 	= ((t1.a4_price - t2.a4_prev_price_30d) / t2.a4_prev_price_30d) * 100,
t1.a4_local_change_q 	= ((t1.a4_price - t2.a4_prev_price_90d) / t2.a4_prev_price_90d) * 100,
t1.a4_local_change_y 	= ((t1.a4_price - t2.a4_prev_price_365d) / t2.a4_prev_price_365d) * 100,
a4_portfolio_change_d 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_1d) / t2.a4_prev_portfolio_price_1d) * 100,
a4_portfolio_change_w 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_7d) / t2.a4_prev_portfolio_price_7d) * 100,
a4_portfolio_change_m 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_30d) / t2.a4_prev_portfolio_price_30d) * 100,
a4_portfolio_change_q 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_90d) / t2.a4_prev_portfolio_price_90d) * 100,
a4_portfolio_change_y 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_365d) / t2.a4_prev_portfolio_price_365d) * 100,

t1.tot_balance_change_d 	= ((t1.tot_balance - t2.prev_tot_balance_1d) / t2.prev_tot_balance_1d) * 100,
t1.tot_balance_change_w 	= ((t1.tot_balance - t2.prev_tot_balance_7d) / t2.prev_tot_balance_7d) * 100,
t1.tot_balance_change_m 	= ((t1.tot_balance - t2.prev_tot_balance_30d) / t2.prev_tot_balance_30d) * 100,
t1.tot_balance_change_q 	= ((t1.tot_balance - t2.prev_tot_balance_90d) / t2.prev_tot_balance_90d) * 100,
t1.tot_balance_change_y 	= ((t1.tot_balance - t2.prev_tot_balance_365d) / t2.prev_tot_balance_365d) * 100;


SELECT* 
FROM p_simulation;

END //
;


DELIMETER //
CREATE PROCEDURE sim_save()
BEGIN

DELETE
FROM sim_data
WHERE p_name = @p_name;

INSERT INTO sim_data (date, p_name, a1_isin, a1_price, a1_forex_pair, a1_fx_rate, a1_portfolio_price, a1_amount, a1_medium_price, a1_local_value, a1_portfolio_value, a1_local_change_d, a1_local_change_w, a1_local_change_m, a1_local_change_q, a1_local_change_y, a1_portfolio_change_d, a1_portfolio_change_w, a1_portfolio_change_m, a1_portfolio_change_q, a1_portfolio_change_y, a2_isin, a2_price, a2_forex_pair, a2_fx_rate, a2_portfolio_price, a2_amount, a2_medium_price, a2_local_value, a2_portfolio_value, a2_local_change_d, a2_local_change_w, a2_local_change_m, a2_local_change_q, a2_local_change_y, a2_portfolio_change_d, a2_portfolio_change_w, a2_portfolio_change_m, a2_portfolio_change_q, a2_portfolio_change_y, a3_isin, a3_price, a3_forex_pair, a3_fx_rate, a3_portfolio_price, a3_amount, a3_medium_price, a3_local_value, a3_portfolio_value, a3_local_change_d, a3_local_change_w, a3_local_change_m, a3_local_change_q, a3_local_change_y, a3_portfolio_change_d, a3_portfolio_change_w, a3_portfolio_change_m, a3_portfolio_change_q, a3_portfolio_change_y, a4_isin, a4_price, a4_forex_pair, a4_fx_rate, a4_portfolio_price, a4_amount, a4_medium_price, a4_local_value, a4_portfolio_value, a4_local_change_d, a4_local_change_w, a4_local_change_m, a4_local_change_q, a4_local_change_y, a4_portfolio_change_d, a4_portfolio_change_w, a4_portfolio_change_m, a4_portfolio_change_q, a4_portfolio_change_y, p_value, a1_allocation, a2_allocation, a3_allocation, a4_allocation, usd_exposure_usd, usd_exposure_eur, eur_exposure, buy, sell, deposit, withdrawl, tot_change, acc_balance, tot_balance, leverage_rate, tot_balance_change_d, tot_balance_change_w, tot_balance_change_m, tot_balance_change_q, tot_balance_change_y)
SELECT* FROM sim_looper;


END //
;


DELIMETER //
CREATE PROCEDURE run_simulation()
BEGIN 

CALL user_update();
CALL sim_prepare();
CALL sim_table_creation();
CALL sim_relative_looper();
CALL sim_final_data_population();

END //
;





/*

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

/*

DELIMITER //
CREATE PROCEDURE sim_periodic_trigger(period VARCHAR(50))
BEGIN

DECLARE counter INT DEFAULT 2; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date DATE DEFAULT ADDDATE(@first_date, 1);

ALTER TABLE sim_looper
ADD COLUMN reb_trigger_a1 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a2 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a3 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a4 TINYINT DEFAULT 0; 

WHILE counter <= (SELECT datediff(@last_date, @first_date)+1) DO

UPDATE sim_looper t1
JOIN (
SELECT 
date, 
LAG(date) OVER (ORDER BY date) prev_date,
LAG(reb_trigger_a1) OVER (ORDER BY date) prev_reb_trigger_a1,
LAG(reb_trigger_a2) OVER (ORDER BY date) prev_reb_trigger_a2,
LAG(reb_trigger_a3) OVER (ORDER BY date) prev_reb_trigger_a3,
LAG(reb_trigger_a4) OVER (ORDER BY date) prev_reb_trigger_a4
FROM sim_looper
) t2
ON t1.date = t2.date
SET 
reb_trigger_a1				= CASE 
								WHEN prev_reb_trigger_a1 = 0										
									AND ((period = 'weekly' AND WEEKOFYEAR(t1.date) = WEEKOFYEAR(prev_date)) OR
										(period = 'monthly' AND MONTH(t1.date) = MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
										(period = 'quarterly' AND QUARTER(t1.date) = QUARTER(prev_date)) OR
										(period = 'semi-annually' AND QUARTER(t1.date) = QUARTER(prev_date)) OR 													-- AND MONTH(t1.date) IN (6, 12)) OR
										(period = 'annually' AND YEAR(t1.date) = YEAR(prev_date)))								
                                THEN 0
								WHEN prev_reb_trigger_a1 = 0
									AND ((period = 'weekly' AND WEEKOFYEAR(t1.date) != WEEKOFYEAR(prev_date)) OR
										(period = 'monthly' AND MONTH(t1.date) != MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
										(period = 'quarterly' AND QUARTER(t1.date) != QUARTER(prev_date)) OR
										(period = 'semi-annually' AND QUARTER(t1.date) != QUARTER(prev_date) 
										AND MONTH(t1.date) IN (1, 7)) OR
										(period = 'annually' AND YEAR(t1.date) != YEAR(prev_date)))								
								THEN 1
								WHEN prev_reb_trigger_a1 = 1 
									AND (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND date = prev_date) IS NULL 	
                                THEN 5
                                ELSE 0
							END,
reb_trigger_a2				= CASE 
								WHEN prev_reb_trigger_a2 = 0										
									AND ((period = 'weekly' AND WEEKOFYEAR(t1.date) = WEEKOFYEAR(prev_date)) OR
										(period = 'monthly' AND MONTH(t1.date) = MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
										(period = 'quarterly' AND QUARTER(t1.date) = QUARTER(prev_date)) OR
										(period = 'semi-annually' AND QUARTER(t1.date) = QUARTER(prev_date)) OR 													-- AND MONTH(t1.date) IN (6, 12)) OR
										(period = 'annually' AND YEAR(t1.date) = YEAR(prev_date)))								
                                THEN 0
								WHEN ((period = 'weekly' AND WEEKOFYEAR(t1.date) != WEEKOFYEAR(prev_date)) OR
									(period = 'monthly' AND MONTH(t1.date) != MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
									(period = 'quarterly' AND QUARTER(t1.date) != QUARTER(prev_date)) OR
									(period = 'semi-annually' AND QUARTER(t1.date) != QUARTER(prev_date) 
									AND MONTH(t1.date) IN (1, 7)) OR
									(period = 'annually' AND YEAR(t1.date) != YEAR(prev_date)))								
								THEN 1
								WHEN prev_reb_trigger_a2 = 1 
									AND (SELECT close FROM asset_prices WHERE isin = @asset_2 AND date = prev_date) IS NULL 	
                                THEN 6
                                ELSE 0
							END,
reb_trigger_a3				= CASE 
								WHEN prev_reb_trigger_a3 = 0										
									AND ((period = 'weekly' AND WEEKOFYEAR(t1.date) = WEEKOFYEAR(prev_date)) OR
										(period = 'monthly' AND MONTH(t1.date) = MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
										(period = 'quarterly' AND QUARTER(t1.date) = QUARTER(prev_date)) OR
										(period = 'semi-annually' AND QUARTER(t1.date) = QUARTER(prev_date)) OR 													-- AND MONTH(t1.date) IN (6, 12)) OR
										(period = 'annually' AND YEAR(t1.date) = YEAR(prev_date)))								
                                THEN 0
								WHEN ((period = 'weekly' AND WEEKOFYEAR(t1.date) != WEEKOFYEAR(prev_date)) OR
									(period = 'monthly' AND MONTH(t1.date) != MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
									(period = 'quarterly' AND QUARTER(t1.date) != QUARTER(prev_date)) OR
									(period = 'semi-annually' AND QUARTER(t1.date) != QUARTER(prev_date) 
									AND MONTH(t1.date) IN (1, 7)) OR
									(period = 'annually' AND YEAR(t1.date) != YEAR(prev_date)))								
								THEN 1
								WHEN prev_reb_trigger_a3 = 1 
									AND (SELECT close FROM asset_prices WHERE isin = @asset_3 AND date = prev_date) IS NULL 	
                                THEN 7
                                ELSE 0
							END,                               
reb_trigger_a4				= CASE 
								WHEN prev_reb_trigger_a4 = 0										
									AND ((period = 'weekly' AND WEEKOFYEAR(t1.date) = WEEKOFYEAR(prev_date)) OR
										(period = 'monthly' AND MONTH(t1.date) = MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
										(period = 'quarterly' AND QUARTER(t1.date) = QUARTER(prev_date)) OR
										(period = 'semi-annually' AND QUARTER(t1.date) = QUARTER(prev_date)) OR 													-- AND MONTH(t1.date) IN (6, 12)) OR
										(period = 'annually' AND YEAR(t1.date) = YEAR(prev_date)))								
                                THEN 0
								WHEN ((period = 'weekly' AND WEEKOFYEAR(t1.date) != WEEKOFYEAR(prev_date)) OR
									(period = 'monthly' AND MONTH(t1.date) != MONTH(prev_date)) OR  																-- The rest of the period changes will always come with a change of month
									(period = 'quarterly' AND QUARTER(t1.date) != QUARTER(prev_date)) OR
									(period = 'semi-annually' AND QUARTER(t1.date) != QUARTER(prev_date) 
									AND MONTH(t1.date) IN (1, 7)) OR
									(period = 'annually' AND YEAR(t1.date) != YEAR(prev_date)))								
								THEN 1
								WHEN prev_reb_trigger_a4 = 1 
									AND (SELECT close FROM asset_prices WHERE isin = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 8
                                ELSE 0
							END

WHERE t1.date = loop_date;
        
        SET counter = counter + 1;
        SET loop_date = DATE_ADD(loop_date, INTERVAL 1 DAY);
        
	END WHILE;
	
END //



DELIMITER //
CREATE PROCEDURE sim_periodic_step2() -- Creating the portfolio simulation day by day
BEGIN

DECLARE counter INT DEFAULT 2; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date DATE DEFAULT ADDDATE(@first_date, 1);


WHILE counter <= (SELECT datediff(@last_date, @first_date)+1) DO

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
LAG(leverage_rate) OVER (ORDER BY date) prev_leverage_rate,
LAG(a1_allocation) OVER (ORDER BY date) a1_prev_allocation,
LAG(a2_allocation) OVER (ORDER BY date) a2_prev_allocation,
LAG(a3_allocation) OVER (ORDER BY date) a3_prev_allocation,
LAG(a4_allocation) OVER (ORDER BY date) a4_prev_allocation
FROM sim_looper
) t2
ON t1.date = t2.date
SET 
t1.a1_amount 				= IF((SELECT close FROM asset_prices WHERE isin = @asset_1 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a1 = 1,                               
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a1_allocation / 100 / a1_portfolio_price),
									t2.prev_a1_amount),                         										                                   
t1.a2_amount 				= IF((SELECT close FROM asset_prices WHERE isin = @asset_2 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a2 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a2_allocation / 100 / a2_portfolio_price),
                                    t2.prev_a2_amount),
t1.a3_amount 				= IF((SELECT close FROM asset_prices WHERE isin = @asset_3 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a3 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a3_allocation / 100 / a3_portfolio_price),
                                    t2.prev_a3_amount),
t1.a4_amount 				= IF((SELECT close FROM asset_prices WHERE isin = @asset_4 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a4 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@p_leverage / 100 + 1, 1) * @a4_allocation / 100 / a4_portfolio_price),
                                    t2.prev_a4_amount),
a1_amount_change       		= a1_amount - prev_a1_amount,                             
a2_amount_change			= a2_amount - prev_a2_amount, 
a3_amount_change			= a3_amount - prev_a3_amount, 
a4_amount_change			= a4_amount - prev_a4_amount,                                    
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
transaction_costs 			= 	-(IF(a1_amount_change != 0, 1, 0)
								+ IF(a2_amount_change != 0, 1, 0)
								+ IF(a3_amount_change != 0, 1, 0)
								+ IF(a4_amount_change != 0, 1, 0)) * @p_transaction_cost,
-- THE INTEREST IS BEING CALCULATED ON A DAILY BASIS instead of a monthly one for ease of programing. The rate is set as the RFR + 1%, which is a realistic rate for a serious brokerage firm. 
interest					= 	IF(prev_acc_balance < 0, prev_acc_balance * (SELECT last_rate + @p_interest_augment 
																				FROM econ_indicators_values 
																				WHERE symbol = 'EUR-RFR' 
                                                                                AND date = t1.date)
                                                                                /100/365, 
                                                                                0),




t1.tot_change				=	t1.buy + t1.sell + t1.deposit + t1.withdrawl + t1.transaction_costs + t1.interest,
t1.acc_balance				=	CASE
								WHEN t1.date = @first_date THEN tot_change
								ELSE t2.prev_acc_balance + tot_change
								END,
t1.tot_balance				=	acc_balance + p_value,
leverage_rate				=	p_value / tot_balance -1,
a1_allocation 				= 	(a1_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a2_allocation 				= 	(a2_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a3_allocation 				= 	(a3_portfolio_value / (tot_balance*((@p_leverage+100)/100))),
a4_allocation 				= 	(a4_portfolio_value / (tot_balance*((@p_leverage+100)/100)))

WHERE t1.date = loop_date;
        
        SET counter = counter + 1;
        SET loop_date = DATE_ADD(loop_date, INTERVAL 1 DAY);
        
	END WHILE;

END //
;
*/