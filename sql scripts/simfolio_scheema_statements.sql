
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
    portfolio_id INT PRIMARY KEY AUTO_INCREMENT,
    portfolio_name VARCHAR(100) NOT NULL UNIQUE,
    portfolio_currency VARCHAR(10),
    portfolio_strategy VARCHAR(100) DEFAULT 'Standart',
    portfolio_transaction_cost FLOAT DEFAULT 0);


CREATE TABLE portfolio_asset(
    CONSTRAINT PK_p_name_isin PRIMARY KEY (portfolio_name, symbol),
    CONSTRAINT FK_symbol FOREIGN KEY (symbol)
    REFERENCES asset(symbol),
    CONSTRAINT FK_portfolio_name FOREIGN KEY (portfolio_name)
    REFERENCES portfolio(portfolio_name),
    portfolio_name VARCHAR(100),
    symbol VARCHAR(20),
    allocation FLOAT);

CREATE TABLE strategy(
	PRIMARY KEY (strategy_name),
	strategy_name VARCHAR(100),
	rebalancing_type ENUM('deviation', 'period', 'none') DEFAULT 'none',
	period ENUM('daily', 'weekly', 'monthly', 'quarterly', 'semi-annually', 'annually') DEFAULT NULL,
	leverage FLOAT DEFAULT 0,
	lev_rebalancing INT UNSIGNED DEFAULT NULL,
	min_rebalancing INT UNSIGNED DEFAULT NULL,
	rel_rebalancing INT UNSIGNED DEFAULT NULL);



--------------------------

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
last_close FLOAT DEFAULT NULL
);

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
last_rate FLOAT
);

