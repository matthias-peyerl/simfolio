/*

SIMFOLIO

This document will guide you to either define and simulate a portfolio or to view data from a past simulation. 

To view a past simulations result JUMP TO ROW...

To create a new portfolio follow these steps
-- 1. Create a portflio name
-- 2. Define the portfolio assets (up to 7) and the respective allocations. 
      Note that the sum of all allocations must be not be more than 100%. (NOT SURE HOW TO IMPLEMENT THAT)
-- 3. 

*/

-- When strting we need to run the following procedure to make sure all relevant data is in place: 
CALL load_basics();


-- If you just want to run the simulation wityhout changing or adjusting anything, just call the following procedure: 

CALL just_run();


-- IF YOU ALREADY HAVE A PORTFOLIO YOU WANT TO USE: 
SET @portfolio_name 	= 'Periodic Standard';


-- Otherwise, if you want to create a new one or update an existing one follow these steps:
-- 1. Setting the portfolio name

SET @portfolio_name 	= CONCAT('Portfolio - ',current_timestamp());		-- Please design your own portfolio name

-- 2. Setting portfolio assets
--    You can choose assets from the simfolio_db.asset table where you will find 20 example instruments to choose from. 
-- 	  Copy the relevant symbol into the @asset_n variable and set the allocation. 
--    You can choose anywhere from 1 to 10 different ones and leave the rest blank. 

SELECT * 
FROM asset
WHERE symbol IN ('IWMO.L', 'PHAU.L', 'DBZB.DE');

SET @asset_1 = 'IWMO.L'; 					SET @asset_1_allocation = 34;
SET @asset_2 = 'PHAU.L'; 					SET @asset_2_allocation = 33;			
SET @asset_3 = 'DBZB.DE'; 					SET @asset_3_allocation = 33;
SET @asset_4 = ''; 							SET @asset_4_allocation = 15;
SET @asset_5 = ''; 							SET @asset_5_allocation = 10;
SET @asset_6 = ''; 							SET @asset_6_allocation = 15;
SET @asset_7 = ''; 							SET @asset_7_allocation = 5;
SET @asset_8 = ''; 							SET @asset_8_allocation = 10;
SET @asset_9 = ''; 							SET @asset_9_allocation = 10;
SET @asset_10 = ''; 						SET @asset_10_allocation = 10;


SET @portfolio_currency 			= 'EUR';		-- Choose from 'EUR' and 'USD'
SET @portfolio_transaction_cost 	=  1;			-- Set a realistic transaction cost for every time you trade.
SET @inicial_balance				= 100000;
SET @portfolio_strategy				= 'Periodic Standard';

-- --> IMPORTANT, CALL THE PARAMETERS TO BE STORED
CALL portfolio_creation();
CALL update_portfolio();

SELECT* FROM portfolio;

-- ---------------------------------------------------------

-- Choose from an existing strategy via the strategy name: 
SELECT* FROM strategy;

-- Or create a new set of strategy rules --  to do that, first set the strategy a new strategy name. : ALTER
SET @strategy_name				= 'Periodic Standard' ;   

-- Next, set the rebalancing type: 

SET @rebalancing_type 	= 'Period';			-- Choose from 'Deviation', 'Period' or 'none'

-- If you chose Deviation as rebalancing type:
SET @rel_rebalancing 	= 10;		-- The relative percentage that an asset can deviate fro it's target allocation. 
SET @min_rebalancing 	= 1 ;		-- The minimum deviation that would override the relative rebalancing if it is not reached. 

-- If you chose Period as rebalancing type:
SET @period 			= 'quarterly';		-- Chose from daily, weekly, monthly, quarterly, semi-annually and annually

-- Choose the portfolio leverage you want to apply, a leverage of 100 means twice the amount in your account will be bought into the portfolio. 
SET @leverage 			= 100; 
SET @lev_rebalancing 	= 5;

CALL strategy_creation();		-- Use this procedure to create a new strategy
CALL update_strategy();			-- Use this procedure to update an existing strategy

-- ____________________________________________________________________________

SELECT* FROM sim_temp;

DROP TABLE sim_looper;

CALL prepare_sim_variables();			
CALL prepare_sim_forex_data();			
CALL sim_table_creation();				
CALL first_periodic_data(); 		
CALL sim_periodic_looper(@period);
CALL sim_final_data_population;




DELIMITER //
CREATE PROCEDURE first_periodic_data()
BEGIN

ALTER TABLE sim_temp
ADD COLUMN reb_trigger_a1 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a2 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a3 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a4 TINYINT DEFAULT 0,
ADD COLUMN reb_trigger_a5 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a6 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a7 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a8 TINYINT DEFAULT 0,
ADD COLUMN reb_trigger_a9 TINYINT DEFAULT 0, 
ADD COLUMN reb_trigger_a10 TINYINT DEFAULT 0; 

-- Introducing all known data into the simulation tables' first row
-- First the calendar dates

INSERT INTO sim_temp (date)
	 SELECT date 
	   FROM calendar
      WHERE date = @start_date;

-- Secondly, all the lookup data and stored values
UPDATE sim_temp st
SET
portfolio_name 		= 	@portfolio_name,
a1_symbol 			= 	@asset_1,
a1_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_1),1),
a1_forex_pair		=	IF(@a1_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a1_fx_rate			= 	IF( @a1_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a1_forex_pair)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @portfolio_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END,
a2_symbol 			= 	@asset_2,	
a2_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_2),1),
a2_forex_pair		=	IF(@a2_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a2_fx_rate			= 	IF( @a2_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a2_forex_pair)),
a2_portfolio_price	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @portfolio_currency) THEN a2_price * a2_fx_rate
							ELSE a2_price / a2_fx_rate
						END,
a3_symbol 			= 	@asset_3,	
a3_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_3),1),
a3_forex_pair		=	IF(@a3_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a3_fx_rate			= 	IF( @a3_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a3_forex_pair)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @portfolio_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END,
a4_symbol 			= 	@asset_4,	
a4_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_4),1),
a4_forex_pair		=	IF(@a4_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a4_fx_rate			= 	IF( @a4_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a4_forex_pair)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @portfolio_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END,
a5_symbol 			= 	@asset_5,	
a5_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_5),1),
a5_forex_pair		=	IF(@a5_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a5_fx_rate			= 	IF( @a5_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a5_forex_pair)),
a5_portfolio_price	=	CASE 
							WHEN a5_forex_pair = CONCAT(@a5_currency, @portfolio_currency) THEN a5_price * a5_fx_rate
                            ELSE a5_price / a5_fx_rate
						END,
a6_symbol 			= 	@asset_6,	
a6_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_6),1),
a6_forex_pair		=	IF(@a6_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a6_fx_rate			= 	IF( @a6_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a6_forex_pair)),
a6_portfolio_price	=	CASE 
							WHEN a6_forex_pair = CONCAT(@a6_currency, @portfolio_currency) THEN a6_price * a6_fx_rate
                            ELSE a6_price / a6_fx_rate
						END,
a7_symbol 			= 	@asset_7,	
a7_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_7),1),
a7_forex_pair		=	IF(@a7_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a7_fx_rate			= 	IF( @a7_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a7_forex_pair)),
a7_portfolio_price	=	CASE 
							WHEN a7_forex_pair = CONCAT(@a7_currency, @portfolio_currency) THEN a7_price * a7_fx_rate
                            ELSE a7_price / a7_fx_rate
						END,
a8_symbol 			= 	@asset_8,	
a8_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_8),1),
a8_forex_pair		=	IF(@a8_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a8_fx_rate			= 	IF( @a8_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a8_forex_pair)),
a8_portfolio_price	=	CASE 
							WHEN a8_forex_pair = CONCAT(@a8_currency, @portfolio_currency) THEN a8_price * a8_fx_rate
                            ELSE a8_price / a8_fx_rate
						END,
a9_symbol 			= 	@asset_9,	
a9_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_9),1),
a9_forex_pair		=	IF(@a9_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a9_fx_rate			= 	IF( @a9_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a9_forex_pair)),
a9_portfolio_price	=	CASE 
							WHEN a9_forex_pair = CONCAT(@a9_currency, @portfolio_currency) THEN a9_price * a9_fx_rate
                            ELSE a9_price / a9_fx_rate
						END,
a10_symbol 			= 	@asset_1,	
a10_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_10),1),
a10_forex_pair		=	IF(@a10_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a10_fx_rate			= 	IF( @a10_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a10_forex_pair)),
a10_portfolio_price	=	CASE 
							WHEN a10_forex_pair = CONCAT(@a10_currency, @portfolio_currency) THEN a10_price * a10_fx_rate
                            ELSE a10_price / a10_fx_rate
						END;

UPDATE sim_temp
SET 
a1_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_1_allocation / 100 / a1_portfolio_price),0),
a2_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_2_allocation / 100 / a2_portfolio_price),0), 
a3_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_3_allocation / 100 / a3_portfolio_price),0), 
a4_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_4_allocation / 100 / a4_portfolio_price),0), 
a5_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_5_allocation / 100 / a5_portfolio_price),0), 
a6_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_6_allocation / 100 / a6_portfolio_price),0), 
a7_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_7_allocation / 100 / a7_portfolio_price),0), 
a8_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_8_allocation / 100 / a8_portfolio_price),0), 
a9_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_9_allocation / 100 / a9_portfolio_price),0), 
a10_amount 				= COALESCE(FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @asset_10_allocation / 100 / a10_portfolio_price),0), 
a1_amount_change		= a1_amount,
a2_amount_change		= a2_amount,
a3_amount_change		= a3_amount,
a4_amount_change		= a4_amount,
a5_amount_change		= a5_amount,
a6_amount_change		= a6_amount,
a7_amount_change		= a7_amount,
a8_amount_change		= a8_amount,
a9_amount_change		= a9_amount,
a10_amount_change		= a10_amount,
a1_portfolio_value		= a1_amount * a1_portfolio_price,
a2_portfolio_value		= a2_amount * a2_portfolio_price,
a3_portfolio_value		= a3_amount * a3_portfolio_price,
a4_portfolio_value		= a4_amount * a4_portfolio_price,
a5_portfolio_value		= a5_amount * a5_portfolio_price,
a6_portfolio_value		= a6_amount * a6_portfolio_price,
a7_portfolio_value		= a7_amount * a7_portfolio_price,
a8_portfolio_value		= a8_amount * a8_portfolio_price,
a9_portfolio_value		= a9_amount * a9_portfolio_price,
a10_portfolio_value		= a10_amount * a10_portfolio_price,
p_value 				= COALESCE(a1_portfolio_value, 0) +
						  COALESCE(a2_portfolio_value, 0) +
                          COALESCE(a3_portfolio_value, 0) +
                          COALESCE(a4_portfolio_value, 0) +
                          COALESCE(a5_portfolio_value, 0) +
                          COALESCE(a6_portfolio_value, 0) +
                          COALESCE(a7_portfolio_value, 0) +
                          COALESCE(a8_portfolio_value, 0) +
                          COALESCE(a9_portfolio_value, 0) +
                          COALESCE(a10_portfolio_value, 0),
buy 					= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
						+ a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value,
transaction_costs		= -(IF(a1_amount_change != 0, 1, 0)
							+ IF(a2_amount_change != 0, 1, 0)
							+ IF(a3_amount_change != 0, 1, 0)
							+ IF(a4_amount_change != 0, 1, 0)
                            + IF(a5_amount_change != 0, 1, 0)
                            + IF(a6_amount_change != 0, 1, 0)
                            + IF(a7_amount_change != 0, 1, 0)
                            + IF(a8_amount_change != 0, 1, 0)
                            + IF(a9_amount_change != 0, 1, 0)
                            + IF(a10_amount_change != 0, 1, 0)) * @portfolio_transaction_cost,
tot_change				= -(a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
						 + a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value) + transaction_costs,
acc_balance				= @inicial_balance + tot_change,
tot_balance				= p_value + acc_balance,
leverage_rate			= p_value / tot_balance,

a1_allocation 			= (a1_portfolio_value / (tot_balance*((@leverage+100)/100))),
a2_allocation 			= (a2_portfolio_value / (tot_balance*((@leverage+100)/100))),
a3_allocation 			= (a3_portfolio_value / (tot_balance*((@leverage+100)/100))),
a4_allocation 			= (a4_portfolio_value / (tot_balance*((@leverage+100)/100))),
a5_allocation 			= (a5_portfolio_value / (tot_balance*((@leverage+100)/100))),
a6_allocation 			= (a6_portfolio_value / (tot_balance*((@leverage+100)/100))),
a7_allocation 			= (a7_portfolio_value / (tot_balance*((@leverage+100)/100))),
a8_allocation 			= (a8_portfolio_value / (tot_balance*((@leverage+100)/100))),
a9_allocation 			= (a9_portfolio_value / (tot_balance*((@leverage+100)/100))),
a10_allocation 			= (a10_portfolio_value / (tot_balance*((@leverage+100)/100)))
WHERE date 				= @start_date;

ALTER TABLE sim_temp
ADD INDEX idx_date(date);

END //
;


DELIMITER //
CREATE PROCEDURE sim_periodic_looper(period VARCHAR(50))
BEGIN


DECLARE outer_counter INT DEFAULT 1; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE inner_counter INT DEFAULT 1;
DECLARE loop_date DATE DEFAULT ADDDATE((SELECT MAX(date) FROM sim_temp GROUP BY date), 1);

DROP TABLE IF EXISTS sim_looper;
CREATE TABLE sim_looper LIKE sim_temp;

WHILE outer_counter <= CEILING((DATEDIFF(@end_date, @start_date)-1)/@batch_size) DO

SET @max_date = (SELECT date FROM sim_temp ORDER BY date DESC LIMIT 1);

INSERT INTO sim_looper 
	 SELECT * 
       FROM sim_temp 
	  WHERE date = @max_date; 

INSERT INTO sim_looper (date)
	 SELECT date 
	   FROM calendar
      WHERE date BETWEEN adddate(@max_date, 1) 
		AND adddate(@max_date, @batch_size); 

-- INSERT KNOWN LOOKUP DATA
UPDATE sim_looper st
SET
portfolio_name 		= 	@portfolio_name,
a1_symbol 			= 	@asset_1,
a1_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_1),1),
a1_forex_pair		=	IF(@a1_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a1_fx_rate			= 	IF( @a1_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a1_forex_pair)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @portfolio_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END,
a2_symbol 			= 	@asset_2,	
a2_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_2),1),
a2_forex_pair		=	IF(@a2_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a2_fx_rate			= 	IF( @a2_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a2_forex_pair)),
a2_portfolio_price	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @portfolio_currency) THEN a2_price * a2_fx_rate
							ELSE a2_price / a2_fx_rate
						END,
a3_symbol 			= 	@asset_3,	
a3_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_3),1),
a3_forex_pair		=	IF(@a3_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a3_fx_rate			= 	IF( @a3_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a3_forex_pair)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @portfolio_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END,
a4_symbol 			= 	@asset_4,	
a4_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_4),1),
a4_forex_pair		=	IF(@a4_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a4_fx_rate			= 	IF( @a4_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a4_forex_pair)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @portfolio_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END,
a5_symbol 			= 	@asset_5,	
a5_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_5),1),
a5_forex_pair		=	IF(@a5_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a5_fx_rate			= 	IF( @a5_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a5_forex_pair)),
a5_portfolio_price	=	CASE 
							WHEN a5_forex_pair = CONCAT(@a5_currency, @portfolio_currency) THEN a5_price * a5_fx_rate
                            ELSE a5_price / a5_fx_rate
						END,
a6_symbol 			= 	@asset_6,	
a6_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_6),1),
a6_forex_pair		=	IF(@a6_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a6_fx_rate			= 	IF( @a6_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a6_forex_pair)),
a6_portfolio_price	=	CASE 
							WHEN a6_forex_pair = CONCAT(@a6_currency, @portfolio_currency) THEN a6_price * a6_fx_rate
                            ELSE a6_price / a6_fx_rate
						END,
a7_symbol 			= 	@asset_7,	
a7_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_7),1),
a7_forex_pair		=	IF(@a7_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a7_fx_rate			= 	IF( @a7_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a7_forex_pair)),
a7_portfolio_price	=	CASE 
							WHEN a7_forex_pair = CONCAT(@a7_currency, @portfolio_currency) THEN a7_price * a7_fx_rate
                            ELSE a7_price / a7_fx_rate
						END,
a8_symbol 			= 	@asset_8,	
a8_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_8),1),
a8_forex_pair		=	IF(@a8_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a8_fx_rate			= 	IF( @a8_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a8_forex_pair)),
a8_portfolio_price	=	CASE 
							WHEN a8_forex_pair = CONCAT(@a8_currency, @portfolio_currency) THEN a8_price * a8_fx_rate
                            ELSE a8_price / a8_fx_rate
						END,
a9_symbol 			= 	@asset_9,	
a9_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_9),1),
a9_forex_pair		=	IF(@a9_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a9_fx_rate			= 	IF( @a9_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a9_forex_pair)),
a9_portfolio_price	=	CASE 
							WHEN a9_forex_pair = CONCAT(@a9_currency, @portfolio_currency) THEN a9_price * a9_fx_rate
                            ELSE a9_price / a9_fx_rate
						END,
a10_symbol 			= 	@asset_1,	
a10_price			= 	COALESCE((SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_10),1),
a10_forex_pair		=	IF(@a10_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a10_fx_rate			= 	IF( @a10_currency = @portfolio_currency, 1, (SELECT last_close FROM forex_prices WHERE date = st.date AND forex_pair = a10_forex_pair)),
a10_portfolio_price	=	CASE 
							WHEN a10_forex_pair = CONCAT(@a10_currency, @portfolio_currency) THEN a10_price * a10_fx_rate
                            ELSE a10_price / a10_fx_rate
						END;

-- Setting up the inner loop
WHILE inner_counter <= @batch_size AND loop_date <= @end_date DO

UPDATE sim_looper t1
JOIN (
SELECT 
date, 
LAG(date) OVER (ORDER BY date) prev_date,
LAG(reb_trigger_a1) OVER (ORDER BY date) prev_reb_trigger_a1,
LAG(reb_trigger_a2) OVER (ORDER BY date) prev_reb_trigger_a2,
LAG(reb_trigger_a3) OVER (ORDER BY date) prev_reb_trigger_a3,
LAG(reb_trigger_a4) OVER (ORDER BY date) prev_reb_trigger_a4,
LAG(reb_trigger_a5) OVER (ORDER BY date) prev_reb_trigger_a5,
LAG(reb_trigger_a6) OVER (ORDER BY date) prev_reb_trigger_a6,
LAG(reb_trigger_a7) OVER (ORDER BY date) prev_reb_trigger_a7,
LAG(reb_trigger_a8) OVER (ORDER BY date) prev_reb_trigger_a8,
LAG(reb_trigger_a9) OVER (ORDER BY date) prev_reb_trigger_a9,
LAG(reb_trigger_a10) OVER (ORDER BY date) prev_reb_trigger_a10,
LAG(a1_amount) OVER (ORDER BY date) prev_a1_amount,
LAG(a2_amount) OVER (ORDER BY date) prev_a2_amount,
LAG(a3_amount) OVER (ORDER BY date) prev_a3_amount,
LAG(a4_amount) OVER (ORDER BY date) prev_a4_amount,
LAG(a5_amount) OVER (ORDER BY date) prev_a5_amount,
LAG(a6_amount) OVER (ORDER BY date) prev_a6_amount,
LAG(a7_amount) OVER (ORDER BY date) prev_a7_amount,
LAG(a8_amount) OVER (ORDER BY date) prev_a8_amount,
LAG(a9_amount) OVER (ORDER BY date) prev_a9_amount,
LAG(a10_amount) OVER (ORDER BY date) prev_a10_amount,
LAG(acc_balance) OVER (ORDER BY date) prev_acc_balance,
LAG(tot_balance) OVER (ORDER BY date) prev_tot_balance,
LAG(leverage_rate) OVER (ORDER BY date) prev_leverage_rate,
LAG(a1_allocation) OVER (ORDER BY date) a1_prev_allocation,
LAG(a2_allocation) OVER (ORDER BY date) a2_prev_allocation,
LAG(a3_allocation) OVER (ORDER BY date) a3_prev_allocation,
LAG(a4_allocation) OVER (ORDER BY date) a4_prev_allocation,
LAG(a5_allocation) OVER (ORDER BY date) a5_prev_allocation,
LAG(a6_allocation) OVER (ORDER BY date) a6_prev_allocation,
LAG(a7_allocation) OVER (ORDER BY date) a7_prev_allocation,
LAG(a8_allocation) OVER (ORDER BY date) a8_prev_allocation,
LAG(a9_allocation) OVER (ORDER BY date) a9_prev_allocation,
LAG(a10_allocation) OVER (ORDER BY date) a10_prev_allocation
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
								 AND (SELECT close FROM asset_prices ap WHERE symbol = @asset_1 AND date = prev_date) IS NULL 	
                                THEN 1
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
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_2 AND date = prev_date) IS NULL 	
                                THEN 1
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
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_3 AND date = prev_date) IS NULL 	
                                THEN 1
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
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a5				= CASE 
								WHEN prev_reb_trigger_a5 = 0										
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
								WHEN prev_reb_trigger_a5 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a6				= CASE 
								WHEN prev_reb_trigger_a6 = 0										
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
								WHEN prev_reb_trigger_a6 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a7				= CASE 
								WHEN prev_reb_trigger_a7 = 0										
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
								WHEN prev_reb_trigger_a7 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a8				= CASE 
								WHEN prev_reb_trigger_a8 = 0										
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
								WHEN prev_reb_trigger_a8 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a9				= CASE 
								WHEN prev_reb_trigger_a9 = 0										
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
								WHEN prev_reb_trigger_a9 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
reb_trigger_a10				= CASE 
								WHEN prev_reb_trigger_a10 = 0										
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
								WHEN prev_reb_trigger_a10 = 1 
									AND (SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = prev_date) IS NULL 	
                                THEN 1
                                ELSE 0
							END,
t1.a1_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_1 AND date = t1.date) IS NOT NULL
									 AND reb_trigger_a1 = 1,                               
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_1_allocation / 100 / a1_portfolio_price),
									t2.prev_a1_amount),                         										                                   
t1.a2_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_2 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a2 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_2_allocation / 100 / a2_portfolio_price),
                                    t2.prev_a2_amount),
t1.a3_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_3 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a3 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_3_allocation / 100 / a3_portfolio_price),
                                    t2.prev_a3_amount),
t1.a4_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_4 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a4 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_4_allocation / 100 / a4_portfolio_price),
                                    t2.prev_a4_amount),
t1.a5_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_5 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a5 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_5_allocation / 100 / a5_portfolio_price),
                                    t2.prev_a5_amount),
t1.a6_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_6 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a6 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_6_allocation / 100 / a6_portfolio_price),
                                    t2.prev_a6_amount),
t1.a7_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_7 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a7 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_7_allocation / 100 / a7_portfolio_price),
                                    t2.prev_a7_amount),
t1.a8_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_8 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a8 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_8_allocation / 100 / a8_portfolio_price),
                                    t2.prev_a8_amount),
t1.a9_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_9 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a9 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_9_allocation / 100 / a9_portfolio_price),
                                    t2.prev_a9_amount),
t1.a10_amount 				= IF((SELECT close FROM asset_prices WHERE symbol = @asset_10 AND date = t1.date) IS NOT NULL
									AND reb_trigger_a10 = 1, 
									FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_10_allocation / 100 / a10_portfolio_price),
                                    t2.prev_a10_amount),                                    
t1.a1_amount_change       		= a1_amount - prev_a1_amount,                             
t1.a2_amount_change				= a2_amount - prev_a2_amount, 
t1.a3_amount_change				= a3_amount - prev_a3_amount, 
t1.a4_amount_change				= a4_amount - prev_a4_amount,  
t1.a5_amount_change				= a5_amount - prev_a5_amount,  
t1.a6_amount_change				= a6_amount - prev_a6_amount,  
t1.a7_amount_change				= a7_amount - prev_a7_amount,  
t1.a8_amount_change				= a8_amount - prev_a8_amount,  
t1.a9_amount_change				= a9_amount - prev_a9_amount,  
t1.a10_amount_change			= a10_amount - prev_a10_amount,  
t1.a1_portfolio_value			= a1_amount * a1_portfolio_price,
t1.a2_portfolio_value			= a2_amount * a2_portfolio_price,
t1.a3_portfolio_value			= a3_amount * a3_portfolio_price,
t1.a4_portfolio_value			= a4_amount * a4_portfolio_price,
t1.a5_portfolio_value			= a5_amount * a5_portfolio_price,
t1.a6_portfolio_value			= a6_amount * a6_portfolio_price,
t1.a7_portfolio_value			= a7_amount * a7_portfolio_price,
t1.a8_portfolio_value			= a8_amount * a8_portfolio_price,
t1.a9_portfolio_value			= a9_amount * a9_portfolio_price,
t1.a10_portfolio_value			= a10_amount * a10_portfolio_price,
t1.p_value 						= a1_portfolio_value + a2_portfolio_value + a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
								+ a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value,
t1.buy 							=	(SELECT 	IF(a1_amount > t2.prev_a1_amount, -t1.a1_portfolio_price * (t1.a1_amount - t2.prev_a1_amount),0)+
											IF(a2_amount > t2.prev_a2_amount, -t1.a2_portfolio_price * (t1.a2_amount - t2.prev_a2_amount),0)+ 
											IF(a3_amount > t2.prev_a3_amount, -t1.a3_portfolio_price * (t1.a3_amount - t2.prev_a3_amount),0)+
											IF(a4_amount > t2.prev_a4_amount, -t1.a4_portfolio_price * (t1.a4_amount - t2.prev_a4_amount),0)+
                                            IF(a5_amount > t2.prev_a5_amount, -t1.a5_portfolio_price * (t1.a5_amount - t2.prev_a5_amount),0)+
                                            IF(a6_amount > t2.prev_a6_amount, -t1.a6_portfolio_price * (t1.a6_amount - t2.prev_a6_amount),0)+
                                            IF(a7_amount > t2.prev_a7_amount, -t1.a7_portfolio_price * (t1.a7_amount - t2.prev_a7_amount),0)+
                                            IF(a8_amount > t2.prev_a8_amount, -t1.a8_portfolio_price * (t1.a8_amount - t2.prev_a8_amount),0)+
                                            IF(a9_amount > t2.prev_a9_amount, -t1.a9_portfolio_price * (t1.a9_amount - t2.prev_a9_amount),0)+
                                            IF(a10_amount > t2.prev_a10_amount, -t1.a10_portfolio_price * (t1.a10_amount - t2.prev_a10_amount),0)),
t1.sell						=	(SELECT 	IF(a1_amount < t2.prev_a1_amount, -t1.a1_portfolio_price * (t1.a1_amount - t2.prev_a1_amount),0) +
											IF(a2_amount < t2.prev_a2_amount, -t1.a2_portfolio_price * (t1.a2_amount - t2.prev_a2_amount),0)+ 
											IF(a3_amount < t2.prev_a3_amount, -t1.a3_portfolio_price * (t1.a3_amount - t2.prev_a3_amount),0)+ 
											IF(a4_amount < t2.prev_a4_amount, -t1.a4_portfolio_price * (t1.a4_amount - t2.prev_a4_amount),0)+ 
                                            IF(a5_amount < t2.prev_a5_amount, -t1.a5_portfolio_price * (t1.a5_amount - t2.prev_a5_amount),0)+
                                            IF(a6_amount < t2.prev_a6_amount, -t1.a6_portfolio_price * (t1.a6_amount - t2.prev_a6_amount),0)+
                                            IF(a7_amount < t2.prev_a7_amount, -t1.a7_portfolio_price * (t1.a7_amount - t2.prev_a7_amount),0)+
                                            IF(a8_amount < t2.prev_a8_amount, -t1.a8_portfolio_price * (t1.a8_amount - t2.prev_a8_amount),0)+
                                            IF(a9_amount < t2.prev_a9_amount, -t1.a9_portfolio_price * (t1.a9_amount - t2.prev_a9_amount),0)+
											IF(a10_amount < t2.prev_a10_amount, -t1.a10_portfolio_price * (t1.a10_amount - t2.prev_a10_amount),0)),
transaction_costs 			= 	-(IF(a1_amount_change != 0, 1, 0)
								+ IF(a2_amount_change != 0, 1, 0)
								+ IF(a3_amount_change != 0, 1, 0)
								+ IF(a4_amount_change != 0, 1, 0)
                                + IF(a5_amount_change != 0, 1, 0)
								+ IF(a6_amount_change != 0, 1, 0)
								+ IF(a7_amount_change != 0, 1, 0)
                                + IF(a8_amount_change != 0, 1, 0)
								+ IF(a9_amount_change != 0, 1, 0)
								+ IF(a10_amount_change != 0, 1, 0)) * @portfolio_transaction_cost,  
-- THE INTEREST IS BEING CALCULATED ON A DAILY BASIS instead of a monthly one for ease of programing. The rate is set as the RFR + 1%, which is a realistic rate for a serious brokerage firm. 
interest					= 	IF(prev_acc_balance < 0, prev_acc_balance * (SELECT last_rate + @interest_augment 
																				FROM econ_indicator_values 
																				WHERE symbol = 'EUR-RFR' 
                                                                                AND date = t1.date)
                                                                                /100/365, 
                                                                                0),
t1.tot_change				=	t1.buy + t1.sell + t1.deposit + t1.withdrawl + t1.transaction_costs + t1.interest,
t1.acc_balance				=	CASE
								WHEN t1.date = @start_date THEN tot_change
								ELSE t2.prev_acc_balance + tot_change
								END,
t1.tot_balance				=	acc_balance + p_value,
leverage_rate				=	p_value / tot_balance -1,
a1_allocation 				= (a1_portfolio_value / (tot_balance*((@leverage+100)/100))),
a2_allocation 				= (a2_portfolio_value / (tot_balance*((@leverage+100)/100))),
a3_allocation 				= (a3_portfolio_value / (tot_balance*((@leverage+100)/100))),
a4_allocation 				= (a4_portfolio_value / (tot_balance*((@leverage+100)/100))),
a5_allocation 				= (a5_portfolio_value / (tot_balance*((@leverage+100)/100))),
a6_allocation 				= (a6_portfolio_value / (tot_balance*((@leverage+100)/100))),
a7_allocation 				= (a7_portfolio_value / (tot_balance*((@leverage+100)/100))),
a8_allocation 				= (a8_portfolio_value / (tot_balance*((@leverage+100)/100))),
a9_allocation 				= (a9_portfolio_value / (tot_balance*((@leverage+100)/100))),
a10_allocation 				= (a10_portfolio_value / (tot_balance*((@leverage+100)/100)))
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

DELETE FROM sim_temp
WHERE a1_amount IS NULL
OR date > @end_date;
	
END//