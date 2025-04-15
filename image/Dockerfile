FROM ubuntu:24.04

ENV DB_HOST=db.example.com
ENV DB_USER=root
ENV DB_PASSWORD=secret
ENV DB_NAME=""
ENV DB_TYPE=mysql
ENV S3_REMOTE=myremote
ENV S3_PATH=backups
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
