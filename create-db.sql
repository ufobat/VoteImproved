CREATE TABLE users(id integer primary key, name varchar(10), passwd varchar(60), email varchar(20), createdat integer, createdby integer, isactive integer, UNIQUE(name));
CREATE TABLE images(id integer primary key, filename varchar(32), userid integer, epoch integer);
CREATE TABLE votes(id integer primary key, imageid integer, userid integer, rating integer, epoch integer, UNIQUE(imageid, userid));

INSERT INTO users values(0, 'ufobat', '$2b$12$XNaUwBC31RaznOBHDOzQmOZV/F1mgqb5hG0OxoTFnlN.gcyEKRi2q', 'martin@senfdax.de', 1461525093, 0, 1);
