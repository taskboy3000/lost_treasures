-- 
-- Created by SQL::Translator::Producer::SQLite
-- Created on Tue Jul  5 16:52:58 2016
-- 

;
BEGIN TRANSACTION;
--
-- Table: users
--
CREATE TABLE users (
  id char(64) NOT NULL,
  email varchar(128) NOT NULL,
  password_hash varchar(64) NOT NULL,
  role char(1) NOT NULL,
  created_at datetime NOT NULL,
  updated_at datetime NOT NULL,
  PRIMARY KEY (id)
);
COMMIT;
