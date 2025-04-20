#!/bin/sh

# === Internal variables ===
DATE_STR=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="${DUMP_PREFIX}_${DATE_STR}.sql.gz"
DUMP_PATH="/data/${FILENAME}"

# === Function to dump database(s) ===
dump_databases() {
    case "$DB_TYPE" in
        mysql)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MySQL databases..."
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --all-databases | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected MySQL databases: $DB_NAME"
                IFS=',' read -r DBS <<< "$DB_NAME"
                for db in $DBS; do
                    mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$db" | gzip >> "$DUMP_PATH"
                done
            fi
            ;;
        mariadb)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MariaDB databases..."
                mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" --all-databases | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected MariaDB databases: $DB_NAME"
                IFS=',' read -r DBS <<< "$DB_NAME"
                for db in $DBS; do
                    mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" "$db" | gzip >> "$DUMP_PATH"
                done
            fi
            ;;
        postgresql)
            export PGPASSWORD="$DB_PASSWORD"
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all PostgreSQL databases..."
                pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" | gzip > "$DUMP_PATH"
            else
                echo "Dumping selected PostgreSQL databases: $DB_NAME"
                IFS=',' read -r DBS <<< "$DB_NAME"
                for db in $DBS; do
                    pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" "$db" | gzip >> "$DUMP_PATH"
                done
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
