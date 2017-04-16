	upstream fastcgi_backend {
                server unix:/var/run/php/marciopribeiro.com.socket.1 weight=100 max_fails=5 fail_timeout=5;
                server unix:/var/run/php/marciopribeiro.com.socket.2 weight=100 max_fails=5 fail_timeout=5;
}


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
         #try_files $uri =404;
               fastcgi_pass fastcgi_backend;
               proxy_set_header X-Forwarded-For $remote_addr;
               proxy_set_header Host $host;
	       fastcgi_index index.php;
               include /etc/nginx/fastcgi_params;
         }
### Permitindo permalinks do wordpress, caso o wordpress responsa na raiz alterar /blog para / ##	
### Alowing pretty urls with wordpress, in case your wordpress rests on the root change /blog to / ou your other location ##
	location /blog {
        # include the "?$args" part so non-default permalinks doesn't break when using query string
        try_files $uri $uri/ /blog/index.php?$args;
  }
}
