-- SETTIG AN INICIAL BALANCE FOR THE SIMULATION

SET @acc = 1;
SET @inicial_balance = (SELECT inicial_balance FROM sim_accounts WHERE acc_id =1); -- NOT NECESSARY ANY MORE
SET @p_name = 'PT1';

-- CREATING A TABLE FOR SIMULATION ACCOUNTS
DROP TABLE p_sim2;

CREATE TABLE p_sim2(
	num INT,
    date DATE PRIMARY KEY,
   	a1_isin VARCHAR(20),
    a1_price FLOAT,
    a1_forex_pair VARCHAR(10),
    a1_fx_rate FLOAT,    
    a1_portfolio_price FLOAT,
    
    a1_amount INT,
    a1_medium_price FLOAT,
    a1_local_value FLOAT,
    a1_portfolio_value FLOAT,
        
    a2_isin VARCHAR(20),
    a2_price FLOAT,
    a2_forex_pair VARCHAR(20),
    a2_fx_rate FLOAT,    
    a2_portfolio_price FLOAT,
    
    a2_amount INT,
    a2_medium_price FLOAT,
    a2_local_value FLOAT,
    a2_portfolio_value FLOAT,

    a3_isin VARCHAR(30),
    a3_price FLOAT,
    a3_forex_pair VARCHAR(30),
    a3_fx_rate FLOAT,    
    a3_portfolio_price FLOAT,
        
    a3_amount INT,
    a3_medium_price FLOAT,
    a3_local_value FLOAT,
    a3_portfolio_value FLOAT,

	a4_isin VARCHAR(40),
    a4_price FLOAT,
    a4_forex_pair VARCHAR(40),
    a4_fx_rate FLOAT,    
    a4_portfolio_price FLOAT,
    
    a4_amount INT,
    a4_medium_price FLOAT,
    a4_local_value FLOAT,
    a4_portfolio_value FLOAT,
  
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

INSERT INTO p_sim2 (date)
	SELECT date 
	FROM calendar
	-- WHERE is_Weekday = 1
    WHERE date BETWEEN @first_date AND @last_date
	ORDER BY date desc;

-- STEP 2 -> INTRODUCING KNOWN VALUES

UPDATE p_sim2 ph
SET 
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

-- STEP 3:	-> INTRODUCING INICIAL LINE (TO PREVENT EXTRA MENTIONS IN EVERY LINE OF THE CODE LATER

UPDATE p_sim2
SET 
a1_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_1)/100/a1_portfolio_price),
a2_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_2)/100/a2_portfolio_price),
a3_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_3)/100/a3_portfolio_price),
a4_amount 				= FLOOR(@inicial_balance * (SELECT allocation FROM portfolio_assets WHERE isin = @asset_4)/100/a4_portfolio_price),
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


-- STEP 4:	-> CREATING A LOOP TO CALCULATE RESPECTIVE ROWS

SELECT*
FROM p_sim2;

-- PREPARING THE COUNTER: The day in the portfolio range minus the first day, where the data is already introduced.

-- SET @loop_counter 	= (SELECT datediff(@last_date, @first_date)-1);

-- TRYING TO CREATE A REPEAT LOOP

CALL sim_loop();

SELECT*
FROM p_sim2;

SELECT datediff(@last_date, @first_date);

DROP PROCEDURE sim_loop;

DELIMITER //
CREATE PROCEDURE sim_loop ()

BEGIN

DECLARE counter INT DEFAULT 2; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date DATE DEFAULT ADDDATE(@first_date, 1);

WHILE counter <= (SELECT datediff(@last_date, @first_date)) DO
		
UPDATE p_sim2 t1
JOIN (
SELECT 
date, 
LAG(a1_amount) OVER (ORDER BY date) prev_a1_amount,
LAG(a2_amount) OVER (ORDER BY date) prev_a2_amount,
LAG(a3_amount) OVER (ORDER BY date) prev_a3_amount,
LAG(a4_amount) OVER (ORDER BY date) prev_a4_amount,
LAG(acc_balance) OVER (ORDER BY date) prev_acc_balance,
LAG(tot_balance) OVER (ORDER BY date) prev_tot_balance
FROM p_sim2
) t2
ON t1.date = t2.date
SET 
t1.a1_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_1)/100/a1_portfolio_price),
t1.a2_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_2)/100/a2_portfolio_price),
t1.a3_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_3)/100/a3_portfolio_price),
t1.a4_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_4)/100/a4_portfolio_price),
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

DELIMETER;















DELIMITER //
CREATE PROCEDURE p_sim_loop (IN p_name VARCHAR(255), IN asset_1 VARCHAR(255), IN asset_2 VARCHAR(255), IN asset_3 VARCHAR(255), IN asset_4 VARCHAR(255), IN @first_date DATE, IN end_date DATE)
BEGIN
	DECLARE loop_position DATE;
	DECLARE a1_portfolio_price FLOAT;
	DECLARE a2_portfolio_price FLOAT;
	DECLARE a3_portfolio_price FLOAT;
	DECLARE a4_portfolio_price FLOAT;

	SET loop_position = start_date;

	WHILE loop_position <= end_date DO
		SET a1_portfolio_price = (SELECT price FROM asset_prices WHERE isin = asset_1 AND date = loop_position);
		SET a2_portfolio_price = (SELECT price FROM asset_prices WHERE isin = asset_2 AND date = loop_position);
		SET a3_portfolio_price = (SELECT price FROM asset_prices WHERE isin = asset_3 AND date = loop_position);
		SET a4_portfolio_price = (SELECT price FROM asset_prices WHERE isin = asset_4 AND date = loop_position);

		-- Your calculations and updates go here

		SET loop_position = DATE_ADD(loop_position, INTERVAL 1 DAY);
	END WHILE;
END //
DELIMITER ;
DECLARE loop_position DATE;
SET 	loop_position 	= (SELECT DATE_ADD(@first_date, INTERVAL 1 DAY));

	
WHILE @loop_position <= @last_date DO

SET @a1_amount := (SELECT a1_amount FROM p_sim2 WHERE date = @loop_position);
SET @a2_amount := (SELECT a2_amount FROM p_sim2 WHERE date = @loop_position);
SET @a3_amount := (SELECT a3_amount FROM p_sim2 WHERE date = @loop_position);
SET @a4_amount := (SELECT a4_amount FROM p_sim2 WHERE date = @loop_position);
SET @a1_portfolio_price := (SELECT a1_portfolio_price FROM p_sim2 WHERE date = @loop_position);
SET @a2_portfolio_price := (SELECT a2_portfolio_price FROM p_sim2 WHERE date = @loop_position);
SET @a3_portfolio_price := (SELECT a3_portfolio_price FROM p_sim2 WHERE date = @loop_position);
SET @a4_portfolio_price := (SELECT a4_portfolio_price FROM p_sim2 WHERE date = @loop_position);


UPDATE p_sim2 t1
JOIN (
SELECT 
date, 
LAG(a1_amount) OVER (ORDER BY date) prev_a1_amount,
LAG(a2_amount) OVER (ORDER BY date) prev_a2_amount,
LAG(a3_amount) OVER (ORDER BY date) prev_a3_amount,
LAG(a4_amount) OVER (ORDER BY date) prev_a4_amount,
LAG(acc_balance) OVER (ORDER BY date) prev_acc_balance,
LAG(tot_balance) OVER (ORDER BY date) prev_tot_balance
FROM p_sim2
) t2
ON t1.date = t2.date
SET 
t1.a1_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_1)/100/a1_portfolio_price),
t1.a2_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_2)/100/a2_portfolio_price),
t1.a3_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_3)/100/a3_portfolio_price),
t1.a4_amount 				= FLOOR(t2.prev_tot_balance * (SELECT allocation FROM portfolio_assets WHERE portfolio_name = @p_name AND isin = @asset_4)/100/a4_portfolio_price),
t1.a1_portfolio_value 		= a1_amount * a1_portfolio_price,
t1.a2_portfolio_value 		= a2_amount * a2_portfolio_price,
t1.a3_portfolio_value 		= a3_amount * a3_portfolio_price,
t1.a4_portfolio_value 		= a4_amount * a4_portfolio_price,
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
WHERE t1.date = loop_position;

SET @loop_position 	= (SELECT DATE_ADD(@loop_position, INTERVAL 1 DAY));

END WHILE;
END


SELECT*
FROM p_sim2;















SELECT*
FROM p_sim2;

SELECT*
FROM portfolio_assets;

update portfolio_assets
SET
allocation = 6.5
WHERE p_asset_id = 12;



































-- UPDATING HISTORICAL PRICES PERFORMANCES ASSET1 

UPDATE p_hist t1 
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

FROM p_hist) t2
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
FROM p_hist;

