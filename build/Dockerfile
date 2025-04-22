FROM alpine:3.18.3

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
    apk add --no-cache \
        ca-certificates \
        mariadb-client \
        postgresql-client \
        gzip \
        rclone

WORKDIR /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the default command
ENTRYPOINT ["/entrypoint.sh"]