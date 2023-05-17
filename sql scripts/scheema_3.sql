
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

SELECT COALESCE((SELECT leverage FROM strategies WHERE strategy_name = @strategy)/100+1,1);










