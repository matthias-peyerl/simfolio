/*
SIMFOLIO
This document will help you execute the investment portfolio simulation step by step. 
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
Be aware that the simultation can take some time to run (60 seconds or more).

If you prefer to choose a portfolio different from a preselected 'Standard' portfolio, 
you can look up the portfolios from the portfolio table and the relating portfolio assets 
and strategies from the portfolio_asset and strategy table respectively. 
Set a different portfolio to run by definig the @portfolio_name varaibale accordingly,
by introducing the portfolio name you want to use. 

*/

-- This procedure will execute the simulation 
-- with the portfolio_name variable that's set at each moment:
CALL run_simulation();

-- Changing this variable you can select another portfolio to run: 
SET @portfolio_name =  		'____________';	


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


-- ----------------------------------------------------------------------------------------------------------------------------------------------------

/* OPTIONAL STEPS
STEP 4 - DEFINE A PORTFOLIO

1. You can have a look at the existing portfolios in the portfolio table. 
   To see the respective assets and their allocation within the portfolio, 
   use the portfolio id as a filter, to look them up in the portfolio_asset table. 
   If you want to use one of the portfolios in a simulation, you just have 
   to set the portfolio_name variable accordingly and go up the run the procedure 
   in step 2 (see the variable setting underneath).
   
2. To create a new portfolio (see underneath), you need to set the following variables: 
		
        - Choose a new portfolio name via the @portfolio_name variable. 
          The name cannot exist in the portfolio table already.
          
		- Choose a portfolio currency via the @portfolio_currency variable. 
          At this point the simulation will work for the base currencies of EUR and USD.
          
		- Choose portfolio transaction costs via the @portfolio_transaction_cost variable. 
          This cost as a total amount in the portfolio currency will be deducted from the
          total balance each time a trade is executed, to make the simulation as realistic
          as possible. 
          
		- Choose a strategy whcih you want to use for your portfolio simulation via the
          @strategy_name variable. You can either choose an existing strategy from the 
          strategy table, or you can create a new one (see step 5 further down).

		- Choose the portfolio assets and their respective allocation via the @asset_(num)
          variables underneath. The allocations are in percent and should add up to 100. 
          If you surpass 100 it will work like leverage, if you deploy less than 100% of
          the capital, the rest will ust remain in your account as a reserve.

		- Finally, run the portfolio_configuration() procedure to establish and save. 
		  You will then be able to always choose it as the 
        
*/

-- To set the variable to run a simulation with an existing portfolio:
SET @portfolio_name 				= 		'____________';					-- Choose an existing portfolio name from the porfolio table. 

-- To create a new portfolio
SET @portfolio_name 				=    	'____________';					-- Choose a name that's not in use yet. 
SET @portfolio_currency 			= 		 'EUR' / 'USD';					-- Choose from 'EUR' and 'USD'
SET @portfolio_transaction_cost 	=  			         1;					-- Set a realistic transaction cost for every time you trade.			 	
SET @strategy_name					= 		'____________';					-- Select any strategy name from the strategy table.


-- Set the portfolio assets you want to use and set the allocations
-- You can look up all the available assets in asset table
SELECT* FROM asset;

SET @asset_1 	= 'IWMO.L'; 					SET @asset_1_allocation 	= 34;
SET @asset_2 	= 'PHAU.L'; 					SET @asset_2_allocation 	= 33;			
SET @asset_3 	= 'DBZB.DE'; 					SET @asset_3_allocation 	= 33;
SET @asset_4 	= NULL; 						SET @asset_4_allocation 	= 0;
SET @asset_5 	= NULL; 						SET @asset_5_allocation 	= 0;
SET @asset_6 	= NULL; 						SET @asset_6_allocation 	= 0;
SET @asset_7 	= NULL; 						SET @asset_7_allocation 	= 0;
SET @asset_8 	= NULL; 						SET @asset_8_allocation 	= 0;
SET @asset_9 	= NULL; 						SET @asset_9_allocation 	= 0;
SET @asset_10 	= NULL;  						SET @asset_10_allocation 	= 0;

-- Create the portfolio by running the following procedure (after setting the variables)
CALL portfolio_configuration();

-- ----------------------------------------------------------------------------------------------------------------------------------------------------


/* OPTIONAL STEPS
STEP 5 - DEFINE A STRATEGY

1. Look up the existing strategies in the strategy table: 
   SELECT* FROM strategy;
   
2. If you are happy with one of the existing strategies, 
   you can use it via its strategy_name when creating a new portfolio (Step 5). 
   
3. If you prefer to create a new strategy, follow these steps: 

   - Choose a name 
		To do that set the variable @strategy_name to a name of your choosing (see underneath).
        
   - Choose the portfolio leverage
		 To do that set the variable @leverage to an integer of your choosing. 
		 The value will represent the leverage in % that the portfolio will be traded 
		 above or below its value. If you set it at 100, the simulation will rebalance 
		 at each rebalancing event to buying a portfolio value taht is double the actual 
		 total balance ot total value of your assets. Recomended are values of between 0 and 500. 
		 Be aware that the leverage will also result in interes payments 
		 that are defined as 1% above the respective risk free rate. 
         
   - Choose a rebalancing strategy, 'deviation' or 'period': 
   
		 If you choose period: 
			 The allocations for each investment asset will be rebalanced or reestablished after a fix period of time of your choosing:
			 (daily, weekly, monthly, quarterly, semi-annually or annually). You need to establish the period you like by setting 
			 the @period variable (see underneath).
             
         If you choose deviation:
			 The rebalancing will be done if the different assets deviate more than a certain threshold from their assigned allocation. 
			 In this case you also need to establish the relative rebalancing and the minimum rebalancing (in percent each). 
				
                The relative rebalancing refers to the percentage that an assets' allocation deviates relative 
                to its' target allocation in percent. If we set it to 10% (via the value 10), an asset 
                that has an allocation of 50% will rebalance when it reaches 45% or 55%; an assent that
                has a target allocation of 3% will rebalance at 2.7% or 3.3%. 
                You need to establisgh the @rel_rebalancing variable in percent to define this. (see underneath)              
				
                The minimum rebalancing establishes the minimum amount an asset has to deviate in terms 
                of the persentage it represents within the whole portfolio to trigger a rebalancing. 
                This is precise to prevent too frequent rebalancing in assets that only represent a 
                very small part of the portfolio. A sensitive value here could be 1% (or 1 as a value for the varuiable). 
				You need to establisgh the @min_rebalancing variable in percent to define this. (see underneath)                 

				The leverage rebalancing setting is optional but recomended. It creates another trigger for rebalancing
				the portfolio when the leverage deviates more that the established amount relative to its' target amount in percent. 
                If you establish a leverage of 100% it will trigger a rebalancing once it crosses 90% or 110% of leverage. 
                
4. To finally establish the new strategy, once you have set all the variables, 
   please run the procedure strategy_configuration to establish it as a new strategy. 
   MAke sure that the strategy name is not taken yet, otherwise you will be reminded to set a new one. 
*/

SELECT* FROM strategy;

-- Create a new strategy:
SET @strategy_name 		= 	'____________________';		-- Choose a name of your liking
SET @leverage			= 		       		     0;		-- Choose the amount of leverage you want to use in percent. 
SET @rebalancing_type	=   'deviation' / 'period'; 		-- Choose between 'deviation' and 'period'

-- Only for perdiodic rebalancing strategies: 
SET @period				= 	'____________________';		-- Choose from: 'daily', 'weekly', 'monthly', 'quarterly', 'semi-annually', 'annually'

-- Only for deviation rebalancing strategies:
SET @rel_rebalancing 		= 				  	10;		-- The relative percentage that an asset can deviate from its' target allocation in percent.  
SET @min_rebalancing 		= 				   	 1;		-- The minimum percentage that an asset needs to be away from it's assigne portfolio percentage. 
SET @leverage_rebalancing	=					10;		-- The percentage the leverage can deviate from its' target amount before triggering a rebalancing 

-- Establish the new strategy (after setting the variables)
CALL strategy_configuration();
 


