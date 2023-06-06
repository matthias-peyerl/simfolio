
-- 1. Creating the database
  CREATE DATABASE simfolio_db;
  
-- 2. Creating lookup tables
DROP TABLE calendar;

-- 2.1. Creating the caledar table and populating it
 CREATE TABLE calendar (
    PRIMARY KEY (date),
    date DATE NOT NULL,
    y SMALLINT NULL,
    q TINYINT NULL,
    m TINYINT NULL,
    d TINYINT NULL,
    day_of_week TINYINT NULL,
    month_name VARCHAR(9) NULL,
    day_name VARCHAR(9) NULL,
    week_of_year TINYINT NULL,
    is_weekday BINARY(1) NULL);

-- Creating a table to help populate the calendar table by creating a string of up to 99999 consecutive numbers
CREATE TABLE ints ( i tinyint );

INSERT INTO ints 
     VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Calculating number of days between desired start and end dates. -> 36889
SET @num_of_days = (SELECT datediff('2050-12-31', '1950-01-01'));

-- Populating the table with only the dates in the next step
INSERT INTO calendar (date)
     SELECT DATE('1950-01-01') + INTERVAL a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i DAY
       FROM ints a 
	   JOIN ints b 
	   JOIN ints c 
       JOIN ints d 
       JOIN ints e
      WHERE (a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i) <= @num_of_days
   ORDER BY 1;

-- Derive the other column data from the date column
UPDATE calendar
   SET 
   	y 				= YEAR(date),
	q 				= quarter(date),
	m 				= MONTH(date),
	d 				= dayofmonth(date),
	day_of_week 	= dayofweek(date),
	month_name 		= monthname(date),
	day_name 		= dayname(date),
	week_of_year	= week(date),
    is_weekday 		= CASE 
					  WHEN dayofweek(date) IN (1,7) THEN 0 
                      ELSE 1 
                      END;

DROP TABLE ints;

CREATE TABLE forex_pair (
forex_pair varchar(20) PRIMARY KEY,
base_currency varchar(10) NOT NULL,
quote_currency varchar(10) NOT NULL);

CREATE TABLE currency (
    iso_code VARCHAR(10) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    country_or_territory VARCHAR(100),
    fractional_unit VARCHAR(50),
    fractional_to_basic INT);
        
    CREATE TABLE asset (
	PRIMARY KEY (symbol),
	CONSTRAINT FK_currency FOREIGN KEY (currency) 
	REFERENCES currency(iso_code),
    symbol VARCHAR(50),
    asset_name VARCHAR(200),
	inception_date DATE NULL,
    end_date DATE NULL,
	currency VARCHAR(20));

CREATE TABLE portfolio (
	CONSTRAINT FK_p_currency FOREIGN KEY (portfolio_currency)
	REFERENCES currency(iso_code),
	CONSTRAINT FK_p_strategy_id FOREIGN KEY (portfolio_strategy)
	REFERENCES strategy(strategy_id),   
    portfolio_id INT PRIMARY KEY AUTO_INCREMENT,
    portfolio_name VARCHAR(100) NOT NULL UNIQUE,
    portfolio_currency VARCHAR(10),
    portfolio_strategy VARCHAR(100),
    portfolio_transaction_cost FLOAT DEFAULT 0);

CREATE TABLE portfolio_asset(
    CONSTRAINT PK_p_id_symbol PRIMARY KEY (portfolio_id, symbol),
    CONSTRAINT FK_symbol FOREIGN KEY (symbol)
    REFERENCES asset(symbol),
    CONSTRAINT FK_portfolio_id FOREIGN KEY (portfolio_id)
    REFERENCES portfolio(portfolio_id),
    portfolio_id INT,
    symbol VARCHAR(20),
    allocation FLOAT);

CREATE TABLE strategy(
	PRIMARY KEY (strategy_id),
    strategy_id INT AUTO_INCREMENT,
	strategy_name VARCHAR(100),
	rebalancing_type ENUM('deviation', 'period', 'none') DEFAULT 'none',
	period ENUM('daily', 'weekly', 'monthly', 'quarterly', 'semi-annually', 'annually') DEFAULT NULL,
	leverage FLOAT DEFAULT 0,
	lev_rebalancing INT UNSIGNED DEFAULT NULL,
	min_rebalancing INT UNSIGNED DEFAULT NULL,
	rel_rebalancing INT UNSIGNED DEFAULT NULL);

-- FACT TABLES
CREATE TABLE asset_prices (
CONSTRAINT PK_date_symbol_exchange_data_prov 
PRIMARY KEY (date, symbol, exchange, data_provider),
date DATE, 
symbol VARCHAR(10),
exchange VARCHAR(10),
data_provider VARCHAR(50),
open FLOAT,
high FLOAT,
low FLOAT,
close FLOAT,
last_close FLOAT DEFAULT NULL);

CREATE TABLE forex_prices (
	CONSTRAINT PK_forex_prices 
    PRIMARY KEY (date, forex_pair),
    date DATE,
    forex_pair VARCHAR(10),
    data_provider VARCHAR(100),
    open FLOAT, 
    high FLOAT,
	low FLOAT,
	close FLOAT,
    last_close FLOAT DEFAULT NULL);

CREATE TABLE econ_indicator(
	symbol VARCHAR(20) PRIMARY KEY,
	name VARCHAR(50),
	description TEXT);

CREATE TABLE econ_indicator_values (
	CONSTRAINT PK_date_name PRIMARY KEY (date, symbol),
	CONSTRAINT FK_indicator_name FOREIGN KEY (symbol)
	REFERENCES econ_indicator(symbol),
	date DATE,
	symbol VARCHAR(50), 
	rate FLOAT,
	last_rate FLOAT);

CREATE TABLE simulation (
	PRIMARY KEY (sim_id),
	FOREIGN KEY (portfolio_id)
	REFERENCES portfolio(portfolio_id),
	FOREIGN KEY (strategy_id)
	REFERENCES strategy(strategy_id),
	sim_id INT UNSIGNED,
	timestamp TIMESTAMP,
	portfolio_id VARCHAR(100),
	strategy_id VARCHAR(100),
	start_date DATE,
	end_date DATE,
	tot_return FLOAT,
	medium_annual_return FLOAT,
	medium_rfr FLOAT,
	maximum_dd FLOAT,
	standard_dev_annual_mean FLOAT,
	sharp_ratio_annual_mean FLOAT,
	sortino_ratio_annual_mean FLOAT);

CREATE TABLE simulation_data (
	sim_id INT,
	portfolio_id VARCHAR(100),
	strategy_id VARCHAR(100),
	sim_timestamp TIMESTAMP,
	date DATE,
	a1_symbol VARCHAR(20),
	a1_price FLOAT,
	a1_forex_pair VARCHAR(10),
	a1_fx_rate FLOAT,
	a1_portfolio_price FLOAT,
	a1_amount INT,
	a1_amount_change INT,
	a1_local_value FLOAT,
	a1_portfolio_value FLOAT,
	a1_local_change_d FLOAT,
	a1_portfolio_change_d FLOAT,
	a2_symbol VARCHAR(20),
	a2_price FLOAT,
	a2_forex_pair VARCHAR(10),
	a2_fx_rate FLOAT,
	a2_portfolio_price FLOAT,
	a2_amount INT,
	a2_amount_change INT,
	a2_local_value FLOAT,
	a2_portfolio_value FLOAT,
	a2_local_change_d FLOAT,
	a2_portfolio_change_d FLOAT,
	a3_symbol VARCHAR(20),
	a3_price FLOAT,
	a3_forex_pair VARCHAR(10),
	a3_fx_rate FLOAT,
	a3_portfolio_price FLOAT,
	a3_amount INT,
	a3_amount_change INT,
	a3_local_value FLOAT,
	a3_portfolio_value FLOAT,
	a3_local_change_d FLOAT,
	a3_portfolio_change_d FLOAT,
	a4_symbol VARCHAR(20),
	a4_price FLOAT,
	a4_forex_pair VARCHAR(10),
	a4_fx_rate FLOAT,
	a4_portfolio_price FLOAT,
	a4_amount INT,
	a4_amount_change INT,
	a4_local_value FLOAT,
	a4_portfolio_value FLOAT,
	a4_local_change_d FLOAT,
	a4_portfolio_change_d FLOAT,
	a5_symbol VARCHAR(20),
	a5_price FLOAT,
	a5_forex_pair VARCHAR(10),
	a5_fx_rate FLOAT,
	a5_portfolio_price FLOAT,
	a5_amount INT,
	a5_amount_change INT,
	a5_local_value FLOAT,
	a5_portfolio_value FLOAT,
	a5_local_change_d FLOAT,
	a5_portfolio_change_d FLOAT,
	a6_symbol VARCHAR(20),
	a6_price FLOAT,
	a6_forex_pair VARCHAR(10),
	a6_fx_rate FLOAT,
	a6_portfolio_price FLOAT,
	a6_amount INT,
	a6_amount_change INT,
	a6_local_value FLOAT,
	a6_portfolio_value FLOAT,
	a6_local_change_d FLOAT,
	a6_portfolio_change_d FLOAT,
	a7_symbol VARCHAR(20),
	a7_price FLOAT,
	a7_forex_pair VARCHAR(10),
	a7_fx_rate FLOAT,
	a7_portfolio_price FLOAT,
	a7_amount INT,
	a7_amount_change INT,
	a7_local_value FLOAT,
	a7_portfolio_value FLOAT,
	a7_local_change_d FLOAT,
	a7_portfolio_change_d FLOAT,
	a8_symbol VARCHAR(20),
	a8_price FLOAT,
	a8_forex_pair VARCHAR(10),
	a8_fx_rate FLOAT,
	a8_portfolio_price FLOAT,
	a8_amount INT,
	a8_amount_change INT,
	a8_local_value FLOAT,
	a8_portfolio_value FLOAT,
	a8_local_change_d FLOAT,
	a8_portfolio_change_d FLOAT,
	a9_symbol VARCHAR(20),
	a9_price FLOAT,
	a9_forex_pair VARCHAR(10),
	a9_fx_rate FLOAT,
	a9_portfolio_price FLOAT,
	a9_amount INT,
	a9_amount_change INT,
	a9_local_value FLOAT,
	a9_portfolio_value FLOAT,
	a9_local_change_d FLOAT,
	a9_portfolio_change_d FLOAT,
	a10_symbol VARCHAR(20),
	a10_price FLOAT,
	a10_forex_pair VARCHAR(10),
	a10_fx_rate FLOAT,
	a10_portfolio_price FLOAT,
	a10_amount INT,
	a10_amount_change INT,
	a10_local_value FLOAT,
	a10_portfolio_value FLOAT,
	a10_local_change_d FLOAT,
	a10_portfolio_change_d FLOAT,
	a1_allocation FLOAT,
	a2_allocation FLOAT,
	a3_allocation FLOAT,
	a4_allocation FLOAT,
	a5_allocation FLOAT,
	a6_allocation FLOAT,
	a7_allocation FLOAT,
	a8_allocation FLOAT,
	a9_allocation FLOAT,
	a10_allocation FLOAT,
	p_value FLOAT,
	usd_exposure_usd FLOAT,
	usd_exposure_eur FLOAT,
	eur_exposure FLOAT,
	buy FLOAT,
	sell FLOAT,
	transaction_costs FLOAT,
	interest FLOAT,
	deposit FLOAT,
	withdrawl FLOAT,
	tot_change FLOAT,
	acc_balance FLOAT,
	tot_balance FLOAT,
	leverage_rate FLOAT,
	tot_balance_change_d FLOAT);

	CREATE TABLE sim_performance_monthly (
	sim_id INT,
	month INT,
	year YEAR,
	period_return FLOAT,
	period_rfr FLOAT,
	maximum_dd FLOAT,
	var FLOAT, 
	standard_dev FLOAT,
	sharp_ratio FLOAT,
	sortino_ratio FLOAT);

CREATE TABLE sim_performance_yearly(
	sim_id INT,
	year YEAR, 
	period_return FLOAT,
	period_rfr FLOAT,
	maximum_dd FLOAT,
	standard_dev FLOAT,
	sharp_ratio FLOAT,
	sortino_ratio FLOAT);
