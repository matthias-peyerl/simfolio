-- SETTING UP USER DEFINED INPUT OPTIONS
SET @p_name 			= 'PT2';
SET @username 			= 'MATT';
SET @inicial_balance 	= 100000;
SET @strategy 			= '150:0';

-- SETTING ALTERNATIVE START AND END DAYS
SET @alt_start			='';--  '2020-01-01';
SET @alt_end			=''; --  '2020-06-01';

CALL run_simulation();
CALL sim_save();
CALL run_and_save();

-- LAST SIMULATIONS RESULTS
SELECT* --  COUNT(*)
FROM sim_looper
WHERE interest = 1; 

SELECT @last_date;

DROP PROCEDURE sim_prepare;
DROP PROCEDURE sim_step1;
DROP PROCEDURE sim_step2;
DROP PROCEDURE sim_step3;
DROP PROCEDURE sim_save;

CALL user_update();
CALL sim_prepare();
CALL sim_step1();
CALL sim_step2();
CALL sim_step3();
CALL sim_save();

SELECT* --  SUM(transaction_costs)
FROM sim_looper;
WHERE transaction_costs = -3;
