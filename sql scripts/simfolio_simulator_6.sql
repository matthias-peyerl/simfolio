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


CREATE TABLE simulation (
PRIMARY KEY (sim_id),
FOREIGN KEY (portfolio_id)
REFERENCES portfolio(portfolio_id),
sim_id INT UNSIGNED,
timestamp TIMESTAMP,
portfolio_id INT,
strategy_id INT, 
start_date DATE,
end_date DATE);




SHOW PROCEDURE sim_final_data_population();



