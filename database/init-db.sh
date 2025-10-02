#!/bin/bash
# Wait until SQL Server is ready before running commands
echo "⏳ Waiting for SQL Server to be ready..."
until /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" > /dev/null 2>&1
do
  sleep 2
done

echo "✅ SQL Server is up. Creating database if not exists..."

# Create the DB if missing
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'SignLanguageTrasnlator')
BEGIN
    CREATE DATABASE [SignLanguageTrasnlator];
END
"

