# Use the official lightweight Nginx image based on Alpine Linux
FROM nginx:alpine

# Copy a custom Nginx configuration file from the host into the container
# This file will be placed in the /etc/nginx/conf.d/ directory, where Nginx automatically includes it
COPY ./frontend.conf /etc/nginx/conf.d/

# Inform Docker that the container listens on the specified network ports at runtime
# EXPOSE 80: Standard HTTP port
# EXPOSE 443: Standard HTTPS port
EXPOSE 80
EXPOSE 443

# The command to run when the container starts
# 'nginx': Starts the Nginx master process
# '-g "daemon off;"': This global directive runs Nginx in the foreground,
# which is necessary for keeping a Docker container alive.
CMD ["nginx", "-g", "daemon off;"]
