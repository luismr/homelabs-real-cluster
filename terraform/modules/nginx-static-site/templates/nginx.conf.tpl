server {
    listen 80;
    server_name _;
    
    # Resolve upstream hostnames at request time (avoids "host not found in upstream" at startup)
    resolver ${cluster_dns_ip} valid=10s ipv6=off;
    
    root /usr/share/nginx/html;
    index index.html index.htm;
    
    # Logging
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml+rss application/json application/javascript;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Proxy routes (variable-based proxy_pass so DNS is resolved at request time, not at nginx start)
%{ for path_prefix, backend_url in proxy_routes ~}
    location ${path_prefix} {
        set $backend "${backend_url}";
        proxy_pass $backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $${http_upgrade};
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $${host};
        proxy_set_header X-Real-IP $${remote_addr};
        proxy_set_header X-Forwarded-For $${proxy_add_x_forwarded_for};
        proxy_set_header X-Forwarded-Proto $${scheme};
        proxy_cache_bypass $${http_upgrade};
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
%{ endfor ~}
    
    # Serve static files
    location / {
        try_files $${uri} $${uri}/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
