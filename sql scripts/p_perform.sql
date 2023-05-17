

SELECT*
FROM p_hist;

-- FIRST THE INSTRUMENT PERFORMANCE
-- THEN THE PORTFOLIO PERFORMANCE
-- THEN THE ACCOUNT PERFORMANCE

DROP TABLE p_perform;

CREATE TABLE p_perform (
id INT PRIMARY KEY AUTO_INCREMENT,
date DATE UNIQUE, 
a1_price FLOAT,
a1_currency VARCHAR(10),
a1_forex_pair VARCHAR(
a1_fx_rate FLOAT,
a1_local_change_d FLOAT,
a1_local_change_w FLOAT,
a1_local_change_m FLOAT,
a1_local_change_q FLOAT,
a1_local_change_y FLOAT,
a1_p_price FLOAT,
a1_portfolio_change_d FLOAT,
a1_portfolio_change_w FLOAT,
a1_portfolio_change_m FLOAT,
a1_portfolio_change_q FLOAT,
a1_portfolio_change_y FLOAT
);

INSERT INTO p_perform (date, a1_price)
SELECT date, a1_price FROM p_hist ORDER BY date DESC;

UPDATE p_perform t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_d = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform t1
JOIN (SELECT date, a1_price, LAG(a1_price,7) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_w = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price,7) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_w = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price,30) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_m = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price,90) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_q = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform t1 -- stock_prices t1
JOIN (SELECT date, a1_price, LAG(a1_price,365) OVER (ORDER BY date) AS prev_price FROM p_perform) t2
ON t1.date = t2.date
SET t1.a1_local_change_y = ((t1.a1_price - t2.prev_price) / t2.prev_price) * 100;

UPDATE p_perform
SET  
a1_currency 			=	@a1_currency,
a1_fx_rate				= 	(SELECT a1_fx_rate FROM p_hist WHERE date = p_perform.date);
a1_p_price				=	CASE 
							WHEN a1_forex_pair = CONCAT(@a1_currency, @p_currency) THEN a1_amount * a1_price * a1_fx_rate
                            ELSE a1_amount * a1_price / a1_fx_rate
							END,
a1_portfolio_change_d	=	
a1_portfolio_change_w 	=
a1_portfolio_change_m 	=
a1_portfolio_change_q 	=
a1_portfolio_change_y 	=

;

SELECT*
FROM p_perform;