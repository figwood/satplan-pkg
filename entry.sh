#!/bin/sh
/app/server &
sed -i "s+BASE_URL+"${BASE_URL}"+" /etc/nginx/nginx.conf && nginx -g 'daemon off;'
