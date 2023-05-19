
-- CREATING THE TABLE TO STORE ALL THE SIMULATIONS

CREATE TABLE sim_data LIKE sim_looper; -- CREATES A TABLE BASED ON THE OUTPUT TABLE STRUCTURE OF THE SIMULATION 

DROP TABLE sim_data;

ALTER TABLE sim_data
ADD COLUMN sim_date DATETIME DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN permanent BOOLEAN DEFAULT 0,
DROP PRIMARY KEY,
ADD CONSTRAINT PK_name_date PRIMARY KEY (sim_date, p_name, date);
DROP TABLE strategies;

CREATE TABLE strategies(
strategy_id INT PRIMARY KEY AUTO_INCREMENT,
strategy_name VARCHAR(100) UNIQUE,
rebalancing_type ENUM('DEVIATION', 'PERIOD', 'NONE'),
period ENUM('daily', 'weekly', 'monthly', 'quarterly', 'yearly'),
leverage FLOAT,
lev_rebalancing INT UNSIGNED,
min_rebalancing INT UNSIGNED,
rel_rebalancing INT UNSIGNED)
;

INSERT INTO strategies (strategy_name, leverage,min_rebalancing, rel_rebalancing)
VALUES ('150:0', 150, 1, 10);

UPDATE strategies
SET rebalancing_type  = 'DEVIATION'
WHERE leverage = 150;



-- CREATING AN ECONOMIC INDICATOR TABLE AND RESPECTIVE VALUES TABLE

DROP TABLE econ_indicators;
DROP TABLE econ_indicators_values;

CREATE TABLE econ_indicators(
symbol VARCHAR(20) PRIMARY KEY,
name VARCHAR(50),
description TEXT);


-- IMPORTING/CREATING A EURO RISK FREE RATE FOR PORTFOLIO RISK CALCULATIONS

INSERT INTO econ_indicators
VALUES ('EUR-RFR', 'Euro Risk Free Rate', 'Euribor weekly until including 2019 and from 2020 on the €STR.');

-- WE USE A COMBINATION OF EURIBOR (DATA GOES BACK FURTHER) AND €STR WHICH WE USE ONWARDS. 
-- WE USE THE WEEKLY EURIBOR BECAUSE IT'S THE CLOSEST TO THE €STR.

CREATE TABLE econ_indicators_values (
date DATE,
symbol VARCHAR(50), 
rate FLOAT,
last_rate FLOAT,
CONSTRAINT PK_date_name PRIMARY KEY (date, symbol),
CONSTRAINT FK_indicator_name FOREIGN KEY (symbol)
REFERENCES econ_indicators(symbol));

-- IMPORTING INDICATOR MANUALLY
-- 1. IMPORTING EURIBOR UNTIL INCLUDING 2019 
-- AND INSTERING DATA INTO TEMP TABLE FOR IMPORT
SELECT* FROM euribor_daily_rates_import;
DESC euribor_daily_rates_import;

ALTER TABLE euribor_daily_rates_import
MODIFY myUnknownColumn DATE;

ALTER TABLE euribor_daily_rates_import
RENAME COLUMN myUnknownColumn TO date,
RENAME COLUMN `1w` TO rate;

CREATE TABLE econ_indicator_imp AS 
SELECT date date, 'EUR-RFR' AS indicator, rate
FROM euribor_daily_rates_import
WHERE year(date) <= 2019;

-- 2. Same procedure for the €STR values for 2020 and later
SELECT* FROM str_import;
DESC str_import;

-- DELETING ALL ROWS WITH DESCRIPTIVE TEXT 
DELETE 
FROM str_import
WHERE `EST.B.EU000A2X2A25.WT` LIKE '%e%';

ALTER TABLE str_import
MODIFY date DATE,
RENAME COLUMN `EST.B.EU000A2X2A25.WT` TO rate;

INSERT INTO econ_indicator_imp
SELECT date, 'EUR-RFR', rate
FROM str_import
WHERE year(date) > 2019;

-- SETTING DATE VARIABLES AND CREATING FINAL IMPORT TABLE

SET @min_date_imp = (SELECT MIN(date) FROM econ_indicator_imp);
SET @max_date_imp = (SELECT MAX(date) FROM econ_indicator_imp);

CREATE TABLE econ_indicator_imp2 AS
SELECT c.date, 'EUR-RFR' as symbol, rate,
IF(rate IS NOT NULL, rate, COALESCE((LAG(rate,1) OVER (ORDER BY c.date)),
										(LAG(rate,2) OVER (ORDER BY c.date)),
										(LAG(rate,3) OVER (ORDER BY c.date)),
                                        (LAG(rate,4) OVER (ORDER BY c.date)),
                                        (LAG(rate,5) OVER (ORDER BY c.date))
									)) last_rate													
FROM econ_indicator_imp e
RIGHT JOIN calendar c
ON c.date = e.date
WHERE c.date BETWEEN @min_date_imp and @max_date_imp;

INSERT INTO econ_indicators_values (date, symbol, rate, last_rate)
SELECT date, symbol, rate, last_rate
FROM econ_indicator_imp2;

select*
from econ_indicators_values;

DROP TABLE econ_indicator_imp;
DROP TABLE econ_indicator_imp2;
DROP TABLE str_import;
DROP TABLE euribor_daily_rates_import;





