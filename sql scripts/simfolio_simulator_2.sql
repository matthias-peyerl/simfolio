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


-- If you just want to run the simulation wityhout changing or adjusting anything, just call the following procedure: 

CALL just_run();


-- IF YOU ALREADY HAVE A PORTFOLIO YOU WANT TO USE: 
SET @portfolio_name 	= 'Standart';



-- Otherwise, if you want to create a new one
-- 1. Setting the portfolio name

SET @portfolio_name 	= CONCAT('Portfolio - ',current_timestamp());		-- Please design your own portfolio name
SET @portfolio_currency = 'EUR';											-- Choose from 'EUR' and 'USD'
SET @inicial_balance	= 100000;


-- 2. Setting portfolio assets
--    You can choose assets from the simfolio_db.asset table where you will find 20 example instruments to choose from. 
-- 	  Copy the relevant symbol into the @asset_n variable and set the allocation. 
--    You can choose anywhere from 1 to 10 different ones and leave the rest blank. 

SELECT * 
FROM asset
WHERE symbol IN ('IWMO.L', 'PHAU.L', 'DBZB.DE');

SET @asset_1 = 'IWMO.L'; 					SET @asset_1_allocation = 5;
SET @asset_2 = 'IWMO.L'; 					SET @asset_2_allocation = 10;			
SET @asset_3 = 'IWMO.L'; 					SET @asset_3_allocation = 5;
SET @asset_4 = 'PHAU.L'; 					SET @asset_4_allocation = 15;
SET @asset_5 = 'PHAU.L'; 					SET @asset_5_allocation = 10;
SET @asset_6 = 'PHAU.L'; 					SET @asset_6_allocation = 15;
SET @asset_7 = 'IWMO.L'; 					SET @asset_7_allocation = 5;
SET @asset_8 = 'DBZB.DE'; 					SET @asset_8_allocation = 10;
SET @asset_9 = 'DBZB.DE'; 					SET @asset_9_allocation = 10;
SET @asset_10 = 'DBZB.DE'; 					SET @asset_10_allocation = 10;


SET @portfolio_currency 			= 'EUR';		-- Choose from 'EUR' and 'USD'
SET @portfolio_transaction_cost 	=  1;			-- Set a realistic transaction cost for every time you trade.

SET @portfolio_strategy				= 'Standart';	-- Choose from an existing strategy or create a new one further down and set it as your portfolio strategy here. 

-- --> IMPORTANT, CALL THE PARAMETERS TO BE STORED
CALL portfolio_creation();
CALL update_portfolio();

SELECT * FROM portfolio;
SELECT * FROM portfolio_asset WHERE portfolio_name = @portfolio_name;
-- ---------------------------------------------------------


-- Choose from an existing strategy via the strategy name: 
SELECT* FROM strategy;

-- Or create a new set of strategy rules --  to do that, first set the strategy a new strategy name. : ALTER
SET @strategy_name				= 'New name here if you want to create your own strategy' ;   

-- Next, set the rebalancing type: 

SET @rebalancing_type = 'Deviation';			-- Choose from 'Deviation', 'Period' or 'none'

-- If you chose Deviation as rebalancing type:
SET @rel_rebalancing = 10;		-- The relative percentage that an asset can deviate fro it's target allocation. 
SET @min_rebalancing = 1 ;		-- The minimum deviation that would override the relative rebalancing if it is not reached. 

-- If you chose Period as rebalancing type:
SET @period = 'monthly';		-- Chose from daily, weekly, monthly, quarterly, semi-annually and annually

-- Choose the portfolio leverage you want to apply, a leverage of 100 means twice the amount in your account will be bought into the portfolio. 
SET @leverage = 100; 
SET @lev_rebalancing = 5;

CALL strategy_creation();		-- Use this procedure to create a new strategy
CALL update_strategy();			-- Use this procedure to update an existing strategy

-- ____________________________________________________________________________


(SELECT COUNT(DISTINCT symbol) FROM asset_prices);

-----------------------------------
;
LAST CLOSE UPDATE PROCEDURE
;

CALL last_close_price_update();


SELECT* FROM sim_temp;
SELECT* FROM sim_forex_prices;

CALL inception_update();
CALL end_date_update();		
CALL last_close_price_update();
CALL load_basic_setting();				
CALL prepare_sim_variables();			
CALL prepare_sim_forex_data();			
CALL prepare_sim_asset_data();			
CALL sim_table_creation();				
CALL known_data_insertion(); 			-- very long
CALL first_row_data_insertion();
-- CALL first_row_data_insertion();		

DROP TABLE sim_asset_1_prices2;

DROP PROCEDURE load_basic_setting;
DROP PROCEDURE prepare_sim_variables;
DROP PROCEDURE prepare_sim_forex_data;
DROP PROCEDURE prepare_sim_asset_data;
DROP PROCEDURE sim_table_creation;
DROP PROCEDURE known_data_insertion;
DROP PROCEDURE first_row_data_insertion;
-- EVERYTHING SET. Now you can run the simulation: 


-- IN THIS PROCEDURE I STILL NEED TO FILTER FOR IT TO ONLY APPLY TO ASSETS WHERE LAST_CLOSE = NULL AT LEAST SOME DATE.
-- ALSO CREATE THE SAME STRUCTURE FOR FOREX
DELIMITER //
CREATE PROCEDURE last_close_price_update()
BEGIN

DECLARE n INT DEFAULT 0;

DROP TABLE IF EXISTS asset_prices_update;

CREATE TABLE asset_prices_update LIKE asset_prices;

WHILE n < (SELECT COUNT(DISTINCT symbol) FROM asset_prices) DO

INSERT INTO asset_prices_update
SELECT c.date, (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n) symbol, 
			   (SELECT exchange FROM asset_prices WHERE symbol = (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n) LIMIT 1) exchange,
			   (SELECT data_provider FROM asset_prices WHERE symbol = (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n) LIMIT 1) data_provider,
			   open, high, low, close,
	   IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
											 (LAG(close,2) OVER (ORDER BY c.date)),
											 (LAG(close,3) OVER (ORDER BY c.date)),
											 (LAG(close,4) OVER (ORDER BY c.date)),
											 (LAG(close,5) OVER (ORDER BY c.date)))) last_close
FROM calendar c                       
  LEFT JOIN  (SELECT date, symbol, exchange, data_provider, open, high, low, close
			    FROM asset_prices
			   WHERE symbol = (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n)) symbol             
	     ON symbol.date = c.date
	  WHERE c.date BETWEEN (SELECT inception_date FROM asset WHERE symbol = (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n))
					AND (SELECT end_date FROM asset WHERE symbol = (SELECT DISTINCT symbol FROM asset_prices GROUP BY symbol LIMIT 1 OFFSET n));

SET n = n + 1;

END WHILE;

DELETE 
FROM asset_prices;

INSERT INTO asset_prices
SELECT *
FROM asset_prices_update;

DROP TABLE asset_prices_update;


END //
;

-- The procedure to be loaded in the beginning:
DELIMITER //
CREATE PROCEDURE load_basic_setting()
BEGIN 

	SET @inicial_balance 		=	100000;
	SET @batch_size		 		=	10;
	SET @interest_augment		=	1;			-- INTEREST AUGMENTATION OF RFR + _% -- out of sight, because its explenation is out of scope
    SET @portfolio_name			= 	'Standart';
        
END //
;

DELIMETER //
-- Creating a Procedure to load all the variables 
CREATE PROCEDURE prepare_sim_variables()
BEGIN
	
-- First we load the all the variables according to the chosen portfolio, 
-- in case it was not newly created they would not have been loaded yet. 

SET     					-- 	Setting the variables from tyhe portfolio table
@portfolio_currency 		= 	(SELECT portfolio_currency FROM portfolio WHERE portfolio_name = @portfolio_name),
@portfolio_transaction_cost	=	(SELECT portfolio_transaction_cost FROM portfolio WHERE portfolio_name = @portfolio_name),
@portfolio_strategy			=	(SELECT portfolio_strategy FROM portfolio WHERE portfolio_name = @portfolio_name);

SET							-- 	Setting the variables from the strategy table
@rebalancing_type			=	(SELECT rebalancing_type FROM strategy WHERE strategy_name = @portfolio_strategy),
@period						=	(SELECT period FROM strategy WHERE strategy_name = @portfolio_strategy),	
@leverage					=	(SELECT leverage FROM strategy WHERE strategy_name = @portfolio_strategy),
@lev_rebalancing			=	(SELECT lev_rebalancing	FROM strategy WHERE strategy_name = @portfolio_strategy),	
@min_rebalancing			=	(SELECT min_rebalancing	FROM strategy WHERE strategy_name = @portfolio_strategy),
@rel_rebalancing			=	(SELECT rel_rebalancing	FROM strategy WHERE strategy_name = @portfolio_strategy);

SET							-- 	Setting the variables from the portfolio assets table. Assets will be named 1-10 according to their allocation. 
@asset_1 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 0), 
@asset_2 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 1),
@asset_3 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 2),
@asset_4 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 3),
@asset_5 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 4),
@asset_6 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 5),
@asset_7 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 6),
@asset_8 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 7),
@asset_9 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 8),
@asset_10		 		= (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 9),
@asset_1_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 0), 
@asset_2_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 1),
@asset_3_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 2),
@asset_4_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 3),
@asset_5_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 4),
@asset_6_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 5),
@asset_7_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 6),
@asset_8_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 7),
@asset_9_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 8),
@asset_10_allocation	= (SELECT allocation FROM portfolio_asset WHERE portfolio_name = @portfolio_name ORDER BY allocation DESC LIMIT 1 OFFSET 9),
@a1_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_1), 
@a2_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_2),
@a3_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_3),
@a4_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_4),
@a5_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_5),
@a6_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_6),
@a7_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_7),
@a8_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_8),
@a9_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_9),
@a10_currency 			= (SELECT currency FROM asset WHERE symbol = @asset_10);

 SET @start_date = (SELECT MAX(inception_date)
					  FROM asset
					 WHERE symbol IN (SELECT symbol 
                                        FROM portfolio_asset 
									   WHERE portfolio_name = @portfolio_name));
 
  SET @end_date =  (SELECT MIN(end_date)
					  FROM asset
					 WHERE symbol IN (SELECT symbol 
                                        FROM portfolio_asset 
									   WHERE portfolio_name = @portfolio_name));

END //
;

-- Here I need to change the structure to be the same as in the assets
DELIMETER //
CREATE PROCEDURE prepare_sim_forex_data()
BEGIN

-- Here I will collect all the tables that are being created in the simulation
-- In the meanwhile I will comment them out, to prevent redundant droppings.    
    
DROP TABLE IF EXISTS sim_currencies;
DROP TABLE IF EXISTS sim_forex_pair;
DROP TABLE IF EXISTS sim_forex_prices;

-- --- temp_portfolio_currencies;
-- --- DROP TABLE IF EXISTS temp_p_forex_pairs;
-- --- DROP TABLE IF EXISTS p_forex_count;
-- DROP TABLE IF EXISTS sim_looper;
-- DROP TABLE IF EXISTS sim_temp;
-- DROP TABLE IF EXISTS p_simulation;


-- Collecting all currencies that are not the portfolio currency 
-- a feature that will make more sense once we handle several currencies, not only EUR and USD 
  
   CREATE TABLE sim_currencies AS
SELECT DISTINCT currency
		   FROM asset 
           JOIN	portfolio_asset
             ON	asset.symbol = portfolio_asset.symbol
		  WHERE	currency != @portfolio_currency;

CREATE TABLE sim_forex_pair AS
      SELECT forex_pair
        FROM forex_pair
       WHERE (base_currency  IN (SELECT currency FROM sim_currencies)
	      OR quote_currency  IN (SELECT currency FROM sim_currencies))
		 AND (base_currency  = @portfolio_currency
		  OR quote_currency  = @portfolio_currency);
 
-- For the sake of this example excercise we will only create one forex price table as there will only be one forex pair. 
-- For a wider simulator the best wold be to have all the las_close prices prepared and stored in the general price data tables. 
CREATE TABLE sim_forex_prices AS
      SELECT c.date , forex_pair, open, high, low, close,
			 IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
				 								  (LAG(close,2) OVER (ORDER BY c.date)),
					 							  (LAG(close,3) OVER (ORDER BY c.date)),
						 						  (LAG(close,4) OVER (ORDER BY c.date)),
							 					  (LAG(close,5) OVER (ORDER BY c.date)))) last_close
       FROM  calendar c                       
  LEFT JOIN  (SELECT date, forex_pair, open, high, low, close
			    FROM forex_prices
			   WHERE forex_pair = (SELECT forex_pair FROM sim_forex_pair LIMIT 1)) a
	     ON  a.date  = c.date
	  WHERE  c.date  BETWEEN @start_date AND @end_date;


END//
;

DELIMITER//
CREATE PROCEDURE prepare_sim_asset_data()
BEGIN 

DROP TABLE IF EXISTS sim_asset_prices;

-- NT SURE IF THIS IS STILL NEEDED
-- SET @sim_asset_count		 = (SELECT COUNT(DISTINCT symbol) FROM portfolio_asset WHERE portfolio_name = @portfolio_name);

-- Creating a temporary table with every calendar date of the simulation and a price for each calendar date, for each asset and forex pair. 
CREATE TABLE sim_asset_prices AS
      SELECT date , symbol, open, high, low, close, last_close
        FROM asset_prices
	   WHERE symbol IN (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name)
         AND date BETWEEN @start_date AND @end_date;

END //
;

DELIMITER //
CREATE PROCEDURE sim_table_creation() -- Creating the table and filling in date and price data 
BEGIN

DROP TABLE IF EXISTS sim_temp; 

CREATE TABLE sim_temp ( -- Temporary table for a simulation
    date DATE PRIMARY KEY,
    portfolio_name VARCHAR(100),
    
   	a1_symbol VARCHAR(20), a1_price FLOAT, a1_forex_pair VARCHAR(10), a1_fx_rate FLOAT, a1_portfolio_price FLOAT,
    a1_amount INT, a1_amount_change INT, a1_local_value FLOAT, a1_portfolio_value FLOAT, 
	a1_local_change_d FLOAT, a1_portfolio_change_d FLOAT, a1_allocation FLOAT);
    
              IF @asset_2 IN (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name)
THEN ALTER TABLE sim_temp
      ADD COLUMN a2_symbol VARCHAR(20),
      ADD COLUMN a2_price FLOAT, 
      ADD COLUMN a2_forex_pair VARCHAR(10),
      ADD COLUMN a2_fx_rate FLOAT,
      ADD COLUMN a2_portfolio_price FLOAT,
      ADD COLUMN a2_amount INT, 
      ADD COLUMN a2_amount_change INT, 
      ADD COLUMN a2_local_value FLOAT, 
      ADD COLUMN a2_portfolio_value FLOAT, 
      ADD COLUMN a2_local_change_d FLOAT, 
      ADD COLUMN a2_portfolio_change_d FLOAT,
      ADD COLUMN a2_allocation FLOAT;
		  END IF;
         
	/*
	a2_symbol VARCHAR(20), a2_price FLOAT, a2_forex_pair VARCHAR(10), a2_fx_rate FLOAT, a2_portfolio_price FLOAT,
    a2_amount INT, a2_amount_change INT, a2_local_value FLOAT, a2_portfolio_value FLOAT, 
	a2_local_change_d FLOAT, a2_portfolio_change_d FLOAT,

	a3_symbol VARCHAR(20), a3_price FLOAT, a3_forex_pair VARCHAR(10), a3_fx_rate FLOAT, a3_portfolio_price FLOAT,
    a3_amount INT, a3_amount_change INT, a3_local_value FLOAT, a3_portfolio_value FLOAT, 
	a3_local_change_d FLOAT, a3_portfolio_change_d FLOAT,

	a4_symbol VARCHAR(20), a4_price FLOAT, a4_forex_pair VARCHAR(10), a4_fx_rate FLOAT, a4_portfolio_price FLOAT,
    a4_amount INT, a4_amount_change INT, a4_local_value FLOAT, a4_portfolio_value FLOAT, 
	a4_local_change_d FLOAT, a4_portfolio_change_d FLOAT,

	a5_symbol VARCHAR(20), a5_price FLOAT, a5_forex_pair VARCHAR(10), a5_fx_rate FLOAT, a5_portfolio_price FLOAT,
    a5_amount INT, a5_amount_change INT, a5_local_value FLOAT, a5_portfolio_value FLOAT, 
	a5_local_change_d FLOAT, a5_portfolio_change_d FLOAT,

	a6_symbol VARCHAR(20), a6_price FLOAT, a6_forex_pair VARCHAR(10), a6_fx_rate FLOAT, a6_portfolio_price FLOAT,
    a6_amount INT, a6_amount_change INT, a6_local_value FLOAT, a6_portfolio_value FLOAT, 
	a6_local_change_d FLOAT, a6_portfolio_change_d FLOAT,

	a7_symbol VARCHAR(20), a7_price FLOAT, a7_forex_pair VARCHAR(10), a7_fx_rate FLOAT, a7_portfolio_price FLOAT,
    a7_amount INT, a7_amount_change INT, a7_local_value FLOAT, a7_portfolio_value FLOAT, 
	a7_local_change_d FLOAT, a7_portfolio_change_d FLOAT,

	a8_symbol VARCHAR(20), a8_price FLOAT, a8_forex_pair VARCHAR(10), a8_fx_rate FLOAT, a8_portfolio_price FLOAT,
    a8_amount INT, a8_amount_change INT, a8_local_value FLOAT, a8_portfolio_value FLOAT, 
	a8_local_change_d FLOAT, a8_portfolio_change_d FLOAT,

	a9_symbol VARCHAR(20), a9_price FLOAT, a9_forex_pair VARCHAR(10), a9_fx_rate FLOAT, a9_portfolio_price FLOAT,
    a9_amount INT, a9_amount_change INT, a9_local_value FLOAT, a9_portfolio_value FLOAT, 
	a9_local_change_d FLOAT, a9_portfolio_change_d FLOAT,

	a10_symbol VARCHAR(20), a10_price FLOAT, a10_forex_pair VARCHAR(10), a10_fx_rate FLOAT, a10_portfolio_price FLOAT,
    a10_amount INT, a10_amount_change INT, a10_local_value FLOAT, a10_portfolio_value FLOAT, 
	a10_local_change_d FLOAT, a10_portfolio_change_d FLOAT,
    */

-- ADDING ACCOUNT METRICS

ALTER TABLE sim_temp
 ADD COLUMN p_value FLOAT,
 ADD COLUMN usd_exposure_usd FLOAT,
 ADD COLUMN usd_exposure_eur FLOAT,
 ADD COLUMN eur_exposure FLOAT,
 ADD COLUMN buy FLOAT DEFAULT 0,
 ADD COLUMN sell FLOAT DEFAULT 0, 
 ADD COLUMN transaction_costs FLOAT DEFAULT 0, 
 ADD COLUMN interest FLOAT DEFAULT 0, 
 ADD COLUMN deposit FLOAT DEFAULT 0, 
 ADD COLUMN withdrawl FLOAT DEFAULT 0,
 ADD COLUMN tot_change FLOAT DEFAULT 0,
 ADD COLUMN acc_balance FLOAT DEFAULT 0,
 ADD COLUMN tot_balance FLOAT DEFAULT 0, 
 ADD COLUMN leverage_rate FLOAT, 
 ADD COLUMN tot_balance_change_d FLOAT;

END//
;

DELIMITER //
CREATE PROCEDURE known_data_insertion()
BEGIN

-- Introducing all known data into the simulation table
-- First the calendar dates

INSERT INTO sim_temp (date)
	 SELECT date 
	   FROM calendar
      WHERE date BETWEEN @start_date
					 AND @end_date;

-- Secondly, all the lookup data and stored values

UPDATE sim_temp st
SET 
portfolio_name 		= 	@portfolio_name,
a1_symbol 			= 	@asset_1,
a1_price			= 	(SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_1),
a1_forex_pair		=	IF(@a1_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a1_fx_rate			= 	IF( @a1_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @portfolio_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END;

		 IF @asset_2 IN (SELECT symbol FROM portfolio_asset WHERE portfolio_name = @portfolio_name) 
THEN UPDATE sim_temp st
	        SET
				a2_symbol 			= 	@asset_2,	
				a2_price			= 	(SELECT last_close FROM asset_prices WHERE date = st.date AND symbol = @asset_2),
				a2_forex_pair		=	IF(@a2_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
				a2_fx_rate			= 	IF( @a2_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
				a2_portfolio_price	=	CASE 
											WHEN a2_forex_pair = CONCAT(@a2_currency, @portfolio_currency) THEN a2_price * a2_fx_rate
											ELSE a2_price / a2_fx_rate
										END;
	END IF;
/*

a3_symbol 			= 	@asset_3,	
a3_price			= 	(SELECT last_close FROM sim_asset_3_prices sap1 WHERE st.date = sap1.date),
a3_forex_pair		=	IF(@a3_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a3_fx_rate			= 	IF( @a3_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @portfolio_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END,
a4_symbol 			= 	@asset_4,	
a4_price			= 	(SELECT last_close FROM sim_asset_4_prices sap1 WHERE st.date = sap1.date),
a4_forex_pair		=	IF(@a4_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a4_fx_rate			= 	IF( @a4_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @portfolio_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END,
a5_symbol 			= 	@asset_5,	
a5_price			= 	(SELECT last_close FROM sim_asset_5_prices sap1 WHERE st.date = sap1.date),
a5_forex_pair		=	IF(@a5_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a5_fx_rate			= 	IF( @a5_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a5_portfolio_price	=	CASE 
							WHEN a5_forex_pair = CONCAT(@a5_currency, @portfolio_currency) THEN a5_price * a5_fx_rate
                            ELSE a5_price / a5_fx_rate
						END,
a6_symbol 			= 	@asset_6,	
a6_price			= 	(SELECT last_close FROM sim_asset_6_prices sap1 WHERE st.date = sap1.date),
a6_forex_pair		=	IF(@a6_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a6_fx_rate			= 	IF( @a6_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a6_portfolio_price	=	CASE 
							WHEN a6_forex_pair = CONCAT(@a6_currency, @portfolio_currency) THEN a6_price * a6_fx_rate
                            ELSE a6_price / a6_fx_rate
						END,
a7_symbol 			= 	@asset_7,	
a7_price			= 	(SELECT last_close FROM sim_asset_7_prices sap1 WHERE st.date = sap1.date),
a7_forex_pair		=	IF(@a7_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a7_fx_rate			= 	IF( @a7_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a7_portfolio_price	=	CASE 
							WHEN a7_forex_pair = CONCAT(@a7_currency, @portfolio_currency) THEN a7_price * a7_fx_rate
                            ELSE a7_price / a7_fx_rate
						END,
a8_symbol 			= 	@asset_8,	
a8_price			= 	(SELECT last_close FROM sim_asset_8_prices sap1 WHERE st.date = sap1.date),
a8_forex_pair		=	IF(@a8_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a8_fx_rate			= 	IF( @a8_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a8_portfolio_price	=	CASE 
							WHEN a8_forex_pair = CONCAT(@a8_currency, @portfolio_currency) THEN a8_price * a8_fx_rate
                            ELSE a8_price / a8_fx_rate
						END,
a9_symbol 			= 	@asset_9,	
a9_price			= 	(SELECT last_close FROM sim_asset_9_prices sap1 WHERE st.date = sap1.date),
a9_forex_pair		=	IF(@a9_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a9_fx_rate			= 	IF( @a9_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a9_portfolio_price	=	CASE 
							WHEN a9_forex_pair = CONCAT(@a9_currency, @portfolio_currency) THEN a9_price * a9_fx_rate
                            ELSE a9_price / a9_fx_rate
						END,
a10_symbol 			= 	@asset_1,	
a10_price			= 	(SELECT last_close FROM sim_asset_10_prices sap1 WHERE st.date = sap1.date),
a10_forex_pair		=	IF(@a10_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a10_fx_rate			= 	IF( @a10_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a10_portfolio_price	=	CASE 
							WHEN a10_forex_pair = CONCAT(@a10_currency, @portfolio_currency) THEN a10_price * a10_fx_rate
                            ELSE a10_price / a10_fx_rate
						END;*/

END //
;

DELIMITER //
CREATE PROCEDURE first_row_data_insertion()
BEGIN

-- INTRODUCING FIRS ROW VALUES
UPDATE sim_temp
SET 
a1_amount 				= FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @a1_allocation / 100 / a1_portfolio_price), -- CHECK AFTER CHANGES
a1_amount_change		= a1_amount,
a1_portfolio_value		= a1_amount * a1_portfolio_price
WHERE date 				= @start_date;


UPDATE sim_temp
SET 
a2_amount 				= FLOOR(@inicial_balance * COALESCE(@leverage / 100 + 1,1) * @a2_allocation / 100 / a2_portfolio_price), -- CHECK AFTER CHANGES
a2_amount_change		= a2_amount,
a2_portfolio_value		= a2_amount * a2_portfolio_price,


p_value 				= a1_portfolio_value + a2_portfolio_value /*+ a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
						+ a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value*/,
buy 					= a1_portfolio_value + a2_portfolio_value /* + a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
						+ a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value*/,
transaction_costs		= -(IF(a1_amount_change != 0, 1, 0)
							+ IF(a2_amount_change != 0, 1, 0)/*
							+ IF(a3_amount_change != 0, 1, 0)
							+ IF(a4_amount_change != 0, 1, 0)
                            + IF(a5_amount_change != 0, 1, 0)
                            + IF(a6_amount_change != 0, 1, 0)
                            + IF(a7_amount_change != 0, 1, 0)
                            + IF(a8_amount_change != 0, 1, 0)
                            + IF(a9_amount_change != 0, 1, 0)
                            + IF(a10_amount_change != 0, 1, 0)*/) * @p_transaction_cost,
tot_change				= -(a1_portfolio_value + a2_portfolio_value/* + a3_portfolio_value + a4_portfolio_value + a5_portfolio_value
						 + a6_portfolio_value + a7_portfolio_value + a8_portfolio_value + a9_portfolio_value + a10_portfolio_value*/) + transaction_costs,
acc_balance				= @inicial_balance + tot_change,
tot_balance				= p_value + acc_balance,
leverage_rate			= p_value / tot_balance,

a1_allocation 			= (a1_portfolio_value / (tot_balance*((@leverage+100)/100))),
a2_allocation 			= (a2_portfolio_value / (tot_balance*((@leverage+100)/100)))
/*
a3_allocation 			= (a3_portfolio_value / (tot_balance*((@leverage+100)/100))),
a4_allocation 			= (a4_portfolio_value / (tot_balance*((@leverage+100)/100))),
a5_allocation 			= (a5_portfolio_value / (tot_balance*((@leverage+100)/100))),
a6_allocation 			= (a6_portfolio_value / (tot_balance*((@leverage+100)/100))),
a7_allocation 			= (a7_portfolio_value / (tot_balance*((@leverage+100)/100))),
a8_allocation 			= (a8_portfolio_value / (tot_balance*((@leverage+100)/100))),
a9_allocation 			= (a9_portfolio_value / (tot_balance*((@leverage+100)/100))),
a10_allocation 			= (a10_portfolio_value / (tot_balance*((@leverage+100)/100)))*/
WHERE date 				= @start_date;

ALTER TABLE sim_temp
ADD INDEX idx_date(date);

END //


DELIMITER //
CREATE PROCEDURE sim_relative_looper() -- Creating the portfolio simulation day by day
BEGIN

DECLARE outer_counter INT DEFAULT 1;
DECLARE inner_counter INT DEFAULT 1; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date     DATE DEFAULT ADDDATE((SELECT MAX(date) FROM sim_temp GROUP BY date), 1);

CREATE TABLE sim_looper LIKE sim_temp;

-- START THE OUTER LOOP TO INTRODUCE A NEW BATCH AND THEN LOOP THROUH IT IN THE INNER LOOP
-- INTRODUCE NEW BATCH 

-- SETTING THE COUNTER FOR THE OUTER LOOP TO THE TOTAL DAYS DEVIDED BY BATCH SIZE ROUNDING UP (AND LATER DELETING ROWS WITH NULL VALUES)

WHILE outer_counter <= CEILING((DATEDIFF(@last_date, @first_date)-1)/@batch_size) DO

SET @max_date = (SELECT date FROM sim_temp ORDER BY date DESC LIMIT 1);

-- INSERT LAST ROW FROM EXISTING DATA IN TABLE
INSERT INTO sim_looper 
	 SELECT * 
       FROM sim_temp 
	  WHERE date = @max_date; 

-- INSERT BATCHSIZE DATES
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
a1_price			= 	(SELECT last_close FROM sim_asset_1_prices sap1 WHERE st.date = sap1.date),
a1_forex_pair		=	IF(@a1_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a1_fx_rate			= 	IF( @a1_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a1_portfolio_price	=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @portfolio_currency) THEN a1_price * a1_fx_rate
                            ELSE a1_price / a1_fx_rate
						END,
a2_symbol 			= 	@asset_2,	
a2_price			= 	(SELECT last_close FROM sim_asset_2_prices sap1 WHERE st.date = sap1.date),
a2_forex_pair		=	IF(@a2_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a2_fx_rate			= 	IF( @a2_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a2_portfolio_price	=	CASE 
							WHEN a2_forex_pair = CONCAT(@a2_currency, @portfolio_currency) THEN a2_price * a2_fx_rate
                            ELSE a2_price / a2_fx_rate
						END,
a3_symbol 			= 	@asset_3,	
a3_price			= 	(SELECT last_close FROM sim_asset_3_prices sap1 WHERE st.date = sap1.date),
a3_forex_pair		=	IF(@a3_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a3_fx_rate			= 	IF( @a3_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a3_portfolio_price	=	CASE 
							WHEN a3_forex_pair = CONCAT(@a3_currency, @portfolio_currency) THEN a3_price * a3_fx_rate
                            ELSE a3_price / a3_fx_rate
						END,
a4_symbol 			= 	@asset_4,	
a4_price			= 	(SELECT last_close FROM sim_asset_4_prices sap1 WHERE st.date = sap1.date),
a4_forex_pair		=	IF(@a4_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a4_fx_rate			= 	IF( @a4_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a4_portfolio_price	=	CASE 
							WHEN a4_forex_pair = CONCAT(@a4_currency, @portfolio_currency) THEN a4_price * a4_fx_rate
                            ELSE a4_price / a4_fx_rate
						END,
a5_symbol 			= 	@asset_5,	
a5_price			= 	(SELECT last_close FROM sim_asset_5_prices sap1 WHERE st.date = sap1.date),
a5_forex_pair		=	IF(@a5_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a5_fx_rate			= 	IF( @a5_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a5_portfolio_price	=	CASE 
							WHEN a5_forex_pair = CONCAT(@a5_currency, @portfolio_currency) THEN a5_price * a5_fx_rate
                            ELSE a5_price / a5_fx_rate
						END,
a6_symbol 			= 	@asset_6,	
a6_price			= 	(SELECT last_close FROM sim_asset_6_prices sap1 WHERE st.date = sap1.date),
a6_forex_pair		=	IF(@a6_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a6_fx_rate			= 	IF( @a6_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a6_portfolio_price	=	CASE 
							WHEN a6_forex_pair = CONCAT(@a6_currency, @portfolio_currency) THEN a6_price * a6_fx_rate
                            ELSE a6_price / a6_fx_rate
						END,
a7_symbol 			= 	@asset_7,	
a7_price			= 	(SELECT last_close FROM sim_asset_7_prices sap1 WHERE st.date = sap1.date),
a7_forex_pair		=	IF(@a7_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a7_fx_rate			= 	IF( @a7_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a7_portfolio_price	=	CASE 
							WHEN a7_forex_pair = CONCAT(@a7_currency, @portfolio_currency) THEN a7_price * a7_fx_rate
                            ELSE a7_price / a7_fx_rate
						END,
a8_symbol 			= 	@asset_8,	
a8_price			= 	(SELECT last_close FROM sim_asset_8_prices sap1 WHERE st.date = sap1.date),
a8_forex_pair		=	IF(@a8_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a8_fx_rate			= 	IF( @a8_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a8_portfolio_price	=	CASE 
							WHEN a8_forex_pair = CONCAT(@a8_currency, @portfolio_currency) THEN a8_price * a8_fx_rate
                            ELSE a8_price / a8_fx_rate
						END,
a9_symbol 			= 	@asset_9,	
a9_price			= 	(SELECT last_close FROM sim_asset_9_prices sap1 WHERE st.date = sap1.date),
a9_forex_pair		=	IF(@a9_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a9_fx_rate			= 	IF( @a9_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a9_portfolio_price	=	CASE 
							WHEN a9_forex_pair = CONCAT(@a9_currency, @portfolio_currency) THEN a9_price * a9_fx_rate
                            ELSE a9_price / a9_fx_rate
						END,
a10_symbol 			= 	@asset_1,	
a10_price			= 	(SELECT last_close FROM sim_asset_10_prices sap1 WHERE st.date = sap1.date),
a10_forex_pair		=	IF(@a10_currency = @portfolio_currency, @portfolio_currency, (SELECT forex_pair FROM sim_forex_pair)),
a10_fx_rate			= 	IF( @a10_currency = @portfolio_currency, 1, (SELECT last_close FROM sim_forex_prices WHERE date = st.date)),
a10_portfolio_price	=	CASE 
							WHEN a10_forex_pair = CONCAT(@a10_currency, @portfolio_currency) THEN a10_price * a10_fx_rate
                            ELSE a10_price / a10_fx_rate
						END;
-- CREATING THE INNER LOOP

WHILE inner_counter <= @batch_size AND loop_date <= @last_date DO
		
        -----------------------------------------------------------------------------
UPDATE sim_looper t1
JOIN (
SELECT 
date, 
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
LAG(a4_allocation) OVER (ORDER BY date) a4_prev_allocation
LAG(a5_allocation) OVER (ORDER BY date) a5_prev_allocation,
LAG(a6_allocation) OVER (ORDER BY date) a6_prev_allocation,
LAG(a7_allocation) OVER (ORDER BY date) a7_prev_allocation,
LAG(a8_allocation) OVER (ORDER BY date) a8_prev_allocation
LAG(a9_allocation) OVER (ORDER BY date) a9_prev_allocation,
LAG(a10_allocation) OVER (ORDER BY date) a10_prev_allocation
FROM sim_looper
) t2
ON t1.date = t2.date
SET -----------------------------------------------------------------------------------------
t1.a1_amount 				= IF(((SELECT close FROM sim_asset_1_prices WHERE date = t1.date) IS NOT NULL
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









