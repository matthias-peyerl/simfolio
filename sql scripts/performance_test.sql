UPDATE performance_testing
SET total_time = TIMEDIFF(end_time, start_time);

SELECT total_time, AVG(batch_size) 
FROM performance_testing
GROUP BY total_time
ORDER BY total_time ASC;

DELETE FROM performance_testing
WHERE id IN (67,9,10,11,12,13,14);



SELECT* FROM performance_testing;

DROP TABLE performance_testing;

CREATE TABLE performance_testing (
id INT AUTO_INCREMENT,
batch_size INT,
start_time TIME,
end_time TIME,
total_time TIME
);

ALTER TABLE performance_testing
ADD COLUMN id INT AUTO_INCREMENT PRIMARY KEY;


CALL sim_performance_results();

DROP PROCEDURE sim_performance_results;



DELIMITER //
CREATE PROCEDURE sim_performance_results()
BEGIN 

DECLARE counter INT DEFAULT 1;

WHILE counter <= 50 DO

SET @counter = counter;

INSERT INTO performance_testing (batch_size, start_time)
VALUES (@counter, CURRENT_TIME());

SET @batch_size = counter;

CALL run_simulation();

UPDATE performance_testing
SET end_time = CURRENT_TIME()
ORDER BY id DESC 
LIMIT 1;

SET counter = counter + 1;

END WHILE;

UPDATE performance_testing
SET total_time = TIMEDIFF(end_time, start_time);

SELECT* FROM performance_testing
ORDER BY total_time ASC;

END //





END //
;