# Autodumper
Autodumper is a docker image that backups databases and sends the data to a remote host using Rclone. It can be useful for performing hot backups and storing them on S3.

## Supported Databases
- MySQL
- MariaDB
- Postgres

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
  casfergroup/autodumper:latest

```

### Docker compose
See examples on [examples/](examples/).

### Periodic backups
If you want to schedule periodic backups, create a cron on the host. Currently the image doesn't support cron by itself
