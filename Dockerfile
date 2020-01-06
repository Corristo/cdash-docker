FROM php:7.0-apache

RUN apt-get update                                                             \
 && apt-get install -y gnupg                                                   \
 && apt-get install -y mariadb-server                                          \
 && curl -sL https://deb.nodesource.com/setup_6.x | bash                       \
 && apt-get install -y git libbz2-dev libfreetype6-dev libjpeg62-turbo-dev     \
    libmcrypt-dev libpng-dev libpq-dev libxslt-dev libxss1 nodejs unzip wget   \
    zip                                                                        \
 && docker-php-ext-configure pgsql --with-pgsql=/usr/local/pgsql               \
 && docker-php-ext-configure gd --with-freetype-dir=/usr/include/              \
                                --with-jpeg-dir=/usr/include/                  \
 && docker-php-ext-install -j$(nproc) bcmath bz2 gd pdo_mysql pdo_pgsql xsl    \
 && wget -q -O checksum https://composer.github.io/installer.sha384sum         \
 && wget -q -O composer-setup.php https://getcomposer.org/installer            \
 && sha384sum -c checksum                                                      \
 && php composer-setup.php --install-dir=/usr/local/bin --filename=composer    \
 && php -r "unlink('composer-setup.php');"                                     \
 && composer self-update --no-interaction                                      \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/cdash						    	     \
 && git clone https://github.com/Kitware/CDash.git -b v2.6.0-prebuilt /tmp           \
 && cd /var/www/cdash                                                       	     \
 && cp -r /tmp/app .								     \
 && cp -r /tmp/backup .								     \
 && cp -r /tmp/bootstrap .							     \
 && cp /tmp/composer.json .							     \
 && cp /tmp/composer.lock .							     \
 && cp -r /tmp/config .								     \
 && cp /tmp/gulpfile.js .							     \
 && cp -r /tmp/include .							     \
 && cp /tmp/package.json .							     \
 && cp /tmp/.php_cs .								     \
 && cp /tmp/php.ini .								     \
 && cp -r /tmp/public .								     \
 && cp -r /tmp/scripts .							     \
 && cp -r /tmp/sql .								     \
 && cp -r /tmp/log .								     \
 && cp -r /tmp/xml_handlers .    						     \
 && echo "pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock" >> php.ini         \
 && echo "<?php" > config/config.local.php                                           \
 && echo "  \$CDASH_DB_HOST ='localhost';" >> config/config.local.php                \
 && echo "  \$CDASH_DB_NAME = 'cdash';" >> config/config.local.php                   \
 && echo "  \$CDASH_DB_TYPE = 'mysql';" >> config/config.local.php                   \
 && echo "  \$CDASH_DB_LOGIN = 'cdash';" >> config/config.local.php                  \
 && echo "  \$CDASH_DB_PORT = '';" >> config/config.local.php                        \
 && echo "  \$CDASH_DB_PASS = 'pwd';" >> config/config.local.php                     \
 && echo "  \$CDASH_DB_CONNECTION_TYPE = 'host';" >> config/config.local.php         \
 && echo "  \$CDASH_LOG_FILE = 'php://stdout';" >> config/config.local.php           \
 && echo "  \$CDASH_ENABLE_FEED = 0;" >> config/config.local.php                     \
 && rm -rf /tmp/*

RUN mkdir -p /var/run/mysqld                                                         \
 && chown -R mysql:root /var/run/mysqld                                              \
 && service mysql start                                                              \
 && mysql -u root -e "CREATE DATABASE cdash COLLATE = 'utf8_unicode_ci';"            \
 && mysql -u root -e "CREATE USER 'cdash' IDENTIFIED BY 'pwd';"			     \
 && mysql -u root -e "GRANT USAGE ON *.* TO 'cdash'@localhost IDENTIFIED BY 'pwd';"  \
 && mysql -u root -e "GRANT ALL privileges ON cdash.* TO 'cdash'@localhost;"         \
 && mysql -u root -e "FLUSH PRIVILEGES;"           				     \
 && mysql -u root -e "SHOW GRANTS FOR 'cdash'@localhost;"                            \
 && service mysql stop

RUN cd /var/www/cdash                                                      \
 && composer install --no-interaction --no-progress --prefer-dist --no-dev \
 && npm install                                                            \
 && node_modules/.bin/gulp                                                 \
 && chmod 777 backup log public/rss public/upload                          \
 && rm -rf /var/www/html                                                   \
 && ln -s /var/www/cdash/public /var/www/html                              \
 && rm -rf composer.lock package.json gulpfile.js composer.json

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

WORKDIR /var/www/cdash

HEALTHCHECK --interval=30s --timeout=5s --start-period=5m \
  CMD ["curl", "-f", "http://localhost/viewProjects.php"]

ENTRYPOINT ["/bin/bash", "/docker-entrypoint.sh"]
