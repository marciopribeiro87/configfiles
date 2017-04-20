PHP-FPM Configuration.
Unix sockets mode.
Create the user running the pool and use the same for editing files ( ftp ) no bash is ideal. 
Place the user for each pool in the www-data group since that is the group both nginx and php-fpm run on. 
The configuration was benched and optimized for a small 1CPU/1GB server, bench and ajust to personal needs.
There are some disabled_functions for security best practices, check to see if none of those impact you. 
