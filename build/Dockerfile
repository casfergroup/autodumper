FROM alpine:latest

ENV DB_HOST="db"
ENV DB_PORT="3306"
ENV DB_USER=""
#ENV DB_PASSWORD=""
ENV DB_NAME=""
ENV DB_TYPE="mysql"
ENV S3_REMOTE=""
ENV S3_PATH=""
ENV DUMP_PREFIX=""

# Install dependencies
RUN apk update && \
    apk upgrade --available && \
    apk add --no-cache \
        age \
        bash \    
        ca-certificates \
        gzip \
        mariadb-client \
        postgresql-client \
        rclone

WORKDIR /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the default command
ENTRYPOINT ["/entrypoint.sh"]