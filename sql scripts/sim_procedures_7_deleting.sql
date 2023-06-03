


DELIMiTER //
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
								    AND  MONTH(t1.date) IN (1, 7)) OR
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