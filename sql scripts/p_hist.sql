-- I WILL SET UP A TABLE FOR ALL PORTFOLIO METRICS IN ONE PLACE - MUCH EASIER TO CONSTRUCT AND TO REFER TO LATER

DROP TABLE p_hist;

CREATE TEMPORARY TABLE p_hist (
	date DATE PRIMARY KEY,
   	a1_isin VARCHAR(20),
    a1_amount INT,
    a1_price FLOAT,
    a1_medium_price FLOAT,
    a1_local_value FLOAT,
    a1_forex_pair VARCHAR(10),
    a1_fx_rate FLOAT,
    a1_portfolio_value FLOAT,
	
    a2_isin VARCHAR(20),
    a2_amount INT,
    a2_price FLOAT,
    a2_medium_price FLOAT,
    a2_local_value FLOAT,
	a2_forex_pair VARCHAR(10),
    a2_fx_rate FLOAT,
    a2_portfolio_value FLOAT,
	
    a3_isin VARCHAR(20),
    a3_amount INT,
    a3_price FLOAT,
    a3_medium_price FLOAT,
    a3_local_value FLOAT,
	a3_forex_pair VARCHAR(10),
    a3_fx_rate FLOAT,
    a3_portfolio_value FLOAT,    
	
    a4_isin VARCHAR(20),
    a4_amount INT,
    a4_price FLOAT,
    a4_medium_price FLOAT,
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
    
    usd_exposure FLOAT,
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
	WHERE is_Weekday = 1
    AND date BETWEEN '2022-01-01' AND @last_date
	ORDER BY date desc;

UPDATE p_hist ph
SET 
a1_isin 		= 	@asset_1,		
a1_amount 		= 	COALESCE((SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_1
					AND inv.date BETWEEN @first_date AND ph.date),0),
a1_price		= 	-- HERE I NEED TO FIND A MORE ELEGANT SOLUTION!!!
					COALESCE((SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date), 
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date +1),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date +2),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date +3),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date +4),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_1 AND ph.date = ap.date +5)),
a1_medium_price	= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_1) > 0, 
					(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_1), 0),
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
a2_amount 		= 	COALESCE((SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_2
					AND inv.date BETWEEN @first_date AND ph.date),0),
a2_price		= 	COALESCE((SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date), 
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date +1),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date +2),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date +3),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date +4),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_2 AND ph.date = ap.date +5)),
a2_medium_price	= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_2) > 0, 
					(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_2), 0),
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
a3_amount 		= 	COALESCE((SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_3
					AND inv.date BETWEEN @first_date AND ph.date),0),
a3_price		= 	COALESCE((SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date), 
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date +1),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date +2),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date +3),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date +4),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_3 AND ph.date = ap.date +5)),
a3_medium_price	= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_3) > 0, 
					(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_3), 0),
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
a4_amount 		= 	COALESCE((SELECT sum(amount)
					FROM inv_transactions inv
					WHERE isin = @asset_4
					AND inv.date BETWEEN @first_date AND ph.date),1),
a4_price		= 	COALESCE((SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date), 
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date +1),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date +2),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date +3),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date +4),
                    (SELECT close FROM asset_prices ap WHERE isin = @asset_4 AND ph.date = ap.date +5)),
a4_medium_price	= 	IF((SELECT Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_4) > 0, 
					(SELECT -Sum(original_value)/Sum(amount) FROM inv_transactions WHERE date <= ph.date AND isin = @asset_4), 0),
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

p_value				= CASE 
						WHEN a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value != 0 THEN a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value
                        ELSE NULL
					END,

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

usd_exposure		= IF(@a1_currency = 'USD', a1_local_value, 0)
					+ IF(@a2_currency = 'USD', a2_local_value, 0)
                    + IF(@a3_currency = 'USD', a3_local_value, 0)
                    + IF(@a4_currency = 'USD', a4_local_value, 0), /*
                    + IF(@a1_currency = 'USD', a5_local_value, 0)
                    + IF(@a1_currency = 'USD', a6_local_value, 0)
                    + IF(@a1_currency = 'USD', a7_local_value, 0)
                    + IF(@a1_currency = 'USD', a8_local_value, 0)
                    + IF(@a1_currency = 'USD', a8_local_value, 0)
                    + IF(@a1_currency = 'USD', a10_local_value, 0),*/

usd_exposure_eur	= usd_exposure / (SELECT close FROM forex_prices WHERE forex_pair = 'EURUSD' AND date = ph.date),

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
    
SELECT*
FROM p_hist;
