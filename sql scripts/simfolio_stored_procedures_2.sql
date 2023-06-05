-- The procedure to be loaded in the beginning, when starting up the db:
DELIMITER //
CREATE PROCEDURE load_basics()
BEGIN 

	SET @inicial_balance 		=	100000;
	SET @batch_size		 		=	10;
	SET @interest_augment		=	1;			-- INTEREST AUGMENTATION OF RFR + _% -- out of sight, because its explenation is out of scope
    SET @portfolio_name			= 	'Standard';
    set @strategy_id			=	1;
    
    -- These procedures make sure all tables have their relevant data in place
    CALL inception_update();
	CALL end_date_update();		
	CALL last_close_price_update();
	CALL last_close_forex_update();
            
END //
;

DELIMITER //
CREATE PROCEDURE run_simulation()
BEGIN

CALL prepare_sim_variables();			
CALL prepare_sim_forex_data();			
CALL sim_table_creation();

IF @rebalancing_type = 'Period'
	THEN CALL first_periodic_data(); 		
		 CALL sim_periodic_looper(@period);
    ELSE CALL first_row_data();
		 CALL sim_relative_looper();
END IF;		

CALL sim_final_data_population;
CALL performance_metrics_calculation();

END //




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

DELIMITER //
CREATE PROCEDURE last_close_forex_update()
BEGIN

DECLARE n INT DEFAULT 0;

DROP TABLE IF EXISTS forex_prices_update;

CREATE TABLE forex_prices_update LIKE forex_prices;

WHILE n < (SELECT COUNT(DISTINCT forex_pair) FROM forex_prices) DO

INSERT INTO forex_prices_update
SELECT c.date, (SELECT DISTINCT forex_pair FROM forex_prices GROUP BY forex_pair LIMIT 1 OFFSET n) forex_pair, 
			   (SELECT data_provider FROM forex_prices WHERE forex_pair = (SELECT DISTINCT forex_pair FROM forex_prices GROUP BY forex_pair LIMIT 1 OFFSET n) LIMIT 1) data_provider,
			   open, high, low, close,
		IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
											 (LAG(close,2) OVER (ORDER BY c.date)),
											 (LAG(close,3) OVER (ORDER BY c.date)),
											 (LAG(close,4) OVER (ORDER BY c.date)),
											 (LAG(close,5) OVER (ORDER BY c.date)))) last_close
FROM calendar c                       
  LEFT JOIN  (SELECT date, forex_pair, data_provider, open, high, low, close
			    FROM forex_prices
			   WHERE forex_pair = (SELECT DISTINCT forex_pair FROM forex_prices GROUP BY forex_pair LIMIT 1 OFFSET n)) forex_pair             
	     ON forex_pair.date = c.date
	  WHERE c.date BETWEEN (SELECT date FROM forex_prices WHERE forex_pair = (SELECT DISTINCT forex_pair FROM forex_prices GROUP BY forex_pair LIMIT 1 OFFSET n) ORDER BY date ASC LIMIT 1)
					   AND (SELECT date FROM forex_prices WHERE forex_pair = (SELECT DISTINCT forex_pair FROM forex_prices GROUP BY forex_pair LIMIT 1 OFFSET n) ORDER BY date DESC LIMIT 1);


SET n = n + 1;

END WHILE;

DELETE 
FROM forex_prices;

INSERT INTO forex_prices
SELECT *
FROM forex_prices_update;

DROP TABLE forex_prices_update;


END //
;

-- The procedure inception_date makes sure that the asset table column inception_date contains in the first date available 
-- from the respective asset in the asset_prices table by updating every column that has a NULL value in thet column.
DELIMITER //
CREATE PROCEDURE inception_update()
BEGIN

DECLARE n INT DEFAULT 0;

DROP TABLE IF EXISTS asset_temp; 

CREATE TABLE asset_temp AS
SELECT* FROM asset;

 WHILE  n <= (SELECT COUNT(symbol) FROM asset_temp WHERE inception_date IS NULL) DO

		UPDATE asset
		   SET inception_date 	=  (SELECT date 
									  FROM asset_prices 
									 WHERE symbol = 	(SELECT symbol 
														   FROM asset_temp 
														  WHERE inception_date IS NULL 
													   ORDER BY symbol 
                                                          LIMIT 1 
														 OFFSET n)
								  ORDER BY date ASC 
									 LIMIT 1)
		WHERE  symboL		    = 	(SELECT symbol 
									   FROM asset_temp 
									  WHERE inception_date IS NULL 
								   ORDER BY symbol 
									  LIMIT 1 
									 OFFSET n);

		   SET n = n + 1;
END WHILE;

END//
;

DELIMITER //
CREATE PROCEDURE end_date_update()
BEGIN

DECLARE n INT DEFAULT 0;

DROP TABLE IF EXISTS asset_temp; 

CREATE TABLE asset_temp AS
SELECT* FROM asset;

-- As opposed to the inception date, the end date will keep changing after each price udate, 
-- so I will not make it depend on an existing end_date, but update all end_dates straight away. 

WHILE  n <= (SELECT COUNT(symbol) FROM asset_temp) DO

		UPDATE asset
		   SET end_date		 	=  (SELECT date 
									  FROM asset_prices 
									 WHERE symbol = 	(SELECT symbol 
														   FROM asset_temp 
													   ORDER BY symbol 
                                                          LIMIT 1 
														 OFFSET n)
								  ORDER BY date DESC 
									 LIMIT 1)
		WHERE  symboL		    = 	(SELECT symbol 
									   FROM asset_temp 
								   ORDER BY symbol 
									  LIMIT 1 
									 OFFSET n);

		   SET n = n + 1;
END WHILE;

END//
;

/* 
The following procedure creates a new portfolio in the portfolio table, if the name is not taken yet. 
If it's taken it just displays that fact as a message in results table. 

If it's not taken it goes on to create it and the respective assets and allocations, 
making sure that no assets are stored for a portfolio t
*/
DELIMITER //
CREATE PROCEDURE portfolio_change()
BEGIN


IF @portfolio_name IN (SELECT portfolio_name FROM portfolio) 
                            
				        THEN SELECT('Portfolio name taken') MESSAGE_FOR_YOU;
					    ELSE SET @portfolio_id = (SELECT max(portfolio_id) +1 FROM portfolio),
							     @strategy_id  = (SELECT strategy_id FROM strategy WHERE strategy_name = @strategy_name);
							 INSERT INTO 	portfolio (portfolio_id, portfolio_name, portfolio_currency, portfolio_strategy, portfolio_transaction_cost)
							      VALUES 	(@portfolio_id, @portfolio_name, @portfolio_currency, @strategy_id, @portfolio_transaction_cost);
					
								 IF 		@asset_1 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_1, @asset_1_allocation);
								 END IF;
								 IF 		@asset_2 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_2, @asset_2_allocation);
								 END IF;
								 IF 		@asset_3 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_3, @asset_3_allocation);
								 END IF;
								 IF 		@asset_4 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_4, @asset_4_allocation);
								 END IF;
								 IF 		@asset_5 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_5, @asset_5_allocation);
								 END IF;
								 IF 		@asset_6 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_6, @asset_6_allocation);
								 END IF;
								 IF 		@asset_7 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_7, @asset_7_allocation);
								 END IF;
								 IF 		@asset_8 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_8, @asset_8_allocation);
								 END IF;
								 IF 		@asset_9 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_9, @asset_9_allocation);
								 END IF;
								 IF 		@asset_10 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_id, @asset_10, @asset_10_allocation);
								 END IF;
			END IF;
              
END//
;

DELIMITER //
CREATE PROCEDURE strategy_change()
BEGIN



    IF @strategy_name IN 	(SELECT strategy_name FROM strategy) 
                            THEN SELECT('Strategy name taken') MESSAGE_FOR_YOU;
	ELSE      		 SET 	@strategy_id = (SELECT max(strategy_id) + 1 FROM strategy);
			 INSERT INTO 	strategy (strategy_id, strategy_name, rebalancing_type, leverage, lev_rebalancing)
			      VALUES 	(@strategy_id, @strategy_name, @rebalancing_type, @leverage, @leverage_rebalancing);
			      				
                      IF	@rebalancing_type 		= 'deviation'
                    THEN	UPDATE strategy
							   SET rel_rebalancing 	= @rel_rebalancing,		
							       min_rebalancing 	= @min_rebalancing
							 WHERE strategy_name   	= @strategy_name;
				  END IF;
                  
					  IF	@rebalancing_type 		= 'period'
                    THEN	UPDATE strategy
							   SET perio 	  		= @period
							 WHERE strategy_name   	= @strategy_name;
				  END IF;                            
    END IF;               
END//
;

DELIMITER //
-- Creating a Procedure to load all the variables 
CREATE PROCEDURE prepare_sim_variables()
BEGIN
	
-- First we load the all the variables according to the chosen portfolio, 
-- in case it was not newly created they would not have been loaded yet. 

    IF  (SELECT COUNT(*) FROM simulation) = 0
        THEN SET @sim_id = 1;
        ELSE SET @sim_id = (SELECT max(sim_id) + 1 FROM simulation);
END IF;

SET 
@sim_timestamp 				= current_timestamp();

SET     					-- 	Setting the variables from the portfolio table
@portfolio_currency 		= 	(SELECT portfolio_currency FROM portfolio WHERE portfolio_name = @portfolio_name),
@portfolio_transaction_cost	=	(SELECT portfolio_transaction_cost FROM portfolio WHERE portfolio_name = @portfolio_name),
@portfolio_strategy			=	(SELECT portfolio_strategy FROM portfolio WHERE portfolio_name = @portfolio_name),
@portfolio_id				=	(SELECT portfolio_id FROM portfolio WHERE portfolio_name = @portfolio_name);


SET							-- 	Setting the variables from the strategy table
@strategy_id				=	(SELECT portfolio_strategy FROM portfolio WHERE portfolio_name = @portfolio_name),
@rebalancing_type			=	(SELECT rebalancing_type FROM strategy WHERE strategy_id = @portfolio_strategy),
@period						=	(SELECT period FROM strategy WHERE strategy_id = @portfolio_strategy),	
@leverage					=	(SELECT leverage FROM strategy WHERE strategy_id = @portfolio_strategy),
@lev_rebalancing			=	(SELECT lev_rebalancing	FROM strategy WHERE strategy_id = @portfolio_strategy),	
@min_rebalancing			=	(SELECT min_rebalancing	FROM strategy WHERE strategy_id = @portfolio_strategy),
@rel_rebalancing			=	(SELECT rel_rebalancing	FROM strategy WHERE strategy_id = @portfolio_strategy);

SET							-- 	Setting the variables from the portfolio assets table. Assets will be named 1-10 according to their allocation. 
@asset_1 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 0), 
@asset_2 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 1),
@asset_3 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 2),
@asset_4 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 3),
@asset_5 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 4),
@asset_6 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 5),
@asset_7 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 6),
@asset_8 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 7),
@asset_9 				= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 8),
@asset_10		 		= (SELECT symbol FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 9),
@asset_1_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 0), 
@asset_2_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 1),
@asset_3_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 2),
@asset_4_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 3),
@asset_5_allocation 	= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 4),
@asset_6_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 5),
@asset_7_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 6),
@asset_8_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 7),
@asset_9_allocation		= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 8),
@asset_10_allocation	= (SELECT allocation FROM portfolio_asset WHERE portfolio_id = @portfolio_id ORDER BY allocation DESC LIMIT 1 OFFSET 9),
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
									   WHERE portfolio_id = @portfolio_id));
 
  SET @end_date =  (SELECT MIN(end_date)
					  FROM asset
					 WHERE symbol IN (SELECT symbol 
                                        FROM portfolio_asset 
									   WHERE portfolio_id = @portfolio_id));

END //
;

-- Here I need to change the structure to be the same as in the assets
DELIMITER//
CREATE PROCEDURE prepare_sim_forex_data()
BEGIN

-- Here I will collect all the tables that are being created in the simulation
-- In the meanwhile I will comment them out, to prevent redundant droppings.    
    
DROP TABLE IF EXISTS sim_currencies;
DROP TABLE IF EXISTS sim_forex_pair;


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
 
END//
;

DELIMITER //
CREATE PROCEDURE sim_table_creation() -- Creating the table and filling in date and price data 
BEGIN

INSERT INTO simulation (sim_id, timestamp, portfolio_id, strategy_id, start_date, end_date)
VALUES (@sim_id, @sim_timestamp, @portfolio_id, @strategy_id, @start_date, @end_date);

DROP TABLE IF EXISTS sim_temp; 

CREATE TABLE sim_temp ( -- Temporary table for a simulation
    sim_id INT NULL,
    portfolio_id VARCHAR(100) NULL,
    strategy_id VARCHAR(100) NULL,
    sim_timestamp TIMESTAMP NULL,
    
    date DATE PRIMARY KEY,
        
   	a1_symbol VARCHAR(20), a1_price FLOAT DEFAULT 1, a1_forex_pair VARCHAR(10), a1_fx_rate FLOAT, a1_portfolio_price FLOAT,
    a1_amount INT DEFAULT 0, a1_amount_change INT, a1_local_value FLOAT, a1_portfolio_value FLOAT, 
	a1_local_change_d FLOAT, a1_portfolio_change_d FLOAT,
    
	a2_symbol VARCHAR(20), a2_price FLOAT DEFAULT 1, a2_forex_pair VARCHAR(10), a2_fx_rate FLOAT, a2_portfolio_price FLOAT,
    a2_amount INT DEFAULT 0, a2_amount_change INT, a2_local_value FLOAT, a2_portfolio_value FLOAT, 
	a2_local_change_d FLOAT, a2_portfolio_change_d FLOAT,

	a3_symbol VARCHAR(20), a3_price FLOAT DEFAULT 1, a3_forex_pair VARCHAR(10), a3_fx_rate FLOAT, a3_portfolio_price FLOAT,
    a3_amount INT DEFAULT 0, a3_amount_change INT, a3_local_value FLOAT, a3_portfolio_value FLOAT, 
	a3_local_change_d FLOAT, a3_portfolio_change_d FLOAT,

	a4_symbol VARCHAR(20), a4_price FLOAT DEFAULT 1, a4_forex_pair VARCHAR(10), a4_fx_rate FLOAT, a4_portfolio_price FLOAT,
    a4_amount INT DEFAULT 0, a4_amount_change INT, a4_local_value FLOAT, a4_portfolio_value FLOAT, 
	a4_local_change_d FLOAT, a4_portfolio_change_d FLOAT,

	a5_symbol VARCHAR(20), a5_price FLOAT DEFAULT 1, a5_forex_pair VARCHAR(10), a5_fx_rate FLOAT, a5_portfolio_price FLOAT,
    a5_amount INT DEFAULT 0, a5_amount_change INT, a5_local_value FLOAT, a5_portfolio_value FLOAT, 
	a5_local_change_d FLOAT, a5_portfolio_change_d FLOAT,

	a6_symbol VARCHAR(20), a6_price FLOAT DEFAULT 1, a6_forex_pair VARCHAR(10), a6_fx_rate FLOAT, a6_portfolio_price FLOAT,
    a6_amount INT DEFAULT 0, a6_amount_change INT, a6_local_value FLOAT, a6_portfolio_value FLOAT, 
	a6_local_change_d FLOAT, a6_portfolio_change_d FLOAT,

	a7_symbol VARCHAR(20), a7_price FLOAT DEFAULT 1, a7_forex_pair VARCHAR(10), a7_fx_rate FLOAT, a7_portfolio_price FLOAT,
    a7_amount INT DEFAULT 0, a7_amount_change INT, a7_local_value FLOAT, a7_portfolio_value FLOAT, 
	a7_local_change_d FLOAT, a7_portfolio_change_d FLOAT,

	a8_symbol VARCHAR(20), a8_price FLOAT DEFAULT 1, a8_forex_pair VARCHAR(10), a8_fx_rate FLOAT, a8_portfolio_price FLOAT,
    a8_amount INT DEFAULT 0, a8_amount_change INT, a8_local_value FLOAT, a8_portfolio_value FLOAT, 
	a8_local_change_d FLOAT, a8_portfolio_change_d FLOAT,

	a9_symbol VARCHAR(20), a9_price FLOAT DEFAULT 1, a9_forex_pair VARCHAR(10), a9_fx_rate FLOAT, a9_portfolio_price FLOAT,
    a9_amount INT DEFAULT 0, a9_amount_change INT, a9_local_value FLOAT, a9_portfolio_value FLOAT, 
	a9_local_change_d FLOAT, a9_portfolio_change_d FLOAT,

	a10_symbol VARCHAR(20), a10_price FLOAT DEFAULT 1, a10_forex_pair VARCHAR(10), a10_fx_rate FLOAT, a10_portfolio_price FLOAT,
    a10_amount INT DEFAULT 0, a10_amount_change INT, a10_local_value FLOAT, a10_portfolio_value FLOAT, 
	a10_local_change_d FLOAT, a10_portfolio_change_d FLOAT,
    
	a1_allocation FLOAT,
    a2_allocation FLOAT,
    a3_allocation FLOAT,
    a4_allocation FLOAT,
	a5_allocation FLOAT,
    a6_allocation FLOAT,
    a7_allocation FLOAT,
    a8_allocation FLOAT,
	a9_allocation FLOAT,
    a10_allocation FLOAT,
    
-- ADDING ACCOUNT METRICS
	p_value FLOAT,
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
	tot_balance_change_d FLOAT);

END//
;

DELIMITER //
CREATE PROCEDURE first_row_data()
BEGIN

-- Introducing all known data into the simulation tables' first row
-- First the calendar dates

INSERT INTO sim_temp (date)
	 SELECT date 
	   FROM calendar
      WHERE date = @start_date;

-- Secondly, all the lookup data and stored values
UPDATE sim_temp st
SET
sim_id 				= 	@sim_id,
portfolio_id 		=	@portfolio_id,
strategy_id 		= 	@strategy_id,
sim_timestamp		=	@sim_timestamp,    

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
CREATE PROCEDURE performance_metrics_calculation()
BEGIN
INSERT INTO simulation_data
SELECT* FROM portfolio_simulation;

INSERT INTO sim_performance_monthly (sim_id, month, year)
	 SELECT @sim_id, month, year
       FROM (SELECT DISTINCT CONCAT(year(date), '-', month(date)), 
							 month(date) AS month, 
						     year(date) AS year
					    FROM portfolio_simulation) t2;

UPDATE sim_performance_monthly
SET sim_id 	      = @sim_id,
    period_return = (SELECT (t2.end_value/t1.start_value-1)*100
				    FROM (SELECT date, tot_balance / (tot_balance_change_d/100 + 1) AS start_value -- calculating the previous days closing as a starting value
							FROM portfolio_simulation
							WHERE month(date) = sim_performance_monthly.month -- p_sim_performance_m.month
							AND year(date)=	sim_performance_monthly.year
							ORDER BY date ASC
							LIMIT 1) t1 
					JOIN
					(SELECT date, tot_balance AS end_value
					FROM portfolio_simulation
							WHERE month(date) = sim_performance_monthly.month -- p_sim_performance_m.month
							AND year(date)=	sim_performance_monthly.year
							ORDER BY date DESC
							LIMIT 1) t2),                          
    period_rfr   = (SELECT AVG(last_rate)/12*100
					FROM econ_indicator_values t1
					WHERE month(date) = sim_performance_monthly.month -- p_sim_performance_m.month
					AND year(date)=	sim_performance_monthly.year),                 
	maximum_dd    = (SELECT min(dd)*100 
					   FROM (SELECT date, 
						   		    tot_balance, 
								    max(tot_balance) OVER (ORDER BY date) AS max_value, 
								    (tot_balance /  max(tot_balance) OVER (ORDER BY date)) - 1 AS dd
						     FROM portfolio_simulation
						     WHERE tot_balance IS NOT NULL
						     AND month(date) = sim_performance_monthly.month
						     AND year(date)  =	sim_performance_monthly.year) dd_series),
	standard_dev  = (SELECT STDDEV(tot_balance_change_d) * SQRT(COUNT(t1.date)) 
					FROM portfolio_simulation t1
					INNER JOIN (SELECT date, is_weekday
								FROM calendar c) t2
					ON t2.date = t1.date
					WHERE month(t1.date) = sim_performance_monthly.month --  p_sim_performance_m.month
					AND year(t1.date)=	sim_performance_monthly.year
					AND is_weekday = 1),
	var			  = (SELECT VARIANCE(tot_balance_change_d/100)
					FROM portfolio_simulation
					WHERE month(date) = sim_performance_monthly.month --  p_sim_performance_m.month
					AND year(date)=	sim_performance_monthly.year),
	sharp_ratio   = (period_return - period_rfr) / standard_dev,
    sortino_ratio = (period_return - period_rfr) / 
					(SELECT STDDEV(tot_balance_change_d) * SQRT(COUNT(date)) 
					FROM portfolio_simulation
					WHERE month(date) = sim_performance_monthly.month --  p_sim_performance_m.month
					AND year(date)=	sim_performance_monthly.year
					AND tot_balance_change_d < 0) 
WHERE sim_id = @sim_id;


INSERT INTO sim_performance_yearly (sim_id, year)
	 SELECT @sim_id, YEAR(date) AS year
	   FROM portfolio_simulation
   GROUP BY year(date)
	 HAVING COUNT(DISTINCT MONTH(date)) = 12;

UPDATE sim_performance_yearly
   SET 	period_return = (SELECT (t2.end_value/t1.start_value-1)*100
					       FROM (SELECT date, tot_balance / (tot_balance_change_d/100 + 1) AS start_value -- calculating the previous days closing as a starting value
							       FROM portfolio_simulation
								  WHERE year(date) = sim_performance_yearly.year
							   ORDER BY date ASC
								  LIMIT 1) t1 
						   JOIN  (SELECT date, 
									   tot_balance AS end_value
								    FROM portfolio_simulation
								   WHERE year(date) = sim_performance_yearly.year
							    ORDER BY date DESC
								   LIMIT 1) t2),   
		period_rfr    = (SELECT AVG(last_rate)
						   FROM econ_indicator_values t1
						  WHERE year(t1.date) = sim_performance_yearly.year),
		maximum_dd    = (SELECT min(dd) * 100
						   FROM 	(SELECT date, 
											tot_balance, 
											max(tot_balance) OVER (ORDER BY date) AS max_value, 
											(tot_balance /  max(tot_balance) OVER (ORDER BY date)) - 1 AS dd
									  FROM 	portfolio_simulation
									 WHERE 	tot_balance IS NOT NULL
									   AND 	year(date) = sim_performance_yearly.year) dd_series),
		standard_dev  = (SELECT STDDEV(tot_balance_change_d) * SQRT(COUNT(date)) 
						   FROM portfolio_simulation
						  WHERE tot_balance IS NOT NULL
						    AND year(date)=	sim_performance_yearly.year),
		sharp_ratio   = (period_return - period_rfr) / standard_dev,
		sortino_ratio = (period_return - period_rfr) / 
						(SELECT STDDEV(tot_balance_change_d) * SQRT(COUNT(date)) 
					       FROM portfolio_simulation
						  WHERE year(date)= sim_performance_yearly.year
						    AND tot_balance_change_d < 0)
WHERE sim_id = @sim_id;                        
                        
         
UPDATE simulation
   SET tot_return 					=	((SELECT tot_balance 
										    FROM portfolio_simulation 
										   WHERE date = @end_date) / @inicial_balance -1) *100,
	   medium_annual_return 		=	 (SELECT AVG(period_return)
									        FROM sim_performance_yearly
										   WHERE sim_id = @sim_id),
	   medium_rfr 					=	 (SELECT AVG(last_rate)
										    FROM econ_indicator_values
										   WHERE date BETWEEN @start_date AND @end_date),
	   maximum_dd 					=	 (SELECT min(dd) * 100
										    FROM (SELECT date, 
														tot_balance, 
														max(tot_balance) OVER (ORDER BY date) AS max_value, 
														(tot_balance /  max(tot_balance) OVER (ORDER BY date)) - 1 AS dd
												   FROM portfolio_simulation
												  WHERE tot_balance IS NOT NULL) dd_series),
	   standard_dev_annual_mean 	=	 (SELECT AVG(standard_dev)
									        FROM sim_performance_yearly
										   WHERE sim_id = @sim_id),
	   sharp_ratio_annual_mean 		=	 (SELECT AVG(sharp_ratio)
									        FROM sim_performance_yearly
										   WHERE sim_id = @sim_id),
	   sortino_ratio_annual_mean	= 	 (SELECT AVG(sortino_ratio)
									        FROM sim_performance_yearly
										   WHERE sim_id = @sim_id)
WHERE sim_id = @sim_id;                             

SELECT* FROM simulation;

SELECT 'SIMULATION RESULTS' AS 'SIMULATION', 
	   sim_id AS Simulation_ID, 
       start_date AS 'Start', 
       end_date AS 'End', 
       CONCAT(ROUND(tot_return, 2),'%') AS 'Total Return',
       CONCAT(ROUND(medium_annual_return, 2),'%') AS 'Medium Annual Return',
       CONCAT(ROUND(maximum_dd, 2),'%') AS 'Maximum Drawdown',
       ROUND(standard_dev_annual_mean, 2) AS 'Standard Deviation',
       ROUND(sharp_ratio_annual_mean, 2) AS 'Sharp Ratio',
       ROUND(sortino_ratio_annual_mean, 2) AS 'Sortino Ratio'
  FROM simulation
 WHERE sim_id = @sim_id;

END//
;

DELIMITER //
CREATE PROCEDURE sim_relative_looper() -- Creating the portfolio simulation day by day
BEGIN

DECLARE outer_counter INT DEFAULT 1;
DECLARE inner_counter INT DEFAULT 1; -- SETTING THE INICIAL COUNTER TO TWO BECAUSE THERE WILL BE ONE DATE IN THE TABLE ALREADY
DECLARE loop_date     DATE DEFAULT ADDDATE((SELECT MAX(date) FROM sim_temp GROUP BY date), 1);

DROP TABLE IF EXISTS sim_looper;
CREATE TABLE sim_looper LIKE sim_temp;

-- START THE OUTER LOOP TO INTRODUCE A NEW BATCH AND THEN LOOP THROUH IT IN THE INNER LOOP
-- INTRODUCE NEW BATCH 

-- SETTING THE COUNTER FOR THE OUTER LOOP TO THE TOTAL DAYS DEVIDED BY BATCH SIZE ROUNDING UP (AND LATER DELETING ROWS WITH NULL VALUES)

WHILE outer_counter <= CEILING((DATEDIFF(@end_date, @start_date)-1)/@batch_size) DO

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
sim_id 				= 	@sim_id,
portfolio_id 		=	@portfolio_id,
strategy_id 		= 	@strategy_id,
sim_timestamp		=	@sim_timestamp,    

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
-- CREATING THE INNER LOOP

WHILE inner_counter <= @batch_size AND loop_date <= @end_date DO
		
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
t1.a1_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
									  AND symbol = @asset_1) IS NOT NULL
									  AND ((ABS(t2.a1_prev_allocation * 100 - @asset_1_allocation) / @asset_1_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a1_prev_allocation * 100 - @asset_1_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_1_allocation / 100 / a1_portfolio_price),
									      t2.prev_a1_amount),                         										                                   
t1.a2_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_2) IS NOT NULL
									  AND ((ABS(t2.a2_prev_allocation * 100 - @asset_2_allocation) / @asset_2_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a2_prev_allocation * 100 - @asset_2_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_2_allocation / 100 / a2_portfolio_price),
									      t2.prev_a2_amount),
t1.a3_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_3) IS NOT NULL
									  AND ((ABS(t2.a3_prev_allocation * 100 - @asset_3_allocation) / @asset_3_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a3_prev_allocation * 100 - @asset_3_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_3_allocation / 100 / a3_portfolio_price),
									      t2.prev_a3_amount),
t1.a4_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_4) IS NOT NULL
									  AND ((ABS(t2.a4_prev_allocation * 100 - @asset_4_allocation) / @asset_4_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a4_prev_allocation * 100 - @asset_4_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_4_allocation / 100 / a4_portfolio_price),
									      t2.prev_a4_amount),
t1.a5_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_5) IS NOT NULL
									  AND ((ABS(t2.a5_prev_allocation * 100 - @asset_5_allocation) / @asset_5_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a5_prev_allocation * 100 - @asset_5_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_5_allocation / 100 / a5_portfolio_price),
									      t2.prev_a5_amount),
t1.a6_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_6) IS NOT NULL
									  AND ((ABS(t2.a6_prev_allocation * 100 - @asset_6_allocation) / @asset_6_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a6_prev_allocation * 100 - @asset_6_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_6_allocation / 100 / a6_portfolio_price),
									      t2.prev_a6_amount),
t1.a7_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_7) IS NOT NULL
									  AND ((ABS(t2.a7_prev_allocation * 100 - @asset_7_allocation) / @asset_7_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a7_prev_allocation * 100 - @asset_7_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_7_allocation / 100 / a7_portfolio_price),
									      t2.prev_a7_amount),
t1.a8_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_8) IS NOT NULL
									  AND ((ABS(t2.a8_prev_allocation * 100 - @asset_8_allocation) / @asset_8_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a8_prev_allocation * 100 - @asset_8_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_8_allocation / 100 / a8_portfolio_price),
									      t2.prev_a8_amount),
t1.a9_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_9) IS NOT NULL
									  AND ((ABS(t2.a9_prev_allocation * 100 - @asset_9_allocation) / @asset_9_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a9_prev_allocation * 100 - @asset_9_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
									      FLOOR(t2.prev_tot_balance * COALESCE(@leverage / 100 + 1, 1) * @asset_9_allocation / 100 / a9_portfolio_price),
									      t2.prev_a9_amount),
t1.a10_amount 				= IF(((SELECT close 
									 FROM asset_prices 
									WHERE date = t1.date
                                      AND symbol = @asset_10) IS NOT NULL
									  AND ((ABS(t2.a10_prev_allocation * 100 - @asset_10_allocation) / @asset_10_allocation >= @rel_rebalancing / 100 
									  AND ABS(t2.a10_prev_allocation * 100 - @asset_10_allocation) >= @min_rebalancing)
									   OR ABS(prev_leverage_rate *100 - @leverage) >= @lev_rebalancing)),
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
t1.acc_balance				=	t2.prev_acc_balance + tot_change,
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

END //
;

DELIMITER //
CREATE PROCEDURE sim_final_data_population() -- Filling the table with the remaining data based on the simulation data
BEGIN

DROP TABLE IF EXISTS portfolio_simulation;

UPDATE sim_temp st
SET

a1_local_value 		= a1_price * a1_amount,
a2_local_value 		= a2_price * a2_amount,
a3_local_value 		= a3_price * a3_amount,
a4_local_value 		= a4_price * a4_amount,
a5_local_value 		= a5_price * a5_amount,
a6_local_value 		= a6_price * a6_amount,
a7_local_value 		= a7_price * a7_amount,
a8_local_value 		= a8_price * a8_amount,
a9_local_value 		= a9_price * a9_amount,
a10_local_value 	= a10_price * a10_amount,

usd_exposure_usd	= IF(@a1_currency = 'USD', a1_local_value, 0)
					+ IF(@a2_currency = 'USD', a2_local_value, 0)
                    + IF(@a3_currency = 'USD', a3_local_value, 0)
                    + IF(@a4_currency = 'USD', a4_local_value, 0)
                    + IF(@a5_currency = 'USD', a5_local_value, 0)
                    + IF(@a6_currency = 'USD', a6_local_value, 0)
                    + IF(@a7_currency = 'USD', a7_local_value, 0)
                    + IF(@a8_currency = 'USD', a8_local_value, 0)
                    + IF(@a9_currency = 'USD', a9_local_value, 0)
                    + IF(@a10_currency = 'USD', a10_local_value, 0),


-- ----------------- CAMBIAR DE NUEVO --> sim_forex_prices --> forex_prices
usd_exposure_eur	= usd_exposure_usd / (SELECT last_close FROM sim_forex_prices WHERE forex_pair = 'EURUSD' AND date = st.date),

eur_exposure		= IF(@a1_currency = 'EUR', a1_local_value, 0)
					+ IF(@a2_currency = 'EUR', a2_local_value, 0)
                    + IF(@a3_currency = 'EUR', a3_local_value, 0)
                    + IF(@a4_currency = 'EUR', a4_local_value, 0)
                    + IF(@a5_currency = 'EUR', a5_local_value, 0)
                    + IF(@a6_currency = 'EUR', a6_local_value, 0)
                    + IF(@a7_currency = 'EUR', a7_local_value, 0)
                    + IF(@a8_currency = 'EUR', a8_local_value, 0)
                    + IF(@a9_currency = 'EUR', a9_local_value, 0)
                    + IF(@a10_currency = 'EUR', a10_local_value, 0);

   IF  @rebalancing_type = 'Period'
 THEN  ALTER TABLE sim_temp
 	   DROP COLUMN reb_trigger_a1,
       DROP COLUMN reb_trigger_a2,
       DROP COLUMN reb_trigger_a3,
       DROP COLUMN reb_trigger_a4,
       DROP COLUMN reb_trigger_a5,
       DROP COLUMN reb_trigger_a6,
       DROP COLUMN reb_trigger_a7,
       DROP COLUMN reb_trigger_a8,
       DROP COLUMN reb_trigger_a9,
       DROP COLUMN reb_trigger_a10;
END IF;

CREATE TABLE portfolio_simulation LIKE sim_temp;     

INSERT INTO portfolio_simulation
SELECT * FROM sim_temp;             

UPDATE portfolio_simulation t1 
  JOIN (SELECT 
		date, 
		tot_balance,
		LAG(tot_balance,1) OVER (ORDER BY date) AS prev_tot_balance_1d
  FROM portfolio_simulation) t2
    ON t1.date = t2.date
   SET t1.tot_balance_change_d = ((t1.tot_balance - t2.prev_tot_balance_1d) / t2.prev_tot_balance_1d) * 100
 WHERE t1.date != @start_date;


IF @asset_1 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a1_price, 
					LAG(a1_price,1) OVER (ORDER BY date) AS a1_prev_price_1d, 
					a1_portfolio_price,
					LAG(a1_portfolio_price,1) OVER (ORDER BY date) AS a1_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a1_local_change_d 		= ((t1.a1_price - t2.a1_prev_price_1d) / t2.a1_prev_price_1d) * 100,
		a1_portfolio_change_d 	= ((t1.a1_portfolio_price - t2.a1_prev_portfolio_price_1d) / t2.a1_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a1_symbol				=	'None',
			a1_price				=	0,
			a1_forex_pair			=	'None',
			a1_fx_rate				=	0,
			a1_portfolio_price		=	0,
			a1_amount				=	0,
			a1_amount_change		=	0,
			a1_local_value			=	0,
			a1_portfolio_value		=	0,
			a1_local_change_d		=	0,
			a1_portfolio_change_d	=	0;
END IF;

IF @asset_2 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a2_price, 
					LAG(a2_price,1) OVER (ORDER BY date) AS a2_prev_price_1d, 
					a2_portfolio_price,
					LAG(a2_portfolio_price,1) OVER (ORDER BY date) AS a2_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a2_local_change_d 		= ((t1.a2_price - t2.a2_prev_price_1d) / t2.a2_prev_price_1d) * 100,
		a2_portfolio_change_d 	= ((t1.a2_portfolio_price - t2.a2_prev_portfolio_price_1d) / t2.a2_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a2_symbol				=	'None',
			a2_price				=	0,
			a2_forex_pair			=	'None',
			a2_fx_rate				=	0,
			a2_portfolio_price		=	0,
			a2_amount				=	0,
			a2_amount_change		=	0,
			a2_local_value			=	0,
			a2_portfolio_value		=	0,
			a2_local_change_d		=	0,
			a2_portfolio_change_d	=	0;
END IF;

IF @asset_3 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a3_price, 
					LAG(a3_price,1) OVER (ORDER BY date) AS a3_prev_price_1d, 
					a3_portfolio_price,
					LAG(a3_portfolio_price,1) OVER (ORDER BY date) AS a3_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a3_local_change_d 		= ((t1.a3_price - t2.a3_prev_price_1d) / t2.a3_prev_price_1d) * 100,
		a3_portfolio_change_d 	= ((t1.a3_portfolio_price - t2.a3_prev_portfolio_price_1d) / t2.a3_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a3_symbol				=	'None',
			a3_price				=	0,
			a3_forex_pair			=	'None',
			a3_fx_rate				=	0,
			a3_portfolio_price		=	0,
			a3_amount				=	0,
			a3_amount_change		=	0,
			a3_local_value			=	0,
			a3_portfolio_value		=	0,
			a3_local_change_d		=	0,
			a3_portfolio_change_d	=	0;
END IF;

IF @asset_4 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a4_price, 
					LAG(a4_price,1) OVER (ORDER BY date) AS a4_prev_price_1d, 
					a4_portfolio_price,
					LAG(a4_portfolio_price,1) OVER (ORDER BY date) AS a4_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a4_local_change_d 		= ((t1.a4_price - t2.a4_prev_price_1d) / t2.a4_prev_price_1d) * 100,
		a4_portfolio_change_d 	= ((t1.a4_portfolio_price - t2.a4_prev_portfolio_price_1d) / t2.a4_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a4_symbol				=	'None',
			a4_price				=	0,
			a4_forex_pair			=	'None',
			a4_fx_rate				=	0,
			a4_portfolio_price		=	0,
			a4_amount				=	0,
			a4_amount_change		=	0,
			a4_local_value			=	0,
			a4_portfolio_value		=	0,
			a4_local_change_d		=	0,
			a4_portfolio_change_d	=	0;
END IF;

IF @asset_5 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a5_price, 
					LAG(a5_price,1) OVER (ORDER BY date) AS a5_prev_price_1d, 
					a5_portfolio_price,
					LAG(a5_portfolio_price,1) OVER (ORDER BY date) AS a5_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a5_local_change_d 		= ((t1.a5_price - t2.a5_prev_price_1d) / t2.a5_prev_price_1d) * 100,
		a5_portfolio_change_d 	= ((t1.a5_portfolio_price - t2.a5_prev_portfolio_price_1d) / t2.a5_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a5_symbol				=	'None',
			a5_price				=	0,
			a5_forex_pair			=	'None',
			a5_fx_rate				=	0,
			a5_portfolio_price		=	0,
			a5_amount				=	0,
			a5_amount_change		=	0,
			a5_local_value			=	0,
			a5_portfolio_value		=	0,
			a5_local_change_d		=	0,
			a5_portfolio_change_d	=	0;
END IF;

IF @asset_6 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a6_price, 
					LAG(a6_price,1) OVER (ORDER BY date) AS a6_prev_price_1d, 
					a6_portfolio_price,
					LAG(a6_portfolio_price,1) OVER (ORDER BY date) AS a6_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a6_local_change_d 		= ((t1.a6_price - t2.a6_prev_price_1d) / t2.a6_prev_price_1d) * 100,
		a6_portfolio_change_d 	= ((t1.a6_portfolio_price - t2.a6_prev_portfolio_price_1d) / t2.a6_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a6_symbol				=	'None',
			a6_price				=	0,
			a6_forex_pair			=	'None',
			a6_fx_rate				=	0,
			a6_portfolio_price		=	0,
			a6_amount				=	0,
			a6_amount_change		=	0,
			a6_local_value			=	0,
			a6_portfolio_value		=	0,
			a6_local_change_d		=	0,
			a6_portfolio_change_d	=	0;
END IF;

IF @asset_7 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a7_price, 
					LAG(a7_price,1) OVER (ORDER BY date) AS a7_prev_price_1d, 
					a7_portfolio_price,
					LAG(a7_portfolio_price,1) OVER (ORDER BY date) AS a7_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a7_local_change_d 		= ((t1.a7_price - t2.a7_prev_price_1d) / t2.a7_prev_price_1d) * 100,
		a7_portfolio_change_d 	= ((t1.a7_portfolio_price - t2.a7_prev_portfolio_price_1d) / t2.a7_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a7_symbol				=	'None',
			a7_price				=	0,
			a7_forex_pair			=	'None',
			a7_fx_rate				=	0,
			a7_portfolio_price		=	0,
			a7_amount				=	0,
			a7_amount_change		=	0,
			a7_local_value			=	0,
			a7_portfolio_value		=	0,
			a7_local_change_d		=	0,
			a7_portfolio_change_d	=	0;
END IF;

IF @asset_8 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a8_price, 
					LAG(a8_price,1) OVER (ORDER BY date) AS a8_prev_price_1d, 
					a8_portfolio_price,
					LAG(a8_portfolio_price,1) OVER (ORDER BY date) AS a8_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a8_local_change_d 		= ((t1.a8_price - t2.a8_prev_price_1d) / t2.a8_prev_price_1d) * 100,
		a8_portfolio_change_d 	= ((t1.a8_portfolio_price - t2.a8_prev_portfolio_price_1d) / t2.a8_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a8_symbol				=	'None',
			a8_price				=	0,
			a8_forex_pair			=	'None',
			a8_fx_rate				=	0,
			a8_portfolio_price		=	0,
			a8_amount				=	0,
			a8_amount_change		=	0,
			a8_local_value			=	0,
			a8_portfolio_value		=	0,
			a8_local_change_d		=	0,
			a8_portfolio_change_d	=	0;
END IF;

IF @asset_9 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a9_price, 
					LAG(a9_price,1) OVER (ORDER BY date) AS a9_prev_price_1d, 
					a9_portfolio_price,
					LAG(a9_portfolio_price,1) OVER (ORDER BY date) AS a9_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a9_local_change_d 		= ((t1.a9_price - t2.a9_prev_price_1d) / t2.a9_prev_price_1d) * 100,
		a9_portfolio_change_d 	= ((t1.a9_portfolio_price - t2.a9_prev_portfolio_price_1d) / t2.a9_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a9_symbol				=	'None',
			a9_price				=	0,
			a9_forex_pair			=	'None',
			a9_fx_rate				=	0,
			a9_portfolio_price		=	0,
			a9_amount				=	0,
			a9_amount_change		=	0,
			a9_local_value			=	0,
			a9_portfolio_value		=	0,
			a9_local_change_d		=	0,
			a9_portfolio_change_d	=	0;
END IF;

IF @asset_10 IS NOT NULL
THEN UPDATE portfolio_simulation t1 
	   JOIN (SELECT 
					date, 
					a10_price, 
					LAG(a10_price,1) OVER (ORDER BY date) AS a10_prev_price_1d, 
					a10_portfolio_price,
					LAG(a10_portfolio_price,1) OVER (ORDER BY date) AS a10_prev_portfolio_price_1d 
					FROM portfolio_simulation) t2
		 ON t1.date = t2.date
		SET 
		a10_local_change_d 		= ((t1.a10_price - t2.a10_prev_price_1d) / t2.a10_prev_price_1d) * 100,
		a10_portfolio_change_d 	= ((t1.a10_portfolio_price - t2.a10_prev_portfolio_price_1d) / t2.a10_prev_portfolio_price_1d) * 100;
ELSE UPDATE portfolio_simulation
		SET a10_symbol				=	'None',
			a10_price				=	0,
			a10_forex_pair			=	'None',
			a10_fx_rate				=	0,
			a10_portfolio_price		=	0,
			a10_amount				=	0,
			a10_amount_change		=	0,
			a10_local_value			=	0,
			a10_portfolio_value		=	0,
			a10_local_change_d		=	0,
			a10_portfolio_change_d	=	0;
END IF;

END //
;

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
sim_id 				= 	@sim_id,
portfolio_id 		=	@portfolio_id,
strategy_id 		= 	@strategy_id,
sim_timestamp		=	@sim_timestamp,    

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
sim_id 				= 	@sim_id,
portfolio_id 		=	@portfolio_id,
strategy_id 		= 	@strategy_id,
sim_timestamp		=	@sim_timestamp,    

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
	
END //




