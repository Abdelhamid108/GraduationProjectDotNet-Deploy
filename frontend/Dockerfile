
# Base image 
FROM nginx:alpine

COPY ./frontend.conf /etc/nginx/conf.d/

EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
