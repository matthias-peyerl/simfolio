-- 		CREATING THE ASSET VEHICLE TABLE

CREATE TABLE asset_vehicle (
asset_vehicle_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
asset_vehicle VARCHAR(20) UNIQUE NOT NULL);

-- POPULATING THE TABLE
INSERT INTO asset_vehicle (asset_vehicle)
VALUES	
('ETP'),  
('Stock'), 
('Mutual fund'), 
('Bond'), 
('REIT'),
('Index');


-- 		CREATING THE ASSET CLASS TABLE

 CREATE TABLE asset_class (
asset_class_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
asset_class VARCHAR(20) UNIQUE NOT NULL);

INSERT INTO asset_class (asset_class)
VALUES	
('Equity'),  
('Bond'), 
('Commodity'),
('Gold'),
('Currency'),
('Crypto asset'),
('Index');

SELECT*
FROM asset_class;


-- 		CREATING THE CURRENCY TABLE
-- 		Table will be populated will fairly complete global currency data

CREATE TABLE currency (
    iso_code VARCHAR(10) PRIMARY KEY,
    currency_name VARCHAR(100) NOT NULL,
    country_or_territory VARCHAR(100),
    fractional_unit VARCHAR(50),
    fractional_to_basic INT
);

CREATE TABLE ForexPair (
forex_pair varchar(20) PRIMARY KEY,
base_currency varchar(10) NOT NULL,
quote_currency varchar(10) NOT NULL
);

-- 		CREATING THE ASSET TABLE AND ADDING FIRST EXAMPLE ASSETS

CREATE TABLE asset (
	isin VARCHAR(50) PRIMARY KEY,
    asset_name VARCHAR(200),
    ticker VARCHAR(10),
	asset_vehicle VARCHAR (20),
    asset_class VARCHAR(20),
	inception_date DATE NULL,
	currency VARCHAR(20),
    CONSTRAINT FK_asset_vehicle FOREIGN KEY (asset_vehicle)
		REFERENCES asset_vehicle (asset_vehicle),
	CONSTRAINT FK_asset_class FOREIGN KEY (asset_class)
		REFERENCES asset_class (asset_class),
	CONSTRAINT FK_currency FOREIGN KEY (currency) 
		REFERENCES currency(iso_code)
);

		
INSERT INTO asset
VALUES 
('IE00BP3QZ825', 'iShares Edge MSCI World Momentum Factor UCITS ETF', 'IWMO.L', 'ETP', 'Equity', '2014-10-06','USD'),
('IE00BKPT2S34', 'iShares Global Inflation Linked Govt Bond ETF', 'IS3V.DE', 'ETP', 'Bond', '2020-04-29', 'EUR'),
('DE000A0H0728', 'iShares Diversified Commodity Swap ETF', 'EXXY.AS', 'ETP', 'Commodity', '2008-01-02', 'USD'),
('JE00B1VS3770', 'WisdomTree Physical Gold', 'PHAU.L', 'ETP', 'Gold', '2008-01-02', 'USD');


-- 		CREATING THE PORTFOLIO TABLE WITH PORTFOLIO ID AND PORTFOLIO_NAME

CREATE TABLE portfolio (
	p_id INT PRIMARY KEY AUTO_INCREMENT,
    p_name VARCHAR(100) NOT NULL UNIQUE,
    p_currency VARCHAR(10),
    p_strategy VARCHAR(100) NULL,
    CONSTRAINT FK_p_currency FOREIGN KEY (p_currency)
	REFERENCES currency(iso_code)
);

CREATE TABLE portfolio_assets (
    portfolio_name VARCHAR(100),
    isin VARCHAR(20),
    allocation FLOAT,    
    CONSTRAINT FK_isin FOREIGN KEY (isin)
    REFERENCES asset(isin),
    CONSTRAINT FK_portfolio_name FOREIGN KEY (portfolio_name)
    REFERENCES portfolio(p_name),
    CONSTRAINT PK_p_name_isin PRIMARY KEY (portfolio_name, isin)
    
);

SELECT*
FROM portfolio_assets;

INSERT INTO portfolio (p_name, p_strategy, p_currency)
VALUES ('PT1', NULL, 'EUR');

INSERT INTO portfolio_assets (portfolio_name, isin, allocation)
VALUES 
('PT1', 'IE00BP3QZ825', 35),
('PT1', 'IE00BKPT2S34', 50),
('PT1', 'DE000A0H0728', 8.5),
('PT1', 'JE00B1VS3770', 7.5);
    

















/*  		THIS WAS THE FORMER VERSION OF THE PORTFOLIO TABLE


CREATE TABLE portfolio (
	portfolio_id SMALLINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
    portfolio_name VARCHAR(100),
    portfolio_currency VARCHAR (10),
    asset_1 VARCHAR(100) NOT NULL,
    allocation_1 FLOAT NULL,
    asset_2 VARCHAR(100) NULL,
    allocation_2 FLOAT NULL,
    asset_3 VARCHAR(100) NULL,
    allocation_3 FLOAT NULL,
    asset_4 VARCHAR(100) NULL,
    allocation_4 FLOAT NULL,
	asset_5 VARCHAR(100) NULL,
    allocation_5 FLOAT NULL,
    asset_6 VARCHAR(100) NULL,
    allocation_6 FLOAT NULL,
    asset_7 VARCHAR(100) NULL,
    allocation_7 FLOAT NULL,
    asset_8 VARCHAR(100) NULL,
    allocation_8 FLOAT NULL,
    asset_9 VARCHAR(100) NULL,
    allocation_9 FLOAT NULL,
    asset_10 VARCHAR(100) NULL,
    allocation_10 FLOAT NULL,
    /*CONSTRAINT CHK_isin CHECK (EXISTS (SELECT isin FROM asset WHERE isin = asset_1)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_2)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_3)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_4)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_5)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_6)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_7)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_8)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_9)
    AND EXISTS (SELECT isin FROM asset WHERE isin = asset_10)),
    CONSTRAINT FK_portfolio_currency FOREIGN KEY (portfolio_currency)
    REFERENCES currency(iso_code)
);

DROP TABLE portfolio;
    
-- TRIGGER TO MAKE SURE ALL ASSETS INTRODUCED INTO PORTFOLIOS ARE IN THE ASSET TABLE

*/
/*
DELIMITER $$    
CREATE TRIGGER trg_check_assets
BEFORE INSERT ON portfolio
FOR EACH ROW
BEGIN
    IF NOT (NEW.asset_1 IN (SELECT isin FROM asset)
            AND NEW.asset_2 IN (SELECT isin FROM asset)
            AND NEW.asset_3 IN (SELECT isin FROM asset)
            AND NEW.asset_4 IN (SELECT isin FROM asset)
            AND NEW.asset_5 IN (SELECT isin FROM asset)
            AND NEW.asset_6 IN (SELECT isin FROM asset)
            AND NEW.asset_7 IN (SELECT isin FROM asset)
            AND NEW.asset_8 IN (SELECT isin FROM asset)
            AND NEW.asset_9 IN (SELECT isin FROM asset)
            AND NEW.asset_10 IN (SELECT isin FROM asset))
    THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid asset in portfolio';
    END IF;
END $$
DELIMITER ;


;
DROP TRIGGER trg_check_assets;

*/
