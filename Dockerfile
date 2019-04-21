FROM microsoft/windowsservercore

ENV PG_SERVICE postgresql
ENV PG_DIR C:\\PostgreSQL
ENV DATA_DIR ${PG_DIR}\\data
ENV PGPASSWORD password

ENV INSTALLER_ARGS --mode unattended --servicename "${PG_SERVICE}" --prefix "${PG_DIR}" --datadir "${DATA_DIR}" --superpassword "${PGPASSWORD}"

SHELL [ "powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';" ]

ARG VERSION=11.2

RUN [Net.ServicePointManager]::SecurityProtocol = 'Tls12, Tls11, Tls'; \
    Invoke-WebRequest -UseBasicParsing -Uri "https://get.enterprisedb.com/postgresql/postgresql-$env:VERSION-2-windows-x64.exe" -OutFile installer.exe; \
    Start-Process installer.exe -ArgumentList "$env:INSTALLER_ARGS" -Wait; \
    Remove-Item installer.exe -Force

RUN Invoke-WebRequest -UseBasicParsing -Uri "https://dotnetbinaries.blob.core.windows.net/servicemonitor/2.0.1.3/ServiceMonitor.exe" -OutFile ServiceMonitor.exe

SHELL [ "cmd", "/S", "/C" ]

RUN SETX /M PATH "%PG_DIR%\\bin;%PATH%" && \
    SETX /M DATA_DIR "%DATA_DIR%" && \
    SETX /M PGPASSWORD "%PGPASSWORD%"

RUN powershell -Command "Do { pg_isready -q } Until ($?)" && \
    ECHO listen_addresses = '*' >> "%DATA_DIR%\\postgresql.conf" && \
    ECHO host all all 0.0.0.0/0 trust > "%DATA_DIR%\\pg_hba.conf" && \
    ECHO host all all ::0/0     trust >> "%DATA_DIR%\\pg_hba.conf" && \
    NET stop %PG_SERVICE%

EXPOSE 5432

CMD [ "cmd", "/S", "/C", "ServiceMonitor", "%PG_SERVICE%" ]
