# mongodb-backup-s3

This Docker image provides an automated mechanism to back up a MongoDB database to an S3-compatible object storage service. The script (`run.sh`) performs the following actions:

1. Reads configuration and secrets either from environment variables or from files referenced by `_FILE` environment variables, as well as from a separate `env.sh` file.
2. Runs `mongodump` to create a gzip-compressed archive of your MongoDB database.
3. Uploads the resulting backup archive to an S3 bucket (AWS S3 or S3-compatible endpoint).
4. Optionally cleans up old backups that exceed a specified retention period.

**Key Features:**

- **S3_PREFIX for Organized Backups**: Store backups under a specific "folder" (prefix) in your bucket by setting `S3_PREFIX`.
- **Automated Scheduled Backups**: Use `SCHEDULE` to run backups at specified cron times.
- **On-demand Backups**: If `SCHEDULE` is not set, the container runs one backup and exits.
- **Restore Functionality**: Restore from the latest or a specified backup timestamp.
- **Configurable MongoDB Version**: Build with `mongo:6.0`, `mongo:7.0`, or `mongo:8.0`.
- **Multi-Arch Support**: Built for `linux/amd64` and `linux/arm64`.
- **Backup Retention**: Clean up old backups after `BACKUP_KEEP_DAYS`.

## Getting Started

### Environment Variables

You can provide configuration via environment variables directly or point them to files containing secrets. The `env.sh` file is sourced at runtime to centralize configuration defaults. Variables ending with `_FILE` take precedence if the referenced file is available.

**Supported Variables:**

| Variable                    | Description                                                                                                     | Required | Default     |
|-----------------------------|-----------------------------------------------------------------------------------------------------------------|----------|-------------|
| `MONGODB_HOST`              | Hostname or IP address of the MongoDB server.                                                                   | Yes      | N/A         |
| `MONGODB_HOST_FILE`         | File containing the MongoDB host.                                                                               | No       | N/A         |
| `MONGODB_USER`              | MongoDB username for authentication.                                                                            | No       | N/A         |
| `MONGODB_USER_FILE`         | File containing the MongoDB username.                                                                           | No       | N/A         |
| `MONGODB_PASS`              | MongoDB password for authentication.                                                                            | No       | N/A         |
| `MONGODB_PASS_FILE`         | File containing the MongoDB password.                                                                           | No       | N/A         |
| `AWS_ACCESS_KEY_ID`         | AWS or S3-compatible access key ID.                                                                             | Yes      | N/A         |
| `AWS_ACCESS_KEY_ID_FILE`    | File containing the AWS access key ID.                                                                          | No       | N/A         |
| `AWS_SECRET_ACCESS_KEY`     | AWS or S3-compatible secret access key.                                                                         | Yes      | N/A         |
| `AWS_SECRET_ACCESS_KEY_FILE`| File containing the AWS secret access key.                                                                      | No       | N/A         |
| `S3_BUCKET`                 | S3 bucket name to store the backups.                                                                            | Yes      | N/A         |
| `S3_PREFIX`                 | S3 prefix/path inside the bucket (optional).                                                                    | No       | `""`        |
| `S3_REGION`                 | AWS region or S3-compatible region (optional).                                                                  | No       | `""`        |
| `S3_ENDPOINT`               | Custom S3 endpoint URL (optional).                                                                              | No       | `""`        |
| `S3_ENDPOINT_FILE`          | File containing the S3 endpoint URL (optional).                                                                 | No       | `""`        |
| `S3_PREFIX`                 | If set, backups will be placed under this prefix (folder) in the S3 bucket (optional).                          | No       | `""`        |
| `BACKUP_KEEP_DAYS`          | Number of days to keep old backups before deletion.                                                             | No       | `7`         |
| `SCHEDULE`                  | Cron syntax. If set, backups run on the defined schedule. If not set, one backup runs and exits. (optional).    | No       | `""`        |

### Usage

### Run Once (No Schedule)

```bash
docker run --rm \
  -e MONGODB_HOST="mongo:27017" \
  -e S3_BUCKET="my-s3-bucket" \
  -e AWS_ACCESS_KEY_ID="your_access_key" \
  -e AWS_SECRET_ACCESS_KEY="your_secret_key" \
  -e S3_PREFIX="myfolder" \
  aspian87/mongodb-backup-s3:6.0
```

### Scheduled Backups

To run daily at 23:30 on Monday, Wednesday, and Friday (`30 23 * * 0,2,4` is UTC-based, adjust as needed):

```bash
docker run --rm \
  -e MONGODB_HOST="mongo:27017" \
  -e S3_BUCKET="my-s3-bucket" \
  -e AWS_ACCESS_KEY_ID="your_access_key" \
  -e AWS_SECRET_ACCESS_KEY="your_secret_key" \
  -e S3_PREFIX="myfolder" \
  -e SCHEDULE="30 23 * * 0,2,4" \
  aspian87/mongodb-backup-s3:6.0
```


### Restore from Latest Backup

**CAUTION: This drops all existing data in MongoDB!**

```bash
docker exec <container_name> sh restore.sh
```

If your bucket has more than 1000 backups, the latest may not be the actual latest due to `aws s3 ls` pagination.

### Restore from Specific Backup Timestamp

```bash
docker exec <container_name> sh restore.sh 2024-12-12T11%3A37%3A00
```

This will download and restore `mongodb-backup-20241012030000` from S3.


### Using Docker Compose

You can integrate this backup service alongside MongoDB in a docker-compose.yml:

```yaml
version: "3.9"
services:
  mongo:
    image: mongo:6.0
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: example
    ports:
      - "27017:27017"

  mongodb-backup:
    image: aspian87/mongodb-backup-s3:6.0
    environment:
      MONGODB_HOST: "mongo:27017"
      S3_BUCKET: "my-s3-bucket"
      AWS_ACCESS_KEY_ID: "your_access_key"
      AWS_SECRET_ACCESS_KEY: "your_secret_key"
      S3_PREFIX: "myfolder"
      # SCHEDULE: "30 23 * * 0,2,4"
      BACKUP_KEEP_DAYS: "14"
    depends_on:
      - mongo

```

Adjust the tag (`6.0`, `7.0`, `8.0`) as needed.

### Logging

`run.sh` provides detailed logging to aid debugging:

- **Start/End Messages**: Indicates the start and end of backup and cleanup processes.
- **Warnings/Errors**: Warns if expected variables are missing or fallback defaults are used.
- **Detailed Steps**: Logs each step such as reading secrets, dumping the database, uploading to S3, and cleaning up old backups.

---

## Contributing

Contributions are welcome! Please open an issue or pull request for any improvements, bug fixes, or feature requests.

## License

[MIT License](LICENSE) - Please see the [LICENSE](LICENSE) file for details.