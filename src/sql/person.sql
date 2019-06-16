SET FOREIGN_KEY_CHECKS=0;
UNLOCK TABLES;

DROP TABLE IF EXISTS `person_type`;
CREATE TABLE `person_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxName` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `person`;
CREATE TABLE `person` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_type_id` int(11) NOT NULL,
  `username` varchar(255) CHARACTER SET utf8 NOT NULL,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `email` varchar(255) CHARACTER SET utf8 NOT NULL,
  `password` varchar(255) CHARACTER SET utf8 NULL,
  `oath_url` varchar(255) CHARACTER SET utf8 NULL,
  `oath_user_id` varchar(255) CHARACTER SET utf8 NULL,
  `created` datetime NOT NULL,
  `updated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxPersonType` (`person_type_id`),
  KEY `idxUsername` (`username`),
  KEY `idxEmail` (`email`),
  KEY `idCreated` (`created`),
  KEY `idxUpdated` (`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE person
ADD CONSTRAINT fk_person_person_type_id
  FOREIGN KEY (person_type_id)
  REFERENCES person_type (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

DROP TABLE IF EXISTS `person_data_type`;
CREATE TABLE `person_data_type` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxName` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `person_data`;
CREATE TABLE `person_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `person_data_type_id` int(11) NOT NULL,
  `person_id` int(11) NOT NULL,
  `name` varchar(255) CHARACTER SET utf8 NOT NULL,
  `string` varchar(8192) CHARACTER SET utf8 NULL,
  `int` int NULL,
  `real` double NULL,
  `datetime` datetime NULL,
  `text` text NULL,
  `created` datetime NOT NULL,
  `updated` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idxPersonDataType` (`person_data_type_id`),
  KEY `idxPerson` (`person_id`),
  KEY `idxName` (`name`),
  KEY `idCreated` (`created`),
  KEY `idxUpdated` (`updated`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
ALTER TABLE person_data
ADD CONSTRAINT fk_person_data_person_data_type_id
  FOREIGN KEY (person_data_type_id)
  REFERENCES person_data_type (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;
ALTER TABLE person_data
ADD CONSTRAINT fk_person_data_person_id
  FOREIGN KEY (person_id)
  REFERENCES person (id)
  ON DELETE CASCADE
  ON UPDATE CASCADE;

SET FOREIGN_KEY_CHECKS=1;