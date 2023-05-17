DESC asset;


-- THIS PROCEDURE WILL WORK FOR DATA IMPORTS FROM YAHOO FINANCE
-- THE IMPORTED CSV TABLE NEEDS TO BE NAMED asset_import_data

SET @import_isin 	= 'LU0378818131';
SET @import_ticker	= 'DBZB.DE';
SET @data_provider 	= 'Yahoo Finance';
 
 -- MISSING PART: THE INFORMATION ABOUT THE ASSET IN THE ASSET TABLE!!!
-- INSERT INTO asset (isin, asset_name, ticker, asset_vehicle, asset_class, inception_date, currency)
-- VALUES (@import_isin, 'Global Government Bond UCITS ETF 1C EUR Hedged', @import_ticker, 'ETP', 'Bond', (SELECT min(date) FROM asset_prices WHERE isin = @import_isin GROUP BY date LIMIT 1), 'EUR');

CALL asset_data_import(@import_isin, @import_ticker, @data_provider);

DELIMITER //
CREATE PROCEDURE asset_data_import(
import_isin VARCHAR(50),
import_ticker VARCHAR(50),
data_provider VARCHAR(50))
BEGIN 

DROP TABLE IF EXISTS asset_table;

ALTER TABLE data_import
MODIFY Date date;

SET @min_date_imp = (SELECT MIN(date) FROM data_import);

CREATE TABLE asset_table AS
SELECT c.date, open, high, low, close, `Adj Close` adj_close, volume,
IF(close IS NOT NULL, close, COALESCE((LAG(close,1) OVER (ORDER BY c.date)),
										(LAG(close,2) OVER (ORDER BY c.date)),
										(LAG(close,3) OVER (ORDER BY c.date)),
                                        (LAG(close,4) OVER (ORDER BY c.date)),
                                        (LAG(close,5) OVER (ORDER BY c.date))
									)) last_close													
FROM data_import d
RIGHT JOIN calendar c
ON c.date = d.date
WHERE c.date BETWEEN @min_date_imp and current_date();

ALTER TABLE asset_table
ADD COLUMN isin varchar(20), --  DEFAULT 'import_placeholder',
ADD COLUMN data_provider VARCHAR(100),
ADD COLUMN ticker VARCHAR(20);

UPDATE asset_table
SET 
isin			= import_isin,
data_provider 	= data_provider,
ticker 			= import_ticker;

INSERT INTO asset_prices 
SELECT date, isin, ticker, data_provider, open, high, low, close, last_close, adj_close, volume
FROM asset_table;

DROP TABLE asset_table;

SELECT*
FROM asset_prices
WHERE isin = import_isin;

END //
