# Autodumper

Autodumper is a docker image that backups databases and sends the data to a remote host using Rclone. It can be useful for performing hot backups and storing them encrypted on S3.

## Supported Databases

- MySQL
- MariaDB
- Postgres

### Backup Encryption

Encryption is optional but highly recommended for securing your backups. This image uses **[age](https://github.com/FiloSottile/age)** for simple and secure public-key encryption.

**To enable encryption**, place your `age` public key file in the backup volume and name it `key.pub`.

  * **With Encryption**: If `/data/key.pub` exists, backups are automatically compressed and encrypted.
  * **Without Encryption**: If no key file is found, backups are only compressed with gzip.

### How to Restore

You can easily restore your backup using standard command-line tools.

#### Restoring an Encrypted Backup

You'll need your `age` private key to decrypt the file. The command below decrypts the backup and then uncompresses it.

```bash
# Decrypts and uncompresses the backup file
age -d -i /path/to/your/private.key backup.adump | gunzip > original_dump.sql
```

#### **Restoring an Unencrypted Backup (.sql.gz)**

For unencrypted backups, you only need to uncompress the file using `gunzip`.

```bash
# Uncompresses the backup file
gunzip -k backup.adump > original_dump.sql
```

**Note**: The `-k` flag is used to keep the original `.adump` file; you can omit it if you don't need to keep the compressed backup.

## How to run

### Command-line

Run 
```
docker run --rm \
  -e DB_HOST=mysql \
  -e DB_PORT=3306 \
  -e DB_USER=testuser \
  -e DB_PASSWORD=testpass \
  -e DB_NAME="testdb1 testdb2" \
  -e DB_TYPE=mysql \
  -e S3_REMOTE=myremote \
  -e S3_PATH=mybucket/backups \
  -e DUMP_PREFIX="backup_" \
  -v $(pwd)/rclone.conf:/root/.config/rclone/rclone.conf:ro \
  -v $(pwd)/yourage.pub:/data/key.pub:ro \
  casfergroup/autodumper:latest

```

### Docker compose

See examples on [examples/](examples/).

### Periodic backups

If you want to schedule periodic backups, create a cron on the host. Currently the image doesn't support cron by itself
