CREATE DATABASE IF NOT EXISTS `web_stats`;
USE `web_stats`;

CREATE TABLE IF NOT EXISTS `skel_stats` (
  `host` char(7) NOT NULL,
  `pid` smallint(5) unsigned NOT NULL,
  `vhost` varchar(255) NOT NULL,
  `rhost` int(10) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `method` varchar(7) NOT NULL,
  `page` varchar(255) NOT NULL,
  `standard` char(8) NOT NULL,
  `status` smallint(3) unsigned NOT NULL,
  `size` int(10) unsigned NOT NULL,
  `time` bigint(20) unsigned NOT NULL,
  KEY `vhost` (`vhost`),
  KEY `rhost` (`rhost`),
  KEY `date` (`date`),
  KEY `page` (`page`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `skel_agents` (
  `host` char(7) NOT NULL,
  `pid` smallint(5) unsigned NOT NULL,
  `vhost` varchar(255) NOT NULL,
  `rhost` int(10) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `agent` varchar(255) NOT NULL,
  KEY `vhost` (`vhost`),
  KEY `rhost` (`rhost`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `skel_errors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `created_date` datetime DEFAULT NULL,
  `current_date` datetime DEFAULT NULL,
  `server` int(10) unsigned DEFAULT '0',
  `type` varchar(50) DEFAULT '',
  `client` varchar(45) DEFAULT '',
  `subdomain` varchar(255) DEFAULT '',
  `instance` varchar(255) DEFAULT '',
  `message` text,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created_date` (`created_date`),
  KEY `server` (`server`),
  KEY `subdomain` (`subdomain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `summary_stats` (
  `date` date NOT NULL DEFAULT '0000-00-00',
  `hits` int(10) unsigned NOT NULL,
  `average` bigint(20) unsigned NOT NULL,
  `_99_percentile` bigint(20) unsigned NOT NULL,
  `_95_percentile` bigint(20) unsigned NOT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

GRANT
SELECT, INSERT, UPDATE, CREATE
ON 'web\_stats'.*
TO 'stats'@'10.%' IDENTIFIED BY '%STATS_AUTH%'; 

CREATE DATABASE IF NOT EXISTS `public_web_stats`;
USE `public_web_stats`;

CREATE TABLE IF NOT EXISTS `skel_stats` (
  `host` char(7) NOT NULL,
  `pid` smallint(5) unsigned NOT NULL,
  `vhost` varchar(255) NOT NULL,
  `rhost` int(10) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `method` varchar(7) NOT NULL,
  `page` varchar(255) NOT NULL,
  `standard` char(8) NOT NULL,
  `status` smallint(3) unsigned NOT NULL,
  `size` int(10) unsigned NOT NULL,
  `time` bigint(20) unsigned NOT NULL,
  KEY `vhost` (`vhost`),
  KEY `rhost` (`rhost`),
  KEY `date` (`date`),
  KEY `page` (`page`),
  KEY `time` (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `skel_agents` (
  `host` char(7) NOT NULL,
  `pid` smallint(5) unsigned NOT NULL,
  `vhost` varchar(255) NOT NULL,
  `rhost` int(10) unsigned NOT NULL,
  `date` datetime NOT NULL,
  `agent` varchar(255) NOT NULL,
  KEY `vhost` (`vhost`),
  KEY `rhost` (`rhost`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `skel_errors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `created_date` datetime DEFAULT NULL,
  `current_date` datetime DEFAULT NULL,
  `server` int(10) unsigned DEFAULT '0',
  `type` varchar(50) DEFAULT '',
  `client` varchar(45) DEFAULT '',
  `subdomain` varchar(255) DEFAULT '',
  `instance` varchar(255) DEFAULT '',
  `message` text,
  `last_modified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `created_date` (`created_date`),
  KEY `server` (`server`),
  KEY `subdomain` (`subdomain`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE IF NOT EXISTS `summary_stats` (
  `date` date NOT NULL DEFAULT '0000-00-00',
  `hits` int(10) unsigned NOT NULL,
  `average` bigint(20) unsigned NOT NULL,
  `_99_percentile` bigint(20) unsigned NOT NULL,
  `_95_percentile` bigint(20) unsigned NOT NULL,
  `updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`),
  KEY `date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

GRANT
SELECT, INSERT, UPDATE, CREATE
ON 'public\_web\_stats'.*
TO 'stats'@'10.%' IDENTIFIED BY '%STATS_AUTH%';
