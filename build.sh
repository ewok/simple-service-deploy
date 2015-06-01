#!/bin/bash

set -e

# Paths
cd $(dirname $0)
BASE_DIR=$(pwd -P)

TEMP="${PWD}/simple-service"
PACKAGE_DIR="${PWD}/package"
NGINX_DIR="/usr/share/nginx/html"

# Getting project from github
if [ ! -d ${TEMP} ]
then 
	git clone https://github.com/ewok/simple-service.git ${TEMP}
else
	cd ${TEMP}
	git fetch --all
	git reset --hard origin/master
	git pull
fi


cd ${TEMP}

# Variables for metapackage (indian code)
data=$(cat "pom.xml")
DESCRIPTION=$(grep -oPm1 "(?<=<description>)[^<]+" <<< "$data") 
NAME=$(grep -oPm1 "(?<=<artifactId>)[^<]+" <<< "$data")
VERSION=$(grep -oPm1 "(?<=<version>)[^<]+" <<< "$data")
JAR_FILE="${TEMP}/target/${NAME}.jar"

# Building jar
mvn package

cd ${BASE_DIR}

# Making deb rpm
if [ ! -d "${PACKAGE_DIR}" ]; then
    mkdir -p ${PACKAGE_DIR}/{etc/init.d,usr/share/${NAME}}
fi


# Service bin
cp -f "${JAR_FILE}" "${PACKAGE_DIR}/usr/share/${NAME}/${NAME}.jar"


# Init.d
cat <<EOF > ${PACKAGE_DIR}/etc/init.d/${NAME}
### BEGIN INIT INFO
# Provides: ${NAME}
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop ${NAME}
# Description: Start, stop and save ${NAME}
### END INIT INFO

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="${DESCRIPTION}"
SERVICE_NAME=${NAME}
PIDFILE=/var/run/${NAME}.pid
SCRIPTNAME=/etc/init.d/${NAME}
PATH_TO_JAR="/usr/share/${NAME}/${NAME}.jar"
EOF

cat <<'EOF' >> ${PACKAGE_DIR}/etc/init.d/${NAME}
do_start()
{
 	echo "Starting $SERVICE_NAME ..."
        if [ ! -f $PIDFILE ]; then
            nohup java -Dlogging.path=/var/log -jar $PATH_TO_JAR /tmp 2>> /dev/null >> /dev/null &
                        echo $! > $PIDFILE
            echo "$SERVICE_NAME started ..."
        else
            echo "$SERVICE_NAME is already running ..."
        fi
}

do_stop()
{
	if [ -f $PIDFILE ]; then
            PID=$(cat $PIDFILE);
            echo "$SERVICE_NAME stoping ..."
            kill $PID;
            echo "$SERVICE_NAME stopped ..."
            rm $PIDFILE
        else
            echo "$SERVICE_NAME is not running ..."
        fi
}

status()
{
	if [ -f $PIDFILE ]; then
            echo "$SERVICE_NAME running ..."
        else
            echo "$SERVICE_NAME is not running ..."
        fi

}

case "$1" in
  start)
        do_start
        ;;
  stop)
        do_stop
        ;;
  status)
        status
        ;;
  restart|force-reload)
        do_stop
        do_start
        ;;
  *)
        echo "Usage: $SERVICE_NAME {start|stop|status|restart}" >&2
        exit 3
        ;;
esac
EOF

chmod +x ${PACKAGE_DIR}/etc/init.d/${NAME}

cat <<EOF > afterinstalldeb
#!/bin/bash
update-rc.d ${NAME} defaults || exit 0
service ${NAME} start
EOF

cat <<EOF > afterinstallrpm
#!/bin/bash
chkconfig ${NAME} on
service ${NAME} start
EOF

cat <<EOF > beforeremovedeb
#!/bin/bash
update-rc.d -f ${NAME} remove || exit 0
service ${NAME} stop
EOF

cat <<EOF > beforeremoverpm
#!/bin/bash
chkconfig ${NAME} off
service ${NAME} stop
EOF

rm -f *.deb
rm -f *.rpm

fpm -n $NAME -v $VERSION -a all -C ${PACKAGE_DIR} \
        --description "$DESCRIPTION" \
	--before-remove beforeremovedeb \
	--after-install afterinstalldeb \
        -t "deb" -d "default-jre" \
        -s dir etc usr

fpm -n $NAME -v $VERSION -a all -C ${PACKAGE_DIR} \
        --description "$DESCRIPTION" \
	--before-remove beforeremoverpm \
	--after-install afterinstallrpm \
        -t "rpm" -d "java-1.7.0-openjdk" \
        -s dir etc usr


for i in $(ls *.deb); do
	cp -f $i ${NGINX_DIR}/package.deb
done

for i in $(ls *.rpm); do
	cp -f $i ${NGINX_DIR}/package.rpm
done

