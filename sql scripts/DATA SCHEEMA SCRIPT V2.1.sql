-- 1. 	CREATING FACT TABLES
-- 1.1 	CREATING THE FOREX_PRICES TABLE AND POPULATING IT WITH EURUSD DATA
-- 		
-- 		the data has been importaed manually
-- 		PRIMARY KEY is the combination of date and forex_pair

CREATE TABLE forex_prices (
	date DATE,
    forex_pair VARCHAR(10),
    open DOUBLE, 
    high DOUBLE,
	low DOUBLE,
	close DOUBLE,
    CONSTRAINT PK_forex_prices PRIMARY KEY (date, forex_pair)
);

-- 		Price data has been imported from CSV (source:Yahoo Finance) as eur_usd
-- 		We need to 
-- 		1. Set date column as Date format
-- 		2. Add a column for the forex_pair and populate it
-- 		3. Add the resulting table into the main Forex_prices table

ALTER TABLE eur_usd
MODIFY Date date;
ALTER TABLE eur_usd
ADD COLUMN forex_pair varchar(10);
UPDATE eur_usd
SET forex_pair = 'EURUSD';

INSERT INTO forex_prices (date, forex_pair, open, high, low, close)
SELECT date, forex_pair, open, high, low, close
FROM eur_usd;

-- 		1.2 CREATING THE ASSET_PRICES TABLE AND POPULATING IT
-- 		We create a table, same as the forex_prices table
-- 		Then we populate it with some instruments with their ISIN as identifier
-- 		the data has been importaed manually
-- 		PRIMARY KEY is the combination of date and isin

CREATE TABLE asset_prices (
	date DATE,
    isin VARCHAR(20),
    open DOUBLE, 
    high DOUBLE,
	low DOUBLE,
	close DOUBLE,
    adj_close DOUBLE,
    volume DOUBLE,
    CONSTRAINT PK_asset_prices PRIMARY KEY (date, isin)
);

-- 		Price data have been imported from CSV (source:Yahoo Finance) into tables named by their isin
-- 		We need to 
-- 		1. Set date column as Date format
-- 		2. Add a column for the isin and populate it as per default with the respective isin
-- 		3. Add the resulting tables into the main asset_prices table

DROP 
;
ALTER TABLE de000a0h0728
-- ADD COLUMN isin varchar(20) DEFAULT 'DE000A0H0728',
ADD COLUMN data_provider VARCHAR(100) DEFAULT 'Yahoo Finance',
ADD COLUMN ticker VARCHAR(20) DEFAULT 'EXXY.AS';

SET @min_date_de000a0h0728 = (SELECT MIN(d.date) FROM de000a0h0728);


SELECT*
FROM de000a0h0728;

MODIFY Date date;
ALTER TABLE ie00bkpt2s34
MODIFY Date date;
ALTER TABLE ie00bp3qz825
MODIFY Date date;
ALTER TABLE je00b1vs3770
MODIFY Date date;

DROP TABLE _asset_de000a0h0728;

CREATE TABLE _asset_de000a0h0728 AS;
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
																	(LAG(close,2) OVER (ORDER BY c.date)) -- ,
																	-- (LAG(close,3) OVER (ORDER BY c.date)),
                                                                    -- (LAG(close,4) OVER (ORDER BY c.date)),
                                                                    -- (LAG(close,5) OVER (ORDER BY c.date))
                                                                    )) last_close,
isin, ticker, data_provider														
FROM de000a0h0728 d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN /*'2008-01-02' */ (SELECT MIN(d.date) FROM de000a0h0728) and current_date();(SELECT MIN(d.date)
						FROM de000a0h0728)
;

SELECT MIN(date) FROM de000a0h0728;



;SELECT*
FROM _asset_de000a0h0728;

DROP TABLE _asset_de000a0h0728;


AND 4 IS NOT NULL;

UPDATE de000a0h0728
SET last_close = 
;
SELECT date, IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY date)),0)) price
FROM de000a0h0728;


0);


/*
DESC import_de000a0h0728;

DROP TABLE de000a0h0728;

ALTER TABLE import_de000a0h0728
MODIFY Date date,
ADD COLUMN isin varchar(20) DEFAULT 'DE000A0H0728',
ADD COLUMN last_close FLOAT;

CREATE TABLE asset_de000a0h0728 AS
SELECT c.date, open, high, low, close, last_close, `Adj close`, volume, isin
FROM calendar c
LEFT JOIN import_de000a0h0728 a
ON c.date = a.date
WHERE c.date >= (SELECT MIN(date) FROM import_de000a0h0728)
;

SELECT c.date, open, high, low, close, last_close, `Adj close`, volume, isin
FROM calendar c
LEFT JOIN import_de000a0h0728 a
ON c.date = a.date
-- WHERE a.date IS NULL OR a.date >= (SELECT MIN(date) FROM import_de000a0h0728)

UNION ALL

SELECT c.date, open, high, low, close, last_close, `Adj close`, volume, isin
FROM calendar c
RIGHT JOIN import_de000a0h0728 a
ON c.date = a.date
WHERE a.date IS NULL; -- OR a.date >= (SELECT MIN(date) FROM import_de000a0h0728)

SELECT c.date, a.open, a.high, a.low, a.close, a.last_close, a.`Adj close`, a.volume, a.isin
FROM calendar c
LEFT JOIN import_de000a0h0728 a ON c.date = a.date
UNION ALL
SELECT a.date, a.open, a.high, a.low, a.close, a.last_close, a.`Adj close`, a.volume, a.isin
FROM calendar c
RIGHT JOIN import_de000a0h0728 a ON c.date = a.date
WHERE c.date IS NULL;
;

DESC import_de000a0h0728;


SELECT c.date, open, high, low, close, last_close, `Adj close`, volume, isin
FROM calendar c
LEFT JOIN import_de000a0h0728 a
ON c.date = a.date;


SELECT*
FROM asset_de000a0h0728;

*/
ALTER TABLE de000a0h0728
ADD COLUMN isin varchar(20) DEFAULT 'DE000A0H0728';
ALTER TABLE ie00bkpt2s34
ADD COLUMN isin varchar(20) DEFAULT 'IE00BKPT2S34';
ALTER TABLE ie00bp3qz825
ADD COLUMN isin varchar(20) DEFAULT 'IE00BP3QZ825';
ALTER TABLE je00b1vs3770
ADD COLUMN isin varchar(20) DEFAULT 'JE00B1VS3770';


INSERT INTO asset_prices (date, open, high, low, close, adj_close, volume, isin)
SELECT*
FROM de000a0h0728
UNION
SELECT*
FROM ie00bkpt2s34
UNION
SELECT*
FROM ie00bp3qz825
UNION
SELECT*
FROM je00b1vs3770;


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
