-- SETTING UP USER DEFINED INPUT OPTIONS
SET @p_name = 'PT2';
SET @username = 'SASHA';
SET @inicial_balance = 1000000;

CALL run_simulation();
CALL sim_save();
CALL run_and_save();

DROP PROCEDURE sim_save;

DROP PROCEDURE sim_step1;

CALL user_update();
CALL sim_prepare();
CALL sim_step1();
CALL sim_step2();
sim_step3
sim_save
;

SELECT*
FROM sim_temp;

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
    
    -- ACOUNT METRICS
    
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

-- STEP 1 -> INTRODUCING CALENDER DATES

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
SELECT allocation FROM portfolio_assets WHERE isin = @asset_1 AN;-- )/100/a1_portfolio_price;

UPDATE sim_temp
SET 
a1_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_1 AND portfolio_name = @p_name)/100/a1_portfolio_price),
a2_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_2 AND portfolio_name = @p_name)/100/a2_portfolio_price),
a3_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_3 AND portfolio_name = @p_name)/100/a3_portfolio_price),
a4_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_4 AND portfolio_name = @p_name)/100/a4_portfolio_price),
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
