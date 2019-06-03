CREATE USER docker WITH ENCRYPTED PASSWORD 'docker';
CREATE DATABASE tagteam_development;
CREATE DATABASE tagteam_test;
GRANT ALL PRIVILEGES ON DATABASE tagteam_development TO docker;
