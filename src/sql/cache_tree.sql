SET FOREIGN_KEY_CHECKS=0;
UNLOCK TABLES;

DROP TABLE IF EXISTS `tree`;
CREATE TABLE `tree` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `parentid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idxParentId` (`parentid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE tree
ADD CONSTRAINT fk_tree_parentid -- This is broken in MySQL as of 2019 in that it won't fire triggers
  FOREIGN KEY (parentid)
  REFERENCES tree (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

DROP FUNCTION IF EXISTS `fn_get_tree_path`;
DELIMITER ;;
CREATE FUNCTION `fn_get_tree_path`(inid INT) RETURNS TEXT CHARSET utf8
BEGIN
  DECLARE childparentid INT;
  DECLARE childpath VARCHAR(255);
  DECLARE path TEXT;
    
  SET childparentid = inid;
  SET path = '';
    
  WHILE childparentid IS NOT NULL DO
    SELECT `name`, parentid INTO childpath, childparentid FROM tree WHERE id=childparentid;
    IF (path = '') THEN
      SET path = childpath;
    ELSE
      SET path = CONCAT(childpath, '/', path);
    END IF;
  END WHILE;
    
  RETURN path;
END ;;
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_get_tree_depth`;
DELIMITER ;;
CREATE FUNCTION `fn_get_tree_depth`(inid INT) RETURNS INT
BEGIN
  DECLARE childparentid INT;
  DECLARE depth INT;
    
  SET childparentid = inid;
  SET depth = 1;
    
  WHILE childparentid IS NOT NULL DO
    SELECT parentid INTO childparentid FROM tree WHERE id=childparentid;
    IF childparentid IS NOT NULL THEN
      SET depth = depth + 1;
    END IF;
  END WHILE;
    
  RETURN depth;
END ;;
DELIMITER ;

DROP FUNCTION IF EXISTS `fn_get_tree_superparent`;
DELIMITER ;;
CREATE FUNCTION `fn_get_tree_superparent`(inid INT) RETURNS INT
BEGIN
  DECLARE childparentid INT;
  DECLARE previd INT;
    
  SET childparentid = inid;
    
  WHILE childparentid IS NOT NULL DO
    SET previd = childparentid;
    SELECT parentid INTO childparentid FROM tree WHERE id=childparentid;
  END WHILE;
    
  RETURN previd;
END ;;
DELIMITER ;

-- view calculates path and depth in realtime
DROP TABLE IF EXISTS `v_tree_calcpath`;
DROP VIEW IF EXISTS `v_tree_calcpath`;
CREATE VIEW `v_tree_calcpath` AS 
  SELECT
    id,`name`,parentid,
    fn_get_tree_path(id) AS path,
    fn_get_tree_depth(id) AS depth,
    fn_get_tree_superparent(id) AS superparent
  FROM tree ORDER BY fn_get_tree_path(id);

SET FOREIGN_KEY_CHECKS=1;

-- insert test data
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_generate_test_data$$
CREATE PROCEDURE sp_generate_test_data(maxrecords INT, depth INT, parentid INT)
BEGIN
  DECLARE counter INT;
  DECLARE lastparent INT;
  DECLARE newname VARCHAR(255);
    
  SET counter = 0;
  SET newname = '';
    
  SET max_sp_recursion_depth=255;
    
  WHILE counter < maxrecords DO
    IF parentid IS NULL THEN
      SET newname = concat('super', counter);
    ELSE
      SET newname = concat('child', counter);
    END IF;
    INSERT INTO tree (name, parentid) VALUES (newname, parentid);
    SET lastparent = last_insert_id();
    IF depth - 1 > 0 THEN
      CALL sp_generate_test_data(maxrecords, depth - 1, lastparent);
    END IF;  
    SET counter = counter + 1;
  END WHILE;
    
END$$
DELIMITER ;

CALL sp_generate_test_data(5, 4, NULL);

-- show data
SELECT * FROM v_tree_calcpath LIMIT 100000;
