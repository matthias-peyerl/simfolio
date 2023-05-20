-- SETTING UP USER DEFINED INPUT OPTIONS
SET @p_name 			= 'PT1';
SET @username 			= 'MATT';
SET @inicial_balance 	= 100000;
SET @strategy 			= '150:0';
SET @reb_period			= (SELECT period 
;

/*
Problem: 
I need to create a rebalancing period for days. But some days are not trading days and I will only be able to trade on trading days. 
At least I want the simulation to be as accurate. 

While looking at that problem, I noticed, that the relative rebalancing already takes place on non trading days as well, so maybe I should solve both problems at the same time. 

How about I only loop through trading days first and fill up the other days afterwards with their respective data, filling in the previous days data.

OR I JUST ADD ANOTHER CONDITION TO THE AMOUNT CALCULATION WHICH IS -- IF TARDING DAY-TRADE - ELSE- DON'T

*/

-- SETTING ALTERNATIVE START AND END DAYS

SET @alt_start			='2019-01-01';
SET @alt_end			='2020-06-01';

-- Interestingly, the running time dose not change linearily. 
-- It has a minimum value at the beginning, then it gets inccrealingly slower per added month, the longer the bigger the table gets. 
-- What might be the optimal split to run at a time and unite later? maybe a year

CALL run_simulation();
CALL sim_save();
CALL run_and_save();

-- LAST SIMULATIONS RESULTS
SELECT* --  COUNT(*)
FROM sim_looper
WHERE r1 = 1;

SELECT @last_date;

DROP PROCEDURE sim_prepare;
DROP PROCEDURE sim_step1;
	DROP PROCEDURE sim_periodic_trigger;
DROP PROCEDURE sim_step2;
DROP PROCEDURE sim_step3;
DROP PROCEDURE sim_save;

CALL user_update();
CALL sim_prepare();
CALL sim_step1();
	CALL sim_periodic_trigger('monthly');
CALL sim_periodic_step2();
CALL sim_relative_step2();    
CALL sim_step2();
CALL sim_step3();
CALL sim_save();

SELECT date, a1_portfolio_change_d, reb_trigger_a1, reb_trigger_a2 --  SUM(transaction_costs)
FROM sim_looper
WHERE reb_trigger_a1 <> 0;
