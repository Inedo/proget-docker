#!/bin/bash

chown -R postgres "$PGDATA"

if [ -z "$(ls -A "$PGDATA")" ]; then
	echo Creating ProGet database...

	su -c "/usr/lib/postgresql/$PG_MAJOR/bin/initdb" postgres
	sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

	su -c "echo 'CREATE DATABASE \"ProGet\";' | /usr/lib/postgresql/$PG_MAJOR/bin/postgres --single -jE" postgres
	su -c "echo \"CREATE USER proget WITH SUPERUSER PASSWORD 'proget';\" | /usr/lib/postgresql/$PG_MAJOR/bin/postgres --single -jE" postgres

	{ echo; echo "host all all 0.0.0.0/0 md5"; } >> "$PGDATA"/pg_hba.conf
fi

echo Starting postgresql...
su -c "/usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl start -w -D /var/lib/postgresql/data" postgres

echo Running changescripter...
mono /usr/local/proget/db/bmdbupdate.exe Update /Conn='Server=localhost; Database=ProGet; User Id=proget; Password=proget;' /Init=yes

echo Starting nginx...
nginx
echo Nginx started

echo Starting ProGet service...
mono /usr/local/proget/service/ProGet.Service.exe Run &
pgservice_pid=$!
echo "Service PID is $pgservice_pid"

echo Starting ProGet Web application...
fastcgi-mono-server4 --socket=tcp --applications=/:/usr/local/proget/web &
pgweb_pid=$!
echo "Web PID is $pgweb_pid"

function handle_shutdown {
	echo "Stopping ProGet service..."
	kill -15 $pgservice_pid

	echo "Stopping ProGet web application..."
	kill -15 $pgweb_pid

	echo "Stopping postgresql..."
	su -c "/usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl stop" postgres

	exit 0
}

trap "handle_shutdown" HUP INT QUIT KILL TERM

echo "Running... Press enter or use docker stop to exit."
while true
do
	sleep 1
done
