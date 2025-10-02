FROM mcr.microsoft.com/mssql/server:2025-latest

COPY ./init-db.sh /init-db.sh

ENTRYPOINT /bin/bash -c "/opt/mssql/bin/sqlservr & sleep 30 && /init-db.sh && tail -f /dev/null"

