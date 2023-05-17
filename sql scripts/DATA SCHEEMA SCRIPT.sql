
/* 
Data has been downloaded manually from Yahoo Finance and imported via a CSV file.

Next step is to declare the date column as a date and not string as it was done automatically in import. 
*/

-- ---FOREX PRICE TABLE CREATION AND MODIFICATION --
ALTER TABLE eur_usd
MODIFY Date date;
-- I will also directly here addapt the table and turn it into the forex_price table.
ALTER TABLE eur_usd
RENAME ForexPrices;

-- CREATING A COLUMN FOR THE FOREIGN KEY REFERENCE
ALTER TABLE forexprices
ADD COLUMN forex_pair varchar(20) NULL;

-- FILLING THE COLUMN WITH DATA (ONLY EURUSD SO FAR SO... FILL IT UP)
UPDATE forexprices
SET forex_pair = 'EURUSD';

--------------------


ALTER TABLE exxy_usd
MODIFY Date date; 

ALTER TABLE exxy_usd
ADD COLUMN isin VARCHAR(50);

ALTER TABLE exxy_usd
ADD FOREIGN KEY (isin) 
	REFERENCES asset(isin);

UPDATE exxy_usd
SET isin = 'DE000A0H0728';

ALTER TABLE exxy_usd
RENAME DE000A0H0728;



-- ---------------------
ALTER TABLE is3v_eur
MODIFY Date date; 

ALTER TABLE is3v_eur
ADD COLUMN isin VARCHAR(50);

ALTER TABLE is3v_eur
ADD FOREIGN KEY (isin) 
	REFERENCES asset(isin);

UPDATE is3v_eur
SET isin = 'IE00BKPT2S34';

ALTER TABLE is3v_eur
RENAME IE00BKPT2S34;

-- ---------------------
ALTER TABLE iwfm_usd
MODIFY Date date; 

ALTER TABLE iwfm_usd
ADD COLUMN isin VARCHAR(50);

ALTER TABLE iwfm_usd
ADD FOREIGN KEY (isin) 
	REFERENCES asset(isin);

UPDATE iwfm_usd
SET isin = 'IE00BP3QZ825';

ALTER TABLE iwfm_usd
RENAME IE00BP3QZ825;
-- ---------------------

ALTER TABLE phau_usd
MODIFY Date date; 

ALTER TABLE phau_usd
ADD COLUMN isin VARCHAR(50);

ALTER TABLE phau_usd
ADD FOREIGN KEY (isin) 
	REFERENCES asset(isin);

UPDATE phau_usd
SET isin = 'JE00B1VS3770';

ALTER TABLE phau_usd
RENAME JE00B1VS3770;
-- -------------------------------------------------------------
/*
CALENDAR TABLE CREATION AND POPULATION
Now we create a calendar table to improve date referencing and slicing
*/

-- BASE TABLE CREATION
CREATE TABLE calendar (
    date DATE NOT NULL PRIMARY KEY,
    y SMALLINT NULL,
    q tinyint NULL,
    m tinyint NULL,
    d tinyint NULL,
    dw tinyint NULL,
    monthName VARCHAR(9) NULL,
    dayName VARCHAR(9) NULL,
    w tinyint NULL,
    isWeekday BINARY(1) NULL
    );
    
/*
Now we create a temporary table to help us populate the calendar by creating a string of up to 99999 consecutive numbers
*/
CREATE TABLE ints ( i tinyint );
INSERT INTO ints VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

-- Calculating number of days between desired start and end dates. -> 36889
SELECT datediff('2050-12-31', '1950-01-01');

-- Populating the table with only the dates in the next step
INSERT INTO calendar (date)
SELECT DATE('1950-01-01') + INTERVAL a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i DAY
FROM ints a JOIN ints b JOIN ints c JOIN ints d JOIN ints e
WHERE (a.i*10000 + b.i*1000 + c.i*100 + d.i*10 + e.i) <= 36889
ORDER BY 1;

-- Derive the other column data from the date column
UPDATE calendar
SET isWeekday = CASE WHEN dayofweek(date) IN (1,7) THEN 0 ELSE 1 END,
	y = YEAR(date),
	q = quarter(date),
	m = MONTH(date),
	d = dayofmonth(date),
	dw = dayofweek(date),
	monthname = monthname(date),
	dayname = dayname(date),
	w = week(date);

DROP TABLE ints;


-- -------------------------------------------------------------
/* NOW LET'S CREATE THE OTHER LOOKUP TABLES */
-- iNSTRUMENTS

-- Creating the ForexPair table

CREATE TABLE ForexPair (
forex_pair varchar(20) PRIMARY KEY,
base_currency varchar(10) NOT NULL,
quote_currency varchar(10) NOT NULL
);

-- ADDINT FREIGN KEY CONSTRINT AND CREATING CONNECTION TO FOREX_TABLE
ALTER TABLE forexprices
ADD FOREIGN KEY (forex_pair)
REFERENCES Forex_Pair(forex_pair);


-- -----------

-- CREATING ASSET VEHICLE TABLE
CREATE TABLE AssetVehicle (
asset_vehicle_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
asset_vehicle VARCHAR(20));

-- POPULATING THE TABLE
INSERT INTO assetvehicle (asset_vehicle)
VALUES	
('ETF'), 
('ETC'), 
('Stock'), 
('Mutual fund'), 
('Bond'), 
('REIT');

-- -----------

-- CREATING THE ASSET TABLE

CREATE TABLE asset (
	isin VARCHAR(50) PRIMARY KEY,
	asset_vehicle SMALLINT UNSIGNED,
	inception_date DATE NULL,
	currency VARCHAR(20),
    FOREIGN KEY (asset_vehicle)
		REFERENCES assetvehicle (asset_vehicle_id),
	FOREIGN KEY (currency) 
		REFERENCES currency(iso_code)
);

INSERT INTO asset
VALUES 
('IE00BP3QZ825', '7', NULL, 'USD'),
('IE00BKPT2S34','7', NULL, 'EUR'),
('DE000A0H0728','7', NULL, 'EUR'),
('JE00B1VS3770','7', NULL, 'EUR');











-- CREATING THE ACCOUNT TABLE + CURRENCY TABLE-----------

CREATE TABLE currency (
    iso_code VARCHAR(10) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    country_or_territory VARCHAR(100),
    fractional_unit VARCHAR(50),
    fractional_to_basic INT
);

CREATE TABLE account (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    account_holder VARCHAR(100) NOT NULL,
    account_currency VARCHAR(10) NOT NULL,
    broker VARCHAR(100),
    FOREIGN KEY (account_currency)
        REFERENCES currency (iso_code)
);

INSERT INTO account (account_holder, account_currency, broker)
VALUES ('Matt', 'EUR', 'Degiro');

CREATE TABLE acc_transaction_type (
    type_id TINYINT PRIMARY KEY AUTO_INCREMENT,
    transaction_type VARCHAR(50) NOT NULL
);

INSERT INTO account_transaction_type (transaction_type)
VALUES 
('deposit'), 
('withdrawal'), 
('transaction_charge'), 
('interest'),
('asset purchase'),
('asset sale'),
('exchange connection fee');





-- ----------------------------
UPDATE asset_prices
SET isin = UPPER(isin);

