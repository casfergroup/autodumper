#!/bin/bash

# === File Permssions ==
umask 077

# == ENV Validation ==
required_vars="DB_HOST DB_USER DB_PASSWORD DB_TYPE S3_REMOTE S3_PATH"
for var in $required_vars; do
    eval "value=\${$var}"
    if [ -z "$value" ]; then
        echo "Error: Required variable $var is not set!"
        exit 1
    fi
done

# === Internal variables ===
local date_str=$(date +"%Y-%m-%d_%H-%M-%S")
local filename
if [ -n "$DB_NAME" ]; then
    filename="${DUMP_PREFIX}_${DB_NAME}_${date_str}.sql.gz"
else
    filename="${DUMP_PREFIX}_${date_str}.sql.gz"
fi
local dump_path="/data/${filename}"

# === Function to process the dump ===
process_dump_stream() {
  local output_path="$1"
  local key_file="/data/key.pub"

  if [ -f "$key_file" ]; then
    echo "Key found at $key_file. Compressing and encrypting stream..." >&2
    gzip | age -e -R "$key_file" > "${output_path}.age"
  else
    echo "Key not found. Compressing stream only..." >&2
    gzip > "${output_path}.sql.gz"
  fi
}

# === Function to dump database(s) ===
dump_databases() {
    case "$DB_TYPE" in
        mysql)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MySQL databases..."
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --all-databases | process_dump_stream "$dump_path"
            else
                echo "Dumping selected MySQL databases: $DB_NAME"
                mysqldump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --databases $DB_NAME | process_dump_stream "$dump_path"
            fi
            ;;
        mariadb)
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all MariaDB databases..."
                mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --all-databases | process_dump_stream "$dump_path"
            else
                echo "Dumping selected MariaDB databases: $DB_NAME"
                mariadb-dump -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p$DB_PASSWORD --databases $DB_NAME | process_dump_stream "$dump_path"
            fi
            ;;
        postgresql)
            export PGPASSWORD="$DB_PASSWORD"
            if [ -z "$DB_NAME" ]; then
                echo "Dumping all PostgreSQL databases..."
                pg_dumpall -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" | process_dump_stream "$dump_path"
            else
                echo "Dumping selected PostgreSQL databases: $DB_NAME"
                pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$PG_USER" -d "$DB_NAME" | process_dump_stream "$dump_path"
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
        echo "Attempt $attempt to upload $filename to $S3_REMOTE:$S3_PATH via rclone..."
        if rclone copy "$dump_path" "$S3_REMOTE:$S3_PATH"; then
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
    rm -f "$dump_path"
else
    echo "Backup upload failed after 3 retries. File kept at: $dump_path"
    exit 1
fi
