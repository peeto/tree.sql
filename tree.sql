
DROP TABLE IF EXISTS `tree`;
CREATE TABLE `tree` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `parentid` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idxParentId` (`parentid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

LOCK TABLES `tree` WRITE;
INSERT INTO `tree` VALUES (1,'super1',NULL),(2,'super2',NULL),(3,'super3',NULL),
  (4,'one',1),(5,'one',2),(6,'one',3),
  (7,'one',4),(8,'one',5),(9,'one',6);
UNLOCK TABLES;

DROP FUNCTION IF EXISTS `fn_get_tree_path`;
DELIMITER ;;
CREATE FUNCTION `fn_get_tree_path`(inid INT) RETURNS varchar(4096) CHARSET utf8
BEGIN
  DECLARE childparentid INT;
  DECLARE childpath VARCHAR(255);
  DECLARE path VARCHAR(4096);
    
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
  SET depth = 0;
    
  WHILE childparentid IS NOT NULL DO
    SELECT parentid INTO childparentid FROM tree WHERE id=childparentid;
    IF childparentid IS NOT NULL THEN
        SET depth = depth + 1;
    END IF;
  END WHILE;
    
  RETURN depth;
END ;;
DELIMITER ;

DROP TABLE IF EXISTS `v_tree_path`;
DROP VIEW IF EXISTS `v_tree_path`;
CREATE VIEW `v_tree_path` AS 
  SELECT id,`name`,parentid,
  fn_get_tree_path(id) AS path,
  fn_get_tree_depth(id) AS depth
  FROM tree ORDER BY fn_get_tree_path(id);
