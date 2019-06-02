SET FOREIGN_KEY_CHECKS=0;
UNLOCK TABLES;

DROP TABLE IF EXISTS `tree`;
CREATE TABLE `tree` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `parentid` int(11) DEFAULT NULL,
  `forceupdate` boolean DEFAULT false, -- column to help force trigger to fire
  PRIMARY KEY (`id`),
  KEY `idxParentId` (`parentid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE tree
ADD CONSTRAINT fk_tree_parentid -- This is broken in MySQL as of 2019 in that it won't fire triggers
  FOREIGN KEY (parentid)
  REFERENCES tree (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

-- instead of calcuating paths and depths on the fly, cache them using triggers and procedures
DROP TABLE IF EXISTS `tree_cache`;
CREATE TABLE `tree_cache` (
  `id` int(11) NOT NULL,
  `path` TEXT CHARACTER SET utf8 NOT NULL,
  `depth` int(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
CREATE FULLTEXT INDEX idxPath ON tree_cache ( path );
ALTER TABLE tree_cache
ADD CONSTRAINT fk_tree_cache_id
  FOREIGN KEY (id)
  REFERENCES tree (id)
  ON DELETE CASCADE
  ON UPDATE NO ACTION;

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

-- maintain tree_cache with triggers
DELIMITER $$
DROP TRIGGER IF EXISTS tr_tree_AFTER_INSERT$$
CREATE DEFINER = CURRENT_USER TRIGGER `tr_tree_AFTER_INSERT` AFTER INSERT ON `tree` 
FOR EACH ROW
BEGIN
  DECLARE newid INT;
  DECLARE path VARCHAR(4096);
  DECLARE depth INT;
    
  SET newid = NEW.id;
  SELECT fn_get_tree_path(newid) INTO path;
  SELECT fn_get_tree_depth(newid) INTO depth;
    
  INSERT INTO tree_cache VALUES (newid, path, depth);
END$$
DELIMITER ;  

-- maintain tree_cache with triggers
DELIMITER $$
DROP TRIGGER IF EXISTS tr_tree_AFTER_UPDATE$$
CREATE DEFINER = CURRENT_USER TRIGGER `tr_tree_AFTER_UPDATE` AFTER UPDATE ON `tree` 
FOR EACH ROW
BEGIN
  DECLARE newid INT;
  DECLARE oldid INT;
  DECLARE newpath VARCHAR(4096);
  DECLARE newdepth INT;
    
  SET newid = NEW.id;
  SELECT fn_get_tree_path(newid) INTO newpath;
  SELECT fn_get_tree_depth(newid) INTO newdepth;
  
  SELECT id INTO oldid FROM tree_cache WHERE id=newid;
  
  IF oldid IS NULL THEN
    INSERT INTO tree_cache VALUES (newid, newpath, newdepth);
  ELSE
    UPDATE tree_cache SET path=newpath, depth=newdepth WHERE id=oldid;
  END IF;
  
END$$
DELIMITER ;  

-- get all descendant list into temp table for cursor
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_get_all_children$$
CREATE PROCEDURE sp_get_all_children(IN oldid INT)
BEGIN
  DROP TABLE IF EXISTS child_list;
  CREATE TEMPORARY TABLE child_list (id INT, parentid INT);
  
  INSERT INTO child_list (SELECT id, parentid 
    FROM (SELECT id, parentid FROM tree ORDER BY id, parentid) AS tree_sorted,
      (SELECT @seekid := oldid) initialisation
    WHERE find_in_set(parentid, @seekid)
    AND length(@seekid := concat(@seekid, ',', id)));
  
END$$
DELIMITER ;

-- runs cursor for sp_repair_tree_cache
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_repair_tree_cursor$$
CREATE PROCEDURE sp_repair_tree_cursor()
BEGIN
  DECLARE newparentid INT;
  DECLARE finished INTEGER DEFAULT 0;
  
  DECLARE tree_cursor CURSOR FOR 
    SELECT id from child_list;
 
  DECLARE CONTINUE HANDLER 
    FOR NOT FOUND SET finished = 1;
  
  OPEN tree_cursor;
  
  get_children: LOOP
    FETCH tree_cursor INTO newparentid;
    IF finished = 1 THEN 
      LEAVE get_children;
    END IF;
    UPDATE tree SET forceupdate = NOT forceupdate WHERE id=newparentid; -- force trigger to fire
  END LOOP get_children;

  CLOSE tree_cursor;
  
END$$
DELIMITER ;

-- fk updates don't fire triggers so deal with it manually
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_repair_tree_cache$$
CREATE PROCEDURE sp_repair_tree_cache(IN oldid INT)
BEGIN

  CALL sp_get_all_children(oldid);
  CALL sp_repair_tree_cursor();
  DROP TABLE child_list;
  
END$$
DELIMITER ;

-- the next two views produce the same result in different ways

-- view calculates path and depth in realtime
DROP TABLE IF EXISTS `v_tree_calcpath`;
DROP VIEW IF EXISTS `v_tree_calcpath`;
CREATE VIEW `v_tree_calcpath` AS 
  SELECT id,`name`,parentid,
  fn_get_tree_path(id) AS path,
  fn_get_tree_depth(id) AS depth
  FROM tree ORDER BY fn_get_tree_path(id);

-- view gets path and depth from cache
DROP TABLE IF EXISTS `v_tree_cachepath`;
DROP VIEW IF EXISTS `v_tree_cachepath`;
CREATE VIEW `v_tree_cachepath` AS 
  SELECT t.id,t.`name`,t.parentid,
  tc.path,
  tc.depth
  FROM tree AS t
  INNER JOIN tree_cache AS tc
    ON tc.id=t.id
  ORDER BY tc.path;

SET FOREIGN_KEY_CHECKS=1;

-- insert test data
LOCK TABLES tree WRITE;
INSERT INTO tree VALUES (1,'super1',NULL,false),(2,'super2',NULL,false),(3,'super3',NULL,false),
  (4,'one',1,false),(5,'one',2,false),(6,'one',3,false),
  (7,'one',4,false),(8,'one',5,false),(9,'one',6,false);
UNLOCK TABLES;

-- test update query
UPDATE tree SET name='newsuper2' WHERE id=2;
CALL sp_repair_tree_cache(2); -- fk updates don't fire triggers so deal with it manually
