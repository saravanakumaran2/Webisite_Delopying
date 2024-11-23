FROM ubuntu:latest
RUN apt-get update && apt-get install -y nginx
COPY index.html /var/www/html/
COPY error /var/www/html/error
COPY assets /var/www/html/assets
COPY images /var/www/html/images
CMD ["nginx", "-g", "daemon off;"]
