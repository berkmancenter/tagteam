CREATE USER docker WITH ENCRYPTED PASSWORD 'docker';
CREATE DATABASE tagteam_development;
GRANT ALL PRIVILEGES ON DATABASE tagteam_development TO docker;
