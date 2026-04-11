# ==========================================
# Stage 1: Build the React Application
# ==========================================
FROM node:alpine3.23 AS Build

# Set the working directory inside the container
WORKDIR /app

# Copy dependency definitions and install them
COPY ./package*.json ./
RUN npm install

# Copy the rest of the application source code
COPY . .

# args needed for build 
ARG VITE_BASE_URI

# Pass the environemnt variable from the args  
ENV VITE_BASE_URI=$VITE_BASE_URI

# Build the production artifacts (creates the /dist folder)
RUN npm run build

# ==========================================
# Stage 2: Serve the Application with Nginx
# ==========================================
FROM nginx:1.29.8-alpine3.23

RUN apk upgrade --no-cache

# Add metadata for the image
LABEL maintainer="abdelhameednael27@gmail.com" \
      version="2.0" \
      description="Production Grade Frontend Image for Ema2a Graduation Project "

# Clear out the default Nginx static assets
RUN rm -rf /usr/share/nginx/html/*

# Copy built artifacts from the Build stage and set ownership to nginx user
COPY --from=Build --chown=nginx:nginx /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration template
COPY ./nginx-proxy.conf.template /etc/nginx/templates/default.conf.template

# Configure proper permissions so Nginx can run securely as a non-root user
RUN chown -R nginx:nginx /var/cache/nginx /var/run /run /tmp /usr/share/nginx /etc/nginx/conf.d && \
    chmod -R 2775 /var/cache/nginx /var/run /tmp /etc/nginx/conf.d /run && \
    chmod -R 755 /usr/share/nginx/html && \
    echo 'umask 0002' >> /etc/profile && \
    echo 'umask 0002' >> /home/nginx/.profile 2>/dev/null || true

# Expose standard HTTP and HTTPS ports
EXPOSE 8080

# Switch to non-root user for security
USER nginx
