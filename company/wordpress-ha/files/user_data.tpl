#!/bin/bash
echo "
<?php
define( 'WP_SITEURL', '${WP_SITEURL}' );
define( 'WP_HOME', '${WP_HOME}' );
define( 'WP_ALLOW_MULTISITE', ${WP_ALLOW_MULTISITE} );
define( 'WPLANG', '${WPLANG}' );

define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASSWORD}' );
define( 'DB_HOST', '${DB_HOST}' );
define( 'DB_CHARSET', '${DB_CHARSET}' );
define( 'DB_COLLATE', '${DB_COLLATE}' );

define( 'AUTH_KEY', '${AUTH_KEY}' );
define( 'SECURE_AUTH_KEY', '${SECURE_AUTH_KEY}' );
define( 'LOGGED_IN_KEY', '${LOGGED_IN_KEY}' );
define( 'NONCE_KEY', '${NONCE_KEY}' );
define( 'AUTH_SALT', '${AUTH_SALT}' );
define( 'SECURE_AUTH_SALT', '${SECURE_AUTH_SALT}' );
define( 'LOGGED_IN_SALT', '${LOGGED_IN_SALT}' );
define( 'NONCE_SALT', '${NONCE_SALT}' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', ${WP_DEBUG} );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
" > /var/www/html/wp-config.php

wp core install --url=${WP_SITEURL} \
	--title=${WP_TITLE} \
	--admin_user=${WP_ADMIN_USER} \
	--admin_password=${WP_ADMIN_PASSWORD} \
	--admin_email=${WP_ADMIN_EMAIL} \
	--path=/var/www/html

sudo mount -t efs ${EFS_ID}:/ /var/www/html
sudo su -c "echo '${EFS_ID}:/ /var/www/html efs _netdev,noresvport,tls,iam 0 0' >> /etc/fstab"

sudo systemctl restart httpd
sudo systemctl enable httpd