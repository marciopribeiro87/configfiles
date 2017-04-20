Nginx server configured and optimized using php + socks ( multiple ) + strong SSL practices.
I assume you already know the basics and only want a easy but good config to use.
Create the www-data user with no shell, nginx will run using this. 
Create www-data group and place nginx + php-fpm users for virtual hosts on group.
PHP-FPM is still being updated and tested so use at own discretion. 
This whole directory goes inside the default nginx install in /etc/nginx. 
Check includes/paths.
Dont forget to replace the example.com and example with your values.
