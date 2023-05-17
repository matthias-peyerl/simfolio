-- I WILL SET UP A TABLE FOR ALL PORTFOLIO METRICS IN ONE PLACE - MUCH EASIER TO CONSTRUCT AND TO REFER TO LATER

DROP TABLE p_hist;

SELECT*
FROM p_hist;

CREATE TABLE p_hist (
	date DATE PRIMARY KEY,
   	a1_isin VARCHAR(20),
    a1_price FLOAT,
    a1_forex_pair VARCHAR(10),
    a1_fx_rate FLOAT,    
    a1_portfolio_price FLOAT,
    
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
    
    a1_amount INT,
    a1_medium_price FLOAT,
    a1_local_value FLOAT,
    a1_portfolio_value FLOAT,
    
    
    a2_isin VARCHAR(20),
    a2_price FLOAT,
    a2_forex_pair VARCHAR(20),
    a2_fx_rate FLOAT,    
    a2_portfolio_price FLOAT,
    
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
    
    a2_amount INT,
    a2_medium_price FLOAT,
    a2_local_value FLOAT,
    a2_portfolio_value FLOAT,

    
    a3_isin VARCHAR(30),
    a3_price FLOAT,
    a3_forex_pair VARCHAR(30),
    a3_fx_rate FLOAT,    
    a3_portfolio_price FLOAT,
    
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
    
    a3_amount INT,
    a3_medium_price FLOAT,
    a3_local_value FLOAT,
    a3_portfolio_value FLOAT,


	a4_isin VARCHAR(40),
    a4_price FLOAT,
    a4_forex_pair VARCHAR(40),
    a4_fx_rate FLOAT,    
    a4_portfolio_price FLOAT,
    
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
    
    a4_amount INT,
    a4_medium_price FLOAT,
    a4_local_value FLOAT,
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
    p_value FLOAT,
    
    a1_allocation FLOAT,
    a2_allocation FLOAT,
    a3_allocation FLOAT,
    a4_allocation FLOAT,
    /*
    a5_allocation FLOAT,
    a6_allocation FLOAT,
    a7_allocation FLOAT,
    a8_allocation FLOAT,
    a9_allocation FLOAT,
    a10_allocation FLOAT,
    */
    -- ACOUNT METRICS
    
    usd_exposure_usd FLOAT,
    usd_exposure_eur FLOAT,
    eur_exposure FLOAT,
    
    buy FLOAT DEFAULT 0,
	sell FLOAT DEFAULT 0,
	transaction_cost FLOAT DEFAULT 0,
	x_connection FLOAT DEFAULT 0,
	interest FLOAT DEFAULT 0,
	deposit FLOAT DEFAULT 0,
	withdrawl FLOAT DEFAULT 0,
	tot_change FLOAT DEFAULT 0,
	acc_balance FLOAT DEFAULT 0,
    tot_balance FLOAT DEFAULT 0,
    leverage_rate FLOAT
);

	INSERT INTO p_hist (date)
	SELECT date 
	FROM calendar
	-- WHERE is_Weekday = 1
    WHERE date BETWEEN '2022-01-01' AND @last_date
	ORDER BY date desc;

SELECT*
FROM p_hist;
WHERE leverage_rate IS NULL;

UPDATE p_hist ph
SET 
a1_isin 			= 	@asset_1,	
a1_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date),
a1_forex_pair		=	IF(@a1_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a1_currency), CONCAT(@a1_currency, @p_currency)))),
a1_fx_rate			= 	IF( @a1_currency = @p_currency, 1, (SELECT last_close
																FROM forex_prices
																WHERE forex_pair = ph.a1_forex_pair
																AND date = ph.date)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @p_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END, 
a1_amount 			= 	COALESCE((SELECT sum(amount)
						FROM inv_transactions inv
						WHERE isin = @asset_1
						AND inv.date BETWEEN @first_date AND ph.date),0),
a1_medium_price		= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_1) > 0, 
						(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_1), 0),
a1_local_value		= 	a1_amount * a1_price,
a1_portfolio_value 	= 	a1_amount * a1_portfolio_price,

a2_isin 			= 	@asset_2,	
a2_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date),
a2_forex_pair		=	IF(@a2_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a2_currency), CONCAT(@a2_currency, @p_currency)))),
a2_fx_rate			= 	IF( @a2_currency = @p_currency, 1, (SELECT last_close
																FROM forex_prices
																WHERE forex_pair = ph.a2_forex_pair
																AND date = ph.date)),
a2_portfolio_price	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @p_currency) THEN a2_price * a2_fx_rate
                            ELSE a2_price / a2_fx_rate
						END, 
a2_amount 			= 	COALESCE((SELECT sum(amount)
						FROM inv_transactions inv
						WHERE isin = @asset_2
						AND inv.date BETWEEN @first_date AND ph.date),0),
a2_medium_price		= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_2) > 0, 
						(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_2), 0),
a2_local_value		= 	a2_amount * a2_price,
a2_portfolio_value 	= 	a2_amount * a2_portfolio_price,

a3_isin 			= 	@asset_3,	
a3_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date),
a3_forex_pair		=	IF(@a3_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a3_currency), CONCAT(@a3_currency, @p_currency)))),
a3_fx_rate			= 	IF( @a3_currency = @p_currency, 1, (SELECT last_close
																FROM forex_prices
																WHERE forex_pair = ph.a3_forex_pair
																AND date = ph.date)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @p_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END, 
a3_amount 			= 	COALESCE((SELECT sum(amount)
						FROM inv_transactions inv
						WHERE isin = @asset_3
						AND inv.date BETWEEN @first_date AND ph.date),0),
a3_medium_price		= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_3) > 0, 
						(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_3), 0),
a3_local_value		= 	a3_amount * a3_price,
a3_portfolio_value 	= 	a3_amount * a3_portfolio_price,

a4_isin 			= 	@asset_4,	
a4_price			= 	(SELECT last_close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date),
a4_forex_pair		=	IF(@a4_currency = @p_currency, @p_currency, (SELECT forex_pair 
																	FROM forex_pair
																	WHERE forex_pair IN (CONCAT(@p_currency, @a4_currency), CONCAT(@a4_currency, @p_currency)))),
a4_fx_rate			= 	IF( @a4_currency = @p_currency, 1, (SELECT last_close
																FROM forex_prices
																WHERE forex_pair = ph.a4_forex_pair
																AND date = ph.date)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @p_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END, 
a4_amount 			= 	COALESCE((SELECT sum(amount)
						FROM inv_transactions inv
						WHERE isin = @asset_4
						AND inv.date BETWEEN @first_date AND ph.date),0),
a4_medium_price		= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_4) > 0, 
						(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_4), 0),
a4_local_value		= 	a4_amount * a4_price,
a4_portfolio_value 	= 	a4_amount * a4_portfolio_price,

a1_allocation 		= ROUND(a1_portfolio_value / p_value,4) * 100,
a2_allocation 		= ROUND(a2_portfolio_value / p_value,4)	* 100,
a3_allocation 		= ROUND(a3_portfolio_value / p_value,4) * 100,
a4_allocation 		= ROUND(a4_portfolio_value / p_value,4) * 100,

    /*
a5_allocation FLOAT,
a6_allocation FLOAT,
a7_allocation FLOAT,
a8_allocation FLOAT,
a9_allocation FLOAT,
a10_allocation FLOAT,
    */

usd_exposure_usd	= IF(@a1_currency = 'USD', a1_local_value, 0)
					+ IF(@a2_currency = 'USD', a2_local_value, 0)
                    + IF(@a3_currency = 'USD', a3_local_value, 0)
                    + IF(@a4_currency = 'USD', a4_local_value, 0), /*
                    + IF(@a1_currency = 'USD', a5_local_value, 0)
                    + IF(@a1_currency = 'USD', a6_local_value, 0)
                    + IF(@a1_currency = 'USD', a7_local_value, 0)
                    + IF(@a1_currency = 'USD', a8_local_value, 0)
                    + IF(@a1_currency = 'USD', a8_local_value, 0)
                    + IF(@a1_currency = 'USD', a10_local_value, 0),*/

usd_exposure_eur	= usd_exposure_usd / (SELECT last_close FROM forex_prices WHERE forex_pair = 'EURUSD' AND date = ph.date),

eur_exposure		= IF(@a1_currency = 'EUR', a1_local_value, 0)
					+ IF(@a2_currency = 'EUR', a2_local_value, 0)
                    + IF(@a3_currency = 'EUR', a3_local_value, 0)
                    + IF(@a4_currency = 'EUR', a4_local_value, 0), /*
                    + IF(@a1_currency = 'EUR', a5_local_value, 0)
                    + IF(@a1_currency = 'EUR', a6_local_value, 0)
                    + IF(@a1_currency = 'EUR', a7_local_value, 0)
                    + IF(@a1_currency = 'EUR', a8_local_value, 0)
                    + IF(@a1_currency = 'EUR', a8_local_value, 0)
                    + IF(@a1_currency = 'EUR', a10_local_value, 0), */

buy 				= (SELECT IFNULL((SELECT SUM(local_value) FROM inv_transactions WHERE date = ph.date AND local_value < 0 GROUP BY date),0)),
sell 				= (SELECT IFNULL((SELECT COALESCE(SUM(local_value), 0)  FROM inv_transactions WHERE date = ph.date AND local_value > 0 GROUP BY date),0)),
transaction_cost 	= (SELECT IFNULL((SELECT COALESCE(SUM(transaction_cost), 0)  FROM inv_transactions WHERE date = ph.date GROUP BY date),0)),
x_connection		= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0)  FROM acc_transactions WHERE date = ph.date AND type = 'exchange connection fee' GROUP BY date),0)),
interest			= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ph.date AND type = 'interest' GROUP BY date),0)),
deposit				= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ph.date AND type = 'deposit' GROUP BY date),0)),
withdrawl			= (SELECT IFNULL((SELECT COALESCE(SUM(amount), 0) FROM acc_transactions WHERE date = ph.date AND type = 'withdrawl' GROUP BY date),0)),
tot_change 			= buy + sell + transaction_cost + x_connection + interest + deposit + withdrawl,

-- THIS LINE MAKES REFERENCE TO THE ACC_HIST TABLE!!!
acc_balance 		= (SELECT IFNULL((SELECT SUM(tot_change) FROM (SELECT * FROM acc_hist) AS t WHERE date < ph.date) + tot_change, tot_change)),
tot_balance			= p_value + acc_balance,
leverage_rate		= p_value / tot_balance    
;    


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


/*
UPDATE p_hist t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price) OVER (ORDER BY date) AS prev_price FROM p_hist) t2
ON t1.date = t2.date
SET t1.a1_local_change_d = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_hist t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price) OVER (ORDER BY date) AS prev_price FROM p_hist) t2
ON t1.date = t2.date
SET t1.a1_local_change_d = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_hist t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price) OVER (ORDER BY date) AS prev_price FROM p_hist) t2
ON t1.date = t2.date
SET t1.a1_local_change_d = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_hist t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price) OVER (ORDER BY date) AS prev_price FROM p_hist) t2
ON t1.date = t2.date
SET t1.a1_local_change_d = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;






UPDATE p_hist t1
JOIN (SELECT date, a1_portfolio_price, LAG(a1_portfolio_price) OVER (ORDER BY date) AS prev_price FROM p_hist) t2
ON t1.date = t2.date
SET t1.a1_portfolio_change_d = ((t1.a1_portfolio_price - t2.prev_price) / t2.prev_price) * 100;





*/




