server {
         listen 80;
         server_name marciopribeiro.com;
               root   /var/www/marciopribeiro.com/htdocs;
               index index.php index index.php index.html index.htm;

         include /etc/nginx/security;

 # Logging --
 access_log  /var/log/nginx/marciopribeiro.com.access.log;
 error_log  /var/log/nginx/marciopribeiro.com.error.log notice;

         # serve static files directly
         location ~* ^.+.(jpg|jpeg|gif|css|png|js|ico|html|xml|txt)$ {
               access_log        off;
               expires           max;
         }

         location ~ \.php$ {
         try_files $uri =404;
               fastcgi_pass unix:/var/run/php/marciopribeiro.com.socket;
               proxy_set_header X-Forwarded-For $remote_addr;
               proxy_set_header Host $host;
	       fastcgi_index index.php;
               include /etc/nginx/fastcgi_params;
         }
}
