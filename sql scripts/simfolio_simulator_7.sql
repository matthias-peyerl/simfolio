/*
SIMFOLIO
This document will help you execute the simulation Step by step. 
*/


/*
STEP 1 - LOAD BASIC SETTINGS
To get started we need to run a little script to make sure everythig is ready to run simulations.
*/
CALL load_basics();


/*
STEP 2 - RUN THE SIMULATION
If you are happy with a basic simulation with a present portfolio and strategy setting, 
you can now run the simulation. The same goes if you did change the settings, create a new portfolio or stratgy, 
and now want to execute: to do that, use the same procedure, (run_simulation()). 
*/
CALL run_simulation();


/*
STEP 3 - VIEW RESULTS
Once executed you can screen a variety of results: 
1. You will by default see an overview of the results as a results table. 
2. The table 'simulation' contains the performance and simulation overview data. 
   Every simulation will be saved with a timestamp, their sim_id, a unique portfolio_id and strategy_id. 
   Retrieve the data respective to the most recent simulation via the following query:
   SELECT * FROM simulation ORDER BY sim_id DESC LIMIT 1; (see underneath the comment)
3. The table 'sim_performance_yearly' contains performance data regarding all full years that the portfolio
   simulation included. Retrieve the data respective to the most recent simulation via the following query:
   SELECT * FROM sim_performance_yearly WHERE sim_id = @sim_id;* (see underneath the comment)
4. The table 'sim_performance_monthly' contains performance data regarding all months that the portfolio
   simulation included. Retrieve the data respective to the most recent simulation via the following query:
   SELECT * FROM sim_performance_yearly WHERE sim_id = @sim_id;* (see underneath the comment)
   *Note that you might have to adapt the queries if the variable is not valid anymore. 
    The most recent query will always have the highest sim_id number. 
*/
SELECT * FROM simulation ORDER BY sim_id DESC LIMIT 1;			-- For a general performance overview
SELECT * FROM sim_performance_yearly WHERE sim_id = @sim_id;  	-- For yearly performance data
SELECT * FROM sim_performance_monthly WHERE sim_id = @sim_id; 	-- For monthly performance data


/* OPTIONAL STEPS 
STEP 4
CREATING OR CHANGING THE (REBALANCING) STRATEGY


 VALUES 	(@strategy_id, @strategy_name, @rebalancing_type, @leverage, @leverage_rebalancing);


2. PORTFOLIO
CREATING OR CHANGING THE (REBALANCING) STRATEGY


*/

-- STEP 2
-- When you're happy with the standard settings or you already personalized portfolio and strategy, 
-- go ahead and execute the following procedure:
CALL run_simulation();



















-- WHAT YOU NEED TO CREATE A NEW PORTFOLIO: 
-- @portfolio_name, @portfolio_currency, @portfolio_strategy, @portfolio_transaction_cost

1. STEP CHOOSE A PORTFOLIO STRAEGY:

 VALUES 	(@strategy_id, @strategy_name, @rebalancing_type, @leverage, @leverage_rebalancing);


-- CREATE A PORTFOLIO 
SET @portfolio_name 				= 'Standard';
SET @portfolio_currency 			= 'EUR';		-- Choose from 'EUR' and 'USD'
SET @portfolio_transaction_cost 	=  1;			-- Set a realistic transaction cost for every time you trade.
SET @inicial_balance				= 100000;
SET @portfolio_strategy				= 1;			-- -----------HERE I NEED STILL TO DO THE RIGHT SEQUENCE


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
CALL portfolio_change();
CALL update_portfolio();

SELECT* FROM portfolio;

DELETE FROM portfolio
WHERE portfolio_id = 3;
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



CALL portfolio_change();

select* from portfolio;
select* from strategy;
SELECT * FROM simulation_data;
-- ____________________________________________________________________________


CALL prepare_sim_variables();			
CALL prepare_sim_forex_data();			
CALL sim_table_creation();

	CALL first_row_data();
	CALL sim_relative_looper();
		
	CALL first_periodic_data(); 		
	CALL sim_periodic_looper(@period);

CALL sim_final_data_population;
CALL performance_metrics_calculation();

DROP PROCEDURE performance_metrics_calculation;

