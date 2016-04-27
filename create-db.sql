CREATE table users(id integer primary key, name varchar(10), passwd varchar(60), email varchar(20), createdat integer, createdby integer, isactive integer, UNIQUE(name));
INSERT INTO users values(0, 'ufobat', '$2b$12$kddjkaM0st3EKSR.i1m8UO9zZQgbJTvszBgt.WR9h0FsWsWTZKuui', 'martin@senfdax.de', 1461525093, 0, 1); 
