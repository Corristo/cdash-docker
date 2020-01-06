#!/bin/bash

if [ -d /certificates ]; then
  a2enmod ssl
  cat > /etc/apache2/sites-enabled/default-ssl.conf <<EOF
<IfModule mod_ssl.c>
	<VirtualHost _default_:443>
		ServerAdmin webmaster@localhost
		DocumentRoot /var/www/html
		ErrorLog ${APACHE_LOG_DIR}/error.log
		CustomLog ${APACHE_LOG_DIR}/access.log combined

		SSLEngine on

		SSLCertificateFile    /certificates/fullchain1.pem
		SSLCertificateKeyFile /certificates/privkey1.pem

		<FilesMatch "\.(cgi|shtml|phtml|php)$">
				SSLOptions +StdEnvVars
		</FilesMatch>
		<Directory /usr/lib/cgi-bin>
				SSLOptions +StdEnvVars
		</Directory>
	</VirtualHost>
</IfModule>
EOF
fi

service mysql start
exec /usr/sbin/apache2ctl -D FOREGROUND
