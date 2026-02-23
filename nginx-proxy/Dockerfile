# Use the official lightweight Nginx image based on Alpine Linux
FROM nginx:alpine

# Copy a custom Nginx configuration file from the host into the container
COPY ./nginx-proxy.conf.template /etc/nginx/templates/default.conf.template

# Copy test html pages into container  
COPY ./public /usr/share/nginx/html

# Inform Docker that the container listens on the specified network ports at runtime
# EXPOSE 80: Standard HTTP port
# EXPOSE 443: Standard HTTPS port
EXPOSE 80
EXPOSE 443

