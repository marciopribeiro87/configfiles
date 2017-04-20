#########################################################################################
#### HTTP/HTTPS Vhost + PHP-FPM + SOCKETS + OPTIMIZED + SECURE SSL              #########
#### Caching is ENABLED ! 				                        #########
#### Wordpress ready and friendly, permalinks ok		                #########
#### Created by : marciopribeiro87 - Marcio Passos Ribeiro 	                #########
#### Date : 20-04-2017 Version: 0.3 e-mail: marciopribeiro@gmail.com            #########
#### Github : https://github.com/marciopribeiro87  		                #########
#### License : GPL-3.0   		    			                #########
#########################################################################################
#### REPLACE THE "EXAMPLE" values below with your own, usually your domain name #########
#########################################################################################



### Cache paths and keys
		fastcgi_cache_path /tmp/nginx levels=1:2 keys_zone=example:10m inactive=60m;
		fastcgi_cache_key "$scheme$request_method$host$request_uri";


### Optimizing the upstream using multiple sockets	
		upstream fastcgi_backend {
                	server unix:/var/run/php/example.com.socket.1 weight=100 max_fails=5 fail_timeout=5;
                	server unix:/var/run/php/example.com.socket.2 weight=100 max_fails=5 fail_timeout=5;
}

## Start of Server section

		server {
         		listen 80;
### SSL/HTTPS Config uncoment only if using SSL/HTTPS ###
#	 		listen 443 ssl;
         	server_name example.com www.example.com;

### START OF SSL/HTTPS BLOCK uncoment only if using SSL/HTTPS ###
#	 	ssl_certificate /etc/nginx/ssl/example.com.crt;
#         	ssl_certificate_key /etc/nginx/ssl/example.com.key;
#         	ssl_trusted_certificate /etc/nginx/ssl/root.com.crt;
#         	ssl_session_cache shared:SSL:50m;
#         	ssl_session_timeout 5m;
#               ssl_dhparam /etc/nginx/ssl/dhparam.pem;
#         	ssl_prefer_server_ciphers on;
#         	ssl_protocols TLSv1.1 TLSv1.2;
#               ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
#         	resolver 8.8.8.8 valid=300s;
#         	ssl_stapling on;
#         	add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
#         	add_header X-XSS-Protection "1; mode=block";
### END OF SSL/HTTPS BLOCK uncoment only if using SSL/HTTPS ###

              	root   /var/www/example.com/htdocs;
              	index index.php index.html index.htm;

# Include security file
               	include /etc/nginx/security;
# Expires for static content
               	include /etc/nginx/expires.conf;

### Custom Headers
    		fastcgi_ignore_headers X-Accel-Expires Expires Cache-Control Set-Cookie;

#Cache everything by default
		set $no_cache 0;

# Only cache GET requests
		if ($request_method != GET){
		    	set $no_cache 1;
}

#Don't cache if the URL contains a query string
		if ($query_string != ""){
			set $no_cache 1;
}

# Bypassing Wordpress
		if ($http_cookie ~* "comment_author_|wordpress_(?!test_cookie)|wp-postpass_|wordpress_logged_in_" ) {
			set $no_cache 1;
}
		if ($request_uri ~* "/wp-admin/|/forum/admin/|/administrator/|/wp-login/" ) {
			set $no_cache 1;
}

#Don't cache if there is a cookie called PHPSESSID
		if ($http_cookie ~* "PHPSESSID"){
		    	set $no_cache 1;
}

### Logging  
		access_log  /var/log/nginx/example.com.access.log;
		error_log  /var/log/nginx/example.com.error.log notice;
		location = /favicon.ico { access_log off; log_not_found off; }
 		location = /robots.txt  { access_log off; log_not_found off; }

### PHP-FPM configs
         	location ~ \.php$ {
#		try_files $uri =404;
### Fastcgi ( PHP-FPM ) cache config
               	fastcgi_cache example;
	       	fastcgi_cache_bypass $http_cache_control;
	       	fastcgi_cache_valid 200 302 10m; # Only cache 200 and 302 responses, cache for 10 minutes
               	fastcgi_cache_valid 301 60m; # Only cache 301 responses, cache for 60 minutes
               	fastcgi_cache_valid any 60m; # Only cache any responses, cache for 60 minutes
               	fastcgi_cache_methods GET HEAD; # Only GET and HEAD methods apply
               	fastcgi_no_cache $no_cache; # Don't save to cache based on $not_cache
               	fastcgi_cache_bypass $no_cache;  # Don't pull from cache based on $not_cache
### Fastcgi ( PHP-FPM ) params
	       	fastcgi_pass fastcgi_backend;
               	fastcgi_param X-Forwarded-For $remote_addr;
               	fastcgi_param Host $host;
	       	fastcgi_index index.php;
               	include /etc/nginx/fastcgi_params;
}

### Alowing pretty urls with wordpress, in case your wordpress rests on the root change /blog to / or your other location ##
# include the "?$args" part so non-default permalinks doesn't break when using query string
		location /blog {
        		try_files $uri $uri/ /blog/index.php?$args;
}
### nginx status
		location /nginx_status {
         		stub_status on;
         		access_log   off;
         		allow all;
}
		add_header X-Cache $upstream_cache_status;

}
