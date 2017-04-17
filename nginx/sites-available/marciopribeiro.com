#########################################################################################
#### HTTP/HTTPS Vhost + PHP-FPM + SOCKETS + OPTIMIZED + SECURE SSL              #########
####                Caching is ENABLED !		                        #########
#### Wordpress ready and friendly, permalinks ok		                #########
#### Using Wordpress i recomend the W3-TotalCache plugin for maximum perfomance #########
#### Created by : marciopribeiro87 - Marcio Passos Ribeiro 	                #########
#### Date : 16-04-2017 Version: 0.1 e-mail: marciopribeiro87@gmail.com          #########
#### Github : https://github.com/marciopribeiro87  		                #########
#### License : GPL-3.0   		    			                #########
#########################################################################################


### Cache paths and keys
fastcgi_cache_path /tmp/nginx levels=1:2 keys_zone=my_cache:10m inactive=60m;
fastcgi_cache_key "$scheme$request_method$host$request_uri";


### Optimizing the upstream using multiple sockets	
	upstream fastcgi_backend {
                server unix:/var/run/php/marciopribeiro.com.socket.1 weight=100 max_fails=5 fail_timeout=5;
                server unix:/var/run/php/marciopribeiro.com.socket.2 weight=100 max_fails=5 fail_timeout=5;
}


server {
         listen 80;
### SSL/HTTPS Config uncoment only if using SSL/HTTPS ###
#	 listen 443 ssl;
         server_name marciopribeiro.com www.marciopribeiro.com;

### START OF SSL/HTTPS BLOCK uncoment only if using SSL/HTTPS ###
#	 ssl_certificate /etc/nginx/ssl/marciopribeiro.com.crt;
#         ssl_certificate_key /etc/nginx/ssl/marciopribeiro.com.key;
#         ssl_trusted_certificate /etc/nginx/ssl/root.com.crt;
#         ssl_session_cache shared:SSL:50m;
#         ssl_session_timeout 5m;
#         ssl_prefer_server_ciphers on;
#         ssl_protocols TLSv1.1 TLSv1.2;
#         ssl_ciphers "EECDH+ECDSA+AESGCM:EECDH+aRSA+AESGCM:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA256:EECDH+ECDSA+SHA384:EECDH+ECDSA+SHA256:EECDH+aRSA+SHA384:EDH+aRSA+AESGCM:EDH+aRSA+SHA256:EDH+aRSA:EECDH:!aNULL:!eNULL:!MEDIUM:!LOW:!3DES:!MD5:!EXP:!PSK:!SRP:!DSS:!RC4:!SEED";
#         resolver 8.8.8.8 valid=300s;
#         ssl_stapling on;
#         add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
#         add_header X-XSS-Protection "1; mode=block";
### END OF SSL/HTTPS BLOCK uncoment only if using SSL/HTTPS ###

               root   /var/www/marciopribeiro.com/htdocs;
               index index.php index index.php index.html index.htm;

               include /etc/nginx/security;
	       include /etc/nginx/expires.conf;
### Custom Headers
		fastcgi_pass_header Set-Cookie;
	        fastcgi_pass_header Cookie;
    		fastcgi_ignore_headers Cache-Control Expires Set-Cookie;
		add_header X-Cache $upstream_cache_status;



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

#Don't cache the following URLs
		if ($request_uri ~* "/(wp-login.php|wp-admin|login.php|backend|admin)"){
		    set $no_cache 1;
}

#Don't cache if there is a cookie called PHPSESSID
		if ($http_cookie ~* "PHPSESSID"){
		    set $no_cache 1;
}

#Don't cache if there is a cookie called wordpress_logged_in_[hash]
		if ($http_cookie ~* "wordpress_logged_in_"){
		    set $no_cache 1;
}



### Logging --
 access_log  /var/log/nginx/marciopribeiro.com.access.log;
 error_log  /var/log/nginx/marciopribeiro.com.error.log notice;

### serve static files directly
##         location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
#               access_log        off;
#               expires           max;
#	
#         }

### PHP-FPM configs

         	location ~ \.php$ {
#		try_files $uri =404;
### Fastcgi ( PHP-FPM ) cache config
               fastcgi_cache my_cache;
	       fastcgi_cache_valid 200 302 10m; # Only cache 200 and 302 responses, cache for 10 minutes
               fastcgi_cache_valid 301 60m; # Only cache 301 responses, cache for 60 minutes
               fastcgi_cache_valid any 60m; # Only cache any responses, cache for 60 minutes
               fastcgi_cache_methods GET HEAD; # Only GET and HEAD methods apply
               fastcgi_no_cache $no_cache; # Don't save to cache based on $no_cache
               fastcgi_cache_bypass $no_cache;  # Don't pull from cache based on $no_cache
### Fastcgi ( PHP-FPM ) params
	       fastcgi_pass fastcgi_backend;
               fastcgi_param X-Forwarded-For $remote_addr;
               fastcgi_param Host $host;
	       fastcgi_index index.php;
               include /etc/nginx/fastcgi_params;

         }

### Alowing pretty urls with wordpress, in case your wordpress rests on the root change /blog to / or your other location ##
	location /blog {
        # include the "?$args" part so non-default permalinks doesn't break when using query string
        try_files $uri $uri/ /blog/index.php?$args;
  }
}
