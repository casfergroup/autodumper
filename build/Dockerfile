FROM ubuntu:24.04

ENV DB_HOST="db"
ENV DB_USER=""
#ENV DB_PASSWORD=""
ENV DB_NAME=""
ENV DB_TYPE="mysql"
ENV S3_REMOTE=""
ENV S3_PATH=""
ENV DUMP_PREFIX=""

# Install dependencies
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
        ca-certificates \
        mariadb-client \
        postgresql-client \
        gzip \
        rclone && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the default command
ENTRYPOINT ["/entrypoint.sh"]
