SET FOREIGN_KEY_CHECKS=0;
UNLOCK TABLES;

DROP TABLE IF EXISTS `relator_type`;
CREATE TABLE `relator_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxName` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `relationship`;
CREATE TABLE `relationship` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `relator_sourcetype_id` int(11) NOT NULL,
  `relator_source_id` int(11) NOT NULL,
  `relator_targettype_id` int(11) NOT NULL,
  `relator_target_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxSourceType` (`relator_sourcetype_id`),
  KEY `idxSource` (`relator_source_id`),
  KEY `idxTargetType` (`relator_targettype_id`),
  KEY `idxTarget` (`relator_target_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE relationship
ADD CONSTRAINT fk_relationship_sourcetype_id
  FOREIGN KEY (relator_sourcetype_id)
  REFERENCES relator_type (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
ALTER TABLE relationship
ADD CONSTRAINT fk_relationship_targettype_id
  FOREIGN KEY (relator_targettype_id)
  REFERENCES relator_type (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
  
SET FOREIGN_KEY_CHECKS=1;
