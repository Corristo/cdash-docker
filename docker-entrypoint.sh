#!/bin/bash

service mysql start
exec /usr/sbin/apache2ctl -D FOREGROUND
