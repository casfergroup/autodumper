#!/bin/sh

# === File Permssions ==
umask 077

# == ENV Validation ==
required_vars="DB_HOST DB_USER DB_PASSWORD DB_TYPE S3_REMOTE S3_PATH"
for var in $required_vars; do
    eval "value=\${$var}"
    if [ -z "$valie" ]; then
        echo "Error: Required variable $var is not set!"
        exit 1
    fi
done

# === Internal variables ===
DATE_STR=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${DUMP_PREFIX}_${DATE_STR}.sql.gz"
DUMP_PATH="/data/${FILENAME}"

# == Function to split 

# === Function to dump database(s) ===
dump_databases() {
    case "$DB_TYPE" in
        mysql)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MySQL databases..."
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --all-databases | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected MySQL databases: $DB_NAME"
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --databases $DB_NAME | gzip >> "$DUMP_PATH"
            fi
            ;;
        mariadb)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MariaDB databases..."
                mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --all-databases | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected MariaDB databases: $DB_NAME"
                mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --databases $DB_NAME | gzip >> "$DUMP_PATH"
            fi
            ;;
        postgresql)
            export PGPASSWORD="$DB_PASSWORD"
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all PostgreSQL databases..."
                pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected PostgreSQL databases: $DB_NAME"
                pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d "$DB_NAME" | gzip >> "$DUMP_PATH"
            fi
            ;;
        *)
            echo "Unsupported DB_TYPE: $DB_TYPE"
            exit 1
            ;;
    esac
}

# === Function to upload dump with rclone ===
upload_with_retries() {
    attempt=1
    max_attempts=3

    while [ "$attempt" -le "$max_attempts" ]; do
        echo "Attempt $attempt to upload $FILENAME to $S3_REMOTE:$S3_PATH via rclone..."
        if rclone copy "$DUMP_PATH" "$S3_REMOTE:$S3_PATH"; then
            echo "Upload successful."
            return 0
        else
            echo "Upload failed on attempt $attempt."
            attempt=$((attempt + 1))
            sleep 5
        fi
    done

    return 1
}

# === Main logic ===
dump_databases

if upload_with_retries; then
    echo "Cleaning up local backup..."
    rm -f "$DUMP_PATH"
else
    echo "Backup upload failed after 3 retries. File kept at: $DUMP_PATH"
    exit 1
fi
