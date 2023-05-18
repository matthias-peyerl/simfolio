

-- CALCULATING PORTFOLIIO PERFORMANCE METRICS
-- 1. DRAWDOWN TO DATE AND MAXIMUM DRAWDOWN
-- 2. CALCULATING STANDART DEVIATIONS (MONTHLY, QUARTERLY AND YEARLY)
-- 3. CALCULATING PORTFOLIO BETA AGAINST A VARIABLE BENCHMARK
-- 4. CALCULATING THE SHARP RATIO FOR MONTHLY RETURNS
-- 5. CALCULATING THE SORTINO RATIO


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


-- 3. CALCULATING PORTFOLIO BETA AGAINST A VARIABLE BENCHMARK

SET @beta_benchmark = 'SP500';

-- Calculating the daily changes in the benchmark
SELECT t1.isin AS Benchmark, AVG((t2.p_change_pct  * t1.benchmark_change_pct) / t1.benchmark_change_pct) AS Beta
FROM 
(SELECT 
	date,
    isin,
	/*close, 
    LAG(last_close) OVER (ORDER BY date) AS prev_close,
    close - LAG(last_close) OVER (ORDER BY date) AS day_change_amt,*/
    ((close - LAG(last_close) OVER (ORDER BY date)) / LAG(last_close) OVER (ORDER BY date)) * 100 AS benchmark_change_pct 
FROM asset_prices
WHERE isin = @beta_benchmark
AND date >= @first_date
AND date <= @last_date) AS t1
LEFT JOIN 
(SELECT 
	date, 
	tot_balance_change_d AS p_change_pct
FROM sim_looper) AS t2
ON t1.date = t2.date
GROUP BY isin;

-- 3. CALCULATING PORTFOLIO BETA AGAINST A VARIABLE BENCHMARK
-- CALCULATING RETURN COVARIANCE OF PORTFOLIO AND BENCHMARK

DROP TABLE bechmark_price_changes;
CREATE TEMPORARY TABLE bechmark_price_changes AS
SELECT
	date,
    isin,
	close, 
    LAG(last_close) OVER (ORDER BY date) AS prev_close,
    close - LAG(last_close) OVER (ORDER BY date) AS day_change_amt_d,
    ((close - LAG(last_close) OVER (ORDER BY date)) / LAG(last_close) OVER (ORDER BY date)) * 100 AS benchmark_change_pct_d 
FROM asset_prices
WHERE isin = @beta_benchmark
AND date >= @first_date
AND date <= @last_date;

-- /*	NOT REALLY NEEDED...
SET @p_return 						= (SELECT tot_balance FROM sim_looper WHERE date = @last_date) / @inicial_balance * 100 - 100;
SET @benchmark_return 				= (SELECT last_close FROM asset_prices WHERE date = @last_date AND isin = @beta_benchmark) / 
										(SELECT last_close FROM asset_prices WHERE date = @first_date AND isin = @beta_benchmark)  * 100 - 100;
-- */
                            
SET @p_avg_return_d					= (SELECT AVG(tot_balance_change_d) FROM sim_looper);
SET @benchmark_avg_return_d			= (SELECT AVG(benchmark_change_pct_d) FROM bechmark_price_changes);


SELECT 
SUM(covar_calc)/(COUNT(DISTINCT date)-1) AS Covariance,
SUM(var_calc)/(COUNT(DISTINCT date)-1) AS Variance,
(SUM(covar_calc)/(COUNT(DISTINCT date)-1))/(SUM(var_calc)/(COUNT(DISTINCT date)-1)) AS Beta
FROM (SELECT
		b.date,
		@p_avg_return_d AS p_avg,
		a.tot_balance_change_d AS p_change,
		@benchmark_avg_return_d AS b_avg,
		b.benchmark_change_pct_d AS b_change,
		(a.tot_balance_change_d - @p_avg_return_d) * (b.benchmark_change_pct_d - @benchmark_avg_return_d) AS covar_calc,
        POW((b.benchmark_change_pct_d - @benchmark_avg_return_d), 2) AS var_calc
	FROM sim_looper a
	RIGHT JOIN
		bechmark_price_changes b
	on b.date = a.date
	WHERE b.benchmark_change_pct_d IS NOT NULL) AS c;

SELECT AVG(tot_balance_change_d) FROM sim_looper;

SELECT @p_return, @benchmark_return, @p_avg_return_d, @benchmark_avg_return_d;

SELECT VARIANCE(benchmark_change_pct_d)
FROM bechmark_price_changes;



-- SHARP RATIO FOR MONTHLY RETURNS

SELECT 
	STDDEV(tot_balance_change_m) AS stddev_monthly
FROM sim_looper;



SELECT
-- CALCULATING THE NUMERATOR FROM YEARLY RETURNS AND YEARLY STDDEV 
((SELECT AVG(t1.rp - t2.rf) AS sharp_numerator
FROM
(SELECT date, tot_balance_change_y AS rp
FROM sim_looper) AS t1
JOIN
(SELECT date, value AS rf
FROM econ_indicators_values
WHERE symbol = 'EUR-RFR') AS t2
ON t1.date = t2.date)
/
(SELECT 
	STDDEV(tot_balance_change_y) AS stddev_monthly
FROM sim_looper)) sharp_ratio;

-- TRYING FOR A MOTHLY SHARP RATIO
SELECT sharp_ratio
-- CALCULATING THE NUMERATOR FROM YEARLY RETURNS AND YEARLY STDDEV 
((SELECT year(t1.date) AS year, AVG(t1.rp - t2.rf) AS sharp_numerator
FROM
(SELECT date, tot_balance_change_y AS rp
FROM sim_looper) AS t1
RIGHT JOIN
(SELECT date, value AS rf
FROM econ_indicators_values
WHERE symbol = 'EUR-RFR') AS t2
ON t1.date = t2.date
GROUP BY year) 
/
(SELECT 
	year(date) AS year, STDDEV(tot_balance_change_y) AS stddev_yearly
FROM sim_looper -- ) sharp_ratio
GROUP BY year)) sharp_ratio;


SELECT date, tot_balance_change_y AS rp
FROM sim_looper;

SELECT date, value AS rf
FROM econ_indicators_values
WHERE symbol = 'EUR-RFR';


-- CREATING A SHARP RATIO YEAR OVER YEAR

SELECT year(t2.date), AVG(t1.rp) - AVG(t2.rf) --  year(t1.date) AS year, AVG(t1.rp - t2.rf) AS sharp_numerator
FROM
(SELECT date, tot_balance_change_y AS rp
FROM sim_looper) AS t1
RIGHT JOIN
(SELECT date, value/12 AS rf
FROM econ_indicators_values
WHERE symbol = 'EUR-RFR'
AND date >= @first_date
AND date <= @last_date ) AS t2
ON t1.date = t2.date
GROUP BY year(t2.date);

-- STANDART DEVIATION YEAR OVER YEAR
SELECT
    YEAR(date) AS year,
    AVG(STDDEV_POP(tot_balance_change_y)) OVER (ORDER BY YEAR(date) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS yearly_stddev
FROM
    sim_looper
GROUP BY
    YEAR(date);

-- NOW THIS LOOKS BETTER 
DROP TABLE yearly_sharp_ratio;

CREATE TEMPORARY TABLE yearly_sharp_ratio AS
SELECT t3.year AS year, t3.excess_return, T4.yearly_stddev, t3.excess_return/T4.yearly_stddev AS sharp_ratio
FROM 
(SELECT year(t2.date) AS year, AVG(t1.rp) - AVG(t2.rf) excess_return --  year(t1.date) AS year, AVG(t1.rp - t2.rf) AS sharp_numerator
	FROM
		(SELECT date, tot_balance_change_y AS rp
		FROM sim_looper
        WHERE tot_balance_change_y IS NOT NULL) AS t1
		JOIN
		(SELECT date, value AS rf
		FROM econ_indicators_values
		WHERE symbol = 'EUR-RFR'
		AND date >= @first_date
		AND date <= @last_date) AS t2
		ON t1.date = t2.date
		GROUP BY YEAR(t2.date)) t3
	JOIN
		-- JOIN WITH A YEARLY STANDART DEV
		(SELECT
		YEAR(date) AS year,
		AVG(STDDEV_POP(tot_balance_change_y)) OVER (ORDER BY YEAR(date) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS yearly_stddev
		FROM sim_looper
		GROUP BY YEAR(date)) t4
	ON t3.year = t4.year;

-- SHARP RATIO AVERAGE ON MONTHLY DATA
SELECT AVG(sharp_ratio)
FROM yearly_sharp_ratio;

SELECT*
FROM yearly_sharp_ratio;

-- I am not sure whether the calcuilation is correct. The problem being that the tot_balance_change_y is using data from the previous 365 days, 
-- which means most of the time, the data is not only from the year the sharp ratio is calculated for. 


