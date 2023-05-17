

-- CALCULATING PORTFOLIIO PERFORMANCE METRICS
-- 1. DRAWDOWN TO DATE AND MAXIMUM DRAWDOWN
-- 2. CALCULATING STANDART DEVIATIONS (MONTHLY, QUARTERLY AND YEARLY)


-- 1. DRAWDOWN TO DATE AND MAXIMUM DRAWDOWN
-- Creating a temporary table calculating the drawdown for each day from previous (highest) peak
CREATE TEMPORARY TABLE sim_drawdown AS
SELECT 
	date, 
    tot_balance, 
    max(tot_balance) OVER (ORDER BY date) AS max_value, 
    (tot_balance /  max(tot_balance) OVER (ORDER BY date)) - 1 AS dd
FROM sim_looper
WHERE tot_balance IS NOT NULL;

-- Creating a temporary table for maximum dd since portfolio inception
CREATE TEMPORARY TABLE max_dd;
SELECT date, min(dd) OVER (ORDER BY date) AS max_dd 
FROM sim_drawdown;

-- 2. CALCULATING STANDART DEVIATIONS (MONTHLY, QUARTERLY AND YEARLY)

SELECT 
	STDDEV(tot_balance_change_m) AS stddev_monthly, 
	STDDEV(tot_balance_change_q) AS stddev_quarterly, 
	STDDEV(tot_balance_change_y) AS stddev_yearly
FROM sim_looper;







