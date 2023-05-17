-- 1. 	CREATING FACT TABLES
-- 1.1 	CREATING THE FOREX_PRICES TABLE AND POPULATING IT WITH EURUSD DATA
-- 		
-- 		the data has been importaed manually
-- 		PRIMARY KEY is the combination of date and forex_pair

DROP TABLE forex_prices;

CREATE TABLE forex_prices (
	date DATE,
    forex_pair VARCHAR(10),
    data_provider VARCHAR(100),
    open FLOAT, 
    high FLOAT,
	low FLOAT,
	close FLOAT,
    mid FLOAT,
    last_close FLOAT,
    CONSTRAINT PK_forex_prices PRIMARY KEY (date, forex_pair)
);


-- 		Price data has been imported from CSV (source:Yahoo Finance) as eur_usd
-- 		We need to 
-- 		1. Set date column as Date format
-- 		2. Add a column for the forex_pair and populate it
-- 		3. Add the resulting table into the main Forex_prices table

ALTER TABLE eur_usd
MODIFY Date date;

SET @min_date_eur_usd = (SELECT MIN(date) FROM eur_usd);

CREATE TABLE _forex_eur_usd AS
SELECT c.date, open, high, low, close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM eur_usd d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_eur_usd and current_date();

ALTER TABLE _forex_eur_usd
-- ADD COLUMN forex_pair varchar(20) DEFAULT 'EURUSD',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance';

INSERT INTO forex_prices 
SELECT date, forex_pair, data_provider, open, high, low, close, last_close
FROM _forex_eur_usd;

SELECT*
FROM _forex_eur_usd;

SELECT*
FROM forex_prices;

-- 		1.2 CREATING THE ASSET_PRICES TABLE AND POPULATING IT
-- 		We create a table, same as the forex_prices table
-- 		Then we populate it with some instruments with their ISIN as identifier
-- 		the data has been importaed manually
-- 		PRIMARY KEY is the combination of date and isin

DROP TABLE asset_prices;

CREATE TABLE asset_prices (
	date DATE,
    isin VARCHAR(20),
    ticker VARCHAR(20),
    data_provider VARCHAR(100),
    open FLOAT, 
    high FLOAT,
	low FLOAT,
	close FLOAT,
    mid FLOAT,
    last_close FLOAT,
    adj_close FLOAT,
    volume FLOAT,    
    CONSTRAINT PK_asset_prices PRIMARY KEY (date, isin, ticker, data_provider)
);




SELECT* -- ;
-- DELETE
FROM asset_prices
WHERE isin = 'IE00BP3QZ825';

-- 		Price data have been imported from CSV (source:Yahoo Finance) into tables named by their isin
-- 		We need to 
-- 		1. Set date column as Date format
-- 		2. Add a column for the isin and populate it as per default with the respective isin
-- 		3. Add the resulting tables into the main asset_prices table

-- FIRST ASSET 

ALTER TABLE de000a0h0728
MODIFY Date date;

SET @min_date_de000a0h0728 = (SELECT MIN(date) FROM de000a0h0728);

CREATE TABLE _asset_de000a0h0728 AS
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM de000a0h0728 d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_de000a0h0728 and current_date();

ALTER TABLE _asset_de000a0h0728
ADD COLUMN isin varchar(20) DEFAULT 'DE000A0H0728',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance',
ADD COLUMN ticker VARCHAR(20) DEFAULT 'EXXY.AS';

INSERT INTO asset_prices 
SELECT date, isin, ticker, data_provider, open, high, low, close, last_close, adj_close, volume
FROM _asset_de000a0h0728;

-- SECOND ASSET

ALTER TABLE ie00bkpt2s34
MODIFY Date date;

SET @min_date_ie00bkpt2s34 = (SELECT MIN(date) FROM ie00bkpt2s34);

CREATE TABLE _asset_ie00bkpt2s34 AS
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM ie00bkpt2s34 d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_ie00bkpt2s34 and current_date();

ALTER TABLE _asset_ie00bkpt2s34
ADD COLUMN isin varchar(20) DEFAULT 'IE00BKPT2S34',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance',
ADD COLUMN ticker VARCHAR(20) DEFAULT 'IS3V.DE';

INSERT INTO asset_prices 
SELECT date, isin, ticker, data_provider, open, high, low, close, last_close, adj_close, volume
FROM _asset_ie00bkpt2s34;

-- THIRD ASSET

ALTER TABLE ie00bp3qz825
MODIFY Date date;

SET @min_date_ie00bp3qz825 = (SELECT MIN(date) FROM ie00bp3qz825);

CREATE TABLE _asset_ie00bp3qz825 AS
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM ie00bp3qz825 d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_ie00bp3qz825 and current_date();

ALTER TABLE _asset_ie00bp3qz825
ADD COLUMN isin varchar(20) DEFAULT 'IE00BP3QZ825',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance',
ADD COLUMN ticker VARCHAR(20) DEFAULT 'IWMO.L';

INSERT INTO asset_prices 
SELECT date, isin, ticker, data_provider, open, high, low, close, last_close, adj_close, volume
FROM _asset_ie00bp3qz825;

-- ASSET 4

ALTER TABLE je00b1vs3770
MODIFY Date date;

SET @min_date_je00b1vs3770 = (SELECT MIN(date) FROM je00b1vs3770);

CREATE TABLE _asset_je00b1vs3770 AS
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM je00b1vs3770 d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_je00b1vs3770 and current_date();

ALTER TABLE _asset_je00b1vs3770
ADD COLUMN isin varchar(20) DEFAULT 'JE00B1VS3770',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance',
ADD COLUMN ticker VARCHAR(20) DEFAULT 'PHAU.L';

INSERT INTO asset_prices 
SELECT date, isin, ticker, data_provider, open, high, low, close, last_close, adj_close, volume
FROM _asset_je00b1vs3770;



-- 		1.3 CREATING THE TRANSACTIONS TABLE AND POPULATING IT WITH DATA

CREATE TABLE inv_transactions (
	inv_transaction_id SMALLINT PRIMARY KEY AUTO_INCREMENT,
	date DATE,
	time TIME, 
	isin VARCHAR(50),
	forex_rate DOUBLE,
	price DOUBLE,
    currency VARCHAR(10),
	amount INT,
    original_value DOUBLE,
    local_value DOUBLE,
	transaction_cost DOUBLE,
	trading_account INT DEFAULT 1,
    order_id VARCHAR(100)
);


-- PREPARING THE TRANSACTIONS_IMPORT TABLE FROM DEGIRO
-- IMPORTANT:	Before importing the CSV data, set Transaction cost column = 0 and the respective currency column = 'EUR' where it is empty, else the row will not be imported
-- 1. Date conversion
-- 2. Time conversion
-- 3. Forex rate to number format
-- 4. Price format conversion


-- 1. Date conversion
UPDATE transactions_import
SET fecha = STR_TO_DATE(Fecha, '%d/%m/%Y');

ALTER TABLE transactions_import
MODIFY fecha date;

-- 2. Time conversion
ALTER TABLE transactions_import
MODIFY Hora time;

-- 3. Forex rate 
UPDATE transactions_import
SET `Tipo de cambio` = 1 
WHERE `Tipo de cambio` = '';

ALTER TABLE transactions_import
MODIFY `Tipo de cambio` DOUBLE;

-- 4. Price format conversion
UPDATE transactions_import
SET `Precio` = REPLACE(`Precio`,'.','');

ALTER TABLE transactions_import
MODIFY `Precio` DOUBLE;

SELECT precio
FROM transactions_import;

UPDATE transactions_import
SET `Precio` = `Precio`/10000;

-- INSERTING DATA INTO TRANSACTIONS TABLE
-- CREARING BTHE DATA FROM THE TABLE
;
INSERT INTO inv_transactions (
	date, time, isin, forex_rate, price, currency, amount, 
	original_value, local_value, transaction_cost, order_id)
SELECT fecha, hora, isin, `Tipo de cambio`, Precio, MyUnknownColumn, `NÃºmero`,
	Valor, `Valor local`, `Costes de transacciÃ³n`, `ID Orden`
FROM transactions_import;

DELETE
FROM transactions_import;

-- 		1.3 CREATING THE ACCOUNT_TRANSACTIONS TABLE AND POPULATING IT WITH DATA
-- 			1. Creating a table with the transaction types 
-- 			2. 

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

CREATE TABLE acc_transactions (
	acc_transaction_id INT PRIMARY KEY AUTO_INCREMENT, 
    date DATE,
    time TIME,
    type VARCHAR(50),
    account_id SMALLINT DEFAULT 1,
    amount SMALLINT
);

-- 		Preparing the acc_trans_import table data 
-- 		1. Date conversion
-- 		2. Time conversion
-- 		3. Amount column into number format

-- 1. Date conversion
-- without the following adjustment the error 1411 (invalid date for st_to_date function was triggered)
SET @@SESSION.sql_mode='ALLOW_INVALID_DATES';

UPDATE acc_trans_import
SET Fecha = STR_TO_DATE(Fecha, '%d-%m-%Y');

ALTER TABLE acc_trans_import
MODIFY fecha date;

-- 2. Time conversion
ALTER TABLE acc_trans_import
MODIFY Hora time;

-- 3. Adjusting date format (coma to point decimals)
UPDATE acc_trans_import
SET `MyUnknownColumn` = REPLACE(`MyUnknownColumn`,',','.');

-- 3. Inserting interest payments
INSERT INTO acc_transactions (date, time, type, amount, account_id)
SELECT fecha, Hora, 'interest', `MyUnknownColumn`, 1
FROM acc_trans_import
WHERE `DescripciÃ³n` = 'InterÃ©s' -- OR `DescripciÃ³n` LIKE 'ComisiÃ³n de conectividad con el mercado%')
AND year(fecha) >= 2022
AND `ID Orden` = ''
AND `VariaciÃ³n` <> ''
AND MyUnknownColumn <> 0;

-- 4. Inserting exchange connection fee
INSERT INTO acc_transactions (date, time, type, amount, account_id)
SELECT fecha, Hora, 'exchange connection fee', `MyUnknownColumn`, 1
FROM acc_trans_import
WHERE `DescripciÃ³n` LIKE 'ComisiÃ³n de conectividad con el mercado%'
AND year(fecha) >= 2022
AND `ID Orden` = ''
AND `VariaciÃ³n` <> ''
AND MyUnknownColumn <> 0;

-- 4. Inserting deposits
INSERT INTO acc_transactions (date, time, type, amount, account_id)
SELECT fecha, Hora, 'deposit', `MyUnknownColumn`, 1
FROM acc_trans_import
WHERE year(fecha) >= 2022
AND `ID Orden` = ''
AND `VariaciÃ³n` <> ''
AND MyUnknownColumn <> 0
AND `MyUnknownColumn` > 1000
AND `DescripciÃ³n`LIKE '%Deposit';

-- 5. Inserting Withdrawls
INSERT INTO acc_transactions (date, time, type, amount, account_id)
SELECT fecha, Hora, 'withdrawal', `MyUnknownColumn`, 1
FROM acc_trans_import
WHERE year(fecha) >= 2022
AND `ID Orden` = ''
AND `VariaciÃ³n` <> ''
AND MyUnknownColumn <> 0
AND `MyUnknownColumn` < -100
AND `DescripciÃ³n`LIKE 'flatex Withdrawal';


SELECT fecha, Hora, 'withdrawal', `MyUnknownColumn`, 1
FROM acc_trans_import
WHERE -- year(fecha) >= 2022
 `ID Orden` = ''
AND `VariaciÃ³n` <> ''
AND MyUnknownColumn <> 0
AND `MyUnknownColumn` < -100
AND `DescripciÃ³n`LIKE 'flatex Withdrawal';











-- 1. 	CREATING THE LOOKUP TABLES

SELECT*
FROM inv_transactions;

SELECT*
FROM asset;

DESC asset;
-- TESTS ---------------------------------
