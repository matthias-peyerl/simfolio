
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
value FLOAT, 
CONSTRAINT PK_date_name PRIMARY KEY (date, symbol),
CONSTRAINT FK_indicator_name FOREIGN KEY (symbol)
REFERENCES econ_indicators(symbol));

-- IMPORTING INDICATOR MANUALLY
-- 1. IMPORTING EURIBOR UNTIL INCLUDING 2019 
SELECT* FROM euribor_daily_rates_import;
DESC euribor_daily_rates_import;

ALTER TABLE euribor_daily_rates_import
MODIFY myUnknownColumn DATE;

ALTER TABLE euribor_daily_rates_import
RENAME COLUMN myUnknownColumn TO date;

INSERT INTO econ_indicators_values
SELECT date, 'EUR-RFR', `1w`
FROM euribor_daily_rates_import
WHERE year(date) <= 2019;

DROP TABLE euribor_daily_rates_import;

-- 2. IMPORTING AND ADDING €STR FRO M 2020 ONWARDS

SELECT* FROM str_import;
DESC str_import;

-- DELETING ALL ROWS WITH DESCRIPTIVE TEXT 
DELETE 
FROM str_import
WHERE `EST.B.EU000A2X2A25.WT` LIKE '%e%';

ALTER TABLE str_import
MODIFY date DATE;

ALTER TABLE str_import
RENAME COLUMN `EST.B.EU000A2X2A25.WT` TO rate;

INSERT INTO econ_indicators_values
SELECT date, 'EUR-RFR', rate
FROM str_import
WHERE year(date) > 2019;

DROP TABLE str_import;

SELECT*
FROM econ_indicators_values;









