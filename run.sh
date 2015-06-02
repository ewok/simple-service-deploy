#!/bin/sh
# Note: Entry point to birix container

# USE the trap if you need to also do manual cleanup after the service is stopped,
#     or need to start multiple services in the one container
trap "shut_down" HUP INT QUIT KILL TERM

shut_down(){  
# stop service and clean up here

service nginx stop

}

cp -f install.sh /usr/share/nginx/html/index.html
sed "/# URL/ a URL=\"${URL}\"" -i /usr/share/nginx/html/index.html

service nginx start
python3 /build/simple-webserver.py 8889 > /dev/null 2>&1 &

echo "[hit enter key to exit] or run 'docker stop <container>'"
read _

shut_down

echo "exited $0"

