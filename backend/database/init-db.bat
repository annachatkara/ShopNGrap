@echo off
setlocal

:: Prompt user for values
set /p PG_APP_USER=Enter PostgreSQL App Username: 
set /p PG_APP_PASS=Enter Password for %PG_APP_USER%: 
set /p PG_APP_DB=Enter Database Name: 


:: Temporary SQL file banayenge
echo CREATE USER %PG_APP_USER% WITH PASSWORD '%PG_APP_PASS%'; > temp_init.sql
echo CREATE DATABASE %PG_APP_DB% OWNER %PG_APP_USER%; >> temp_init.sql
echo GRANT ALL PRIVILEGES ON DATABASE %PG_APP_DB% TO %PG_APP_USER%; >> temp_init.sql
echo ALTER USER %PG_APP_USER% CREATEDB; >> temp_init.sql
:: Run psql command (admin user se login hoga, default postgres)
psql -U postgres -h localhost -p 5432 -f temp_init.sql

:: Cleanup temp file
del temp_init.sql

echo ✅ Database setup complete!

echo Your connection URL is:
echo postgresql://%PG_APP_USER%:%PG_APP_PASS%@localhost:5432/%PG_APP_DB%
echo.
pause
