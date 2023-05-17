-- SETTING UP USER DEFINED INPUT OPTIONS
SET @p_name = 'PT1';
SET @username = 'MATT';
SET @inicial_balance = 100000;
SET @strategy = '150:0';

CALL run_simulation();
CALL sim_save();
CALL run_and_save();

SELECT* -- SUM(buy), SUM(sell), SUM(tot_change)
FROM sim_looper; -- LAST SIMULATIONS RESULTS

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

SELECT ABS(9.53 - @a1_allocation) / @a1_allocation ;

SELECT @p_rel_rebalancing / 100;

SELECT @p_min_rebalancing;

select ABS(9.5 - @a1_allocation); -- > @p_min_rebalancing
