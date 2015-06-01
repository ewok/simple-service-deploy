#!/bin/sh
# Note: Entry point to birix container

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "shut_down" HUP INT QUIT KILL TERM

shut_down(){  
# stop service and clean up here

service nginx stop
killall webhookd

}

cp -f install.sh /usr/share/nginx/html/index.html
sed "/# URL/ a URL=\"${URL}\"" -i /usr/share/nginx/html/index.html

service nginx start
webhookd > /dev/null 2>&1 &

echo "[hit enter key to exit] or run 'docker stop <container>'"
read _

shut_down

echo "exited $0"

