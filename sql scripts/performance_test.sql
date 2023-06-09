
-- This script works to test the runtime for different batch sizes of dates to calculate at a time within the simulations.
DROP PROCEDURE sim_performance_results;

CREATE TABLE performance_testing (
	PRIMARY KEY (id),
    id INT AUTO_INCREMENT,
	batch_size INT,
	start_time TIME,
	end_time TIME,
	total_time TIME);


DELIMITER //
CREATE PROCEDURE sim_performance_results()
BEGIN 

DECLARE counter INT DEFAULT 1;

WHILE counter <= 20 DO

SET @counter = counter;

INSERT INTO performance_testing (batch_size, start_time)
     VALUES (@counter, CURRENT_TIME());

SET @batch_size = counter;

CALL run_simulation();

  UPDATE performance_testing
     SET end_time = CURRENT_TIME()
ORDER BY id DESC 
   LIMIT 1;

  SELECT * 
    FROM performance_testing
ORDER BY total_time ASC;

SET counter = counter + 1;

END WHILE;

UPDATE performance_testing
   SET total_time = TIMEDIFF(end_time, start_time);

  SELECT * 
    FROM performance_testing
ORDER BY total_time ASC;

END //


CALL sim_performance_results();
/*
SELECT * 
    FROM performance_testing
ORDER BY total_time ASC;