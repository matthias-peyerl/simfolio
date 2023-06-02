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

-- The procedure to be loaded in the beginning, when starting up the db:
DELIMITER //
CREATE PROCEDURE load_basic_setting()
BEGIN 

	SET @inicial_balance 		=	100000;
	SET @batch_size		 		=	10;
	SET @interest_augment		=	1;			-- INTEREST AUGMENTATION OF RFR + _% -- out of sight, because its explenation is out of scope
    SET @portfolio_name			= 	'Standard';
        
END //
;






















-- The procedure inception_date makes sure that the asset table column inception_date contains in the first date available 
-- from the respective asset in the asset_prices table by updating every column that has a NULL value in thet column.
DROP PROCEDURE update_portfolio;
DROP PROCEDURE portfolio_creation;
DROP PROCEDURE end_date_update;

CALL end_date_update();
SELECT*
FROM asset;


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

-- If you just want to run the simulation wityhout changing or adjusting anything, just call the following procedure: 

CALL just_run();

PREPARE ALL VARIABLES... ETC WITH A PROCEDURE AT THE START 
;


/* 
The following procedure creates a new portfolio in the portfolio table, if the name is not taken yet. 
If it's taken it just displays that fact as a message in results table. 

If it's not taken it goes on to create it and the respective assets and allocations, 
making sure that no assets are stored for a portfolio t
*/
DELIMITER //
CREATE PROCEDURE portfolio_creation()
BEGIN

    IF @portfolio_name IN 	(SELECT portfolio_name FROM portfolio) 
                            THEN SELECT('Portfolio name taken') MESSAGE_FOR_YOU;
	ELSE      INSERT INTO 	portfolio (portfolio_name, portfolio_currency, portfolio_strategy, portfolio_transaction_cost)
				   VALUES 	(@portfolio_name, @portfolio_currency, @portfolio_strategy, @portfolio_transaction_cost);
			       DELETE
                     FROM	portfolio_asset
				    WHERE	portfolio_name = @portfolio_name;
					
                 IF 		@asset_1 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_1, @asset_1_allocation);
                 END IF;
                 IF 		@asset_2 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_2, @asset_2_allocation);
                 END IF;
                 IF 		@asset_3 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_3, @asset_3_allocation);
                 END IF;
                 IF 		@asset_4 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_4, @asset_4_allocation);
                 END IF;
                 IF 		@asset_5 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_5, @asset_5_allocation);
                 END IF;
                 IF 		@asset_6 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_6, @asset_6_allocation);
                 END IF;
                 IF 		@asset_7 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_7, @asset_7_allocation);
                 END IF;
                 IF 		@asset_8 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_8, @asset_8_allocation);
                 END IF;
                 IF 		@asset_9 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_9, @asset_9_allocation);
                 END IF;
                 IF 		@asset_10 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_10, @asset_10_allocation);
                 END IF;
	END IF;               
END//
;

DELIMITER //
CREATE PROCEDURE update_portfolio()
BEGIN

    IF @portfolio_name IN 	(SELECT portfolio_name FROM portfolio) 
					 THEN	 UPDATE portfolio
							    SET	portfolio_currency 			= @portfolio_currency,
									portfolio_strategy			= @portfolio_strategy,
                                    portfolio_transaction_cost	= @portfolio_transaction_cost								
							  WHERE portfolio_name = @portfolio_name;
                   
							 DELETE
							   FROM	portfolio_asset
							  WHERE	portfolio_name = @portfolio_name;
					
                 IF 		@asset_1 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_1, @asset_1_allocation);
                 END IF;
                 IF 		@asset_2 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_2, @asset_2_allocation);
                 END IF;
                 IF 		@asset_3 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_3, @asset_3_allocation);
                 END IF;
                 IF 		@asset_4 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_4, @asset_4_allocation);
                 END IF;
                 IF 		@asset_5 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_5, @asset_5_allocation);
                 END IF;
                 IF 		@asset_6 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_6, @asset_6_allocation);
                 END IF;
                 IF 		@asset_7 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_7, @asset_7_allocation);
                 END IF;
                 IF 		@asset_8 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_8, @asset_8_allocation);
                 END IF;
                 IF 		@asset_9 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_9, @asset_9_allocation);
                 END IF;
                 IF 		@asset_10 != '' THEN INSERT INTO portfolio_asset VALUES (@portfolio_name, @asset_10, @asset_10_allocation);
                 END IF;
	END IF;               
END//
;


DELIMITER //
CREATE PROCEDURE strategy_creation()
BEGIN

    IF @strategy_name IN 	(SELECT strategy_name FROM strategy) 
                            THEN SELECT('Strategy name taken') MESSAGE_FOR_YOU;
	ELSE     INSERT INTO 	strategy (strategy_name, rebalancing_type, leverage, lev_rebalancing)
			      VALUES 	(@strategy_name, @rebalancing_type, @leverage, @leverage_rebalancing);
			      				
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
CREATE PROCEDURE update_strategy()
BEGIN

    IF @strategy_name 	    IN 	(SELECT strategy_name FROM strategy) 
				 THEN   UPDATE  strategy
						   SET  rebalancing_type 		= @rebalancing_type, 
								leverage		 		= @leverage,
                                lev_rebalancing			= @lev_rebalancing	
						WHERE   strategy_name 			= @strategy_name;
    
						   IF	@rebalancing_type 		= 'deviation'
						 THEN	UPDATE strategy
							    SET rel_rebalancing 	= @rel_rebalancing,		
							       min_rebalancing 		= @min_rebalancing
							    WHERE strategy_name   	= @strategy_name;
					   END IF;
                  
						  IF   @rebalancing_type 		= 'period'
						THEN   UPDATE strategy
							   SET period 	  			= @period
							   WHERE strategy_name   	= @strategy_name;
					   END IF;  
	ELSE SELECT "Strategy name doesn't exist";
    END IF;               
END//
;

