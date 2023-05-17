-- SETTING UP USER DEFINED INPUT OPTIONS
SET @p_name = 'PT1';
SET @username = 'MATT';
SET @inicial_balance = 100000;
SET @strategy = '150:0';

CALL run_simulation();
CALL sim_save();
CALL run_and_save();

-- LAST SIMULATIONS RESULTS
SELECT*
FROM sim_looper; 

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


