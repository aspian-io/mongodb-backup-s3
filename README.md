# mongodb-backup-s3

This Docker image provides an automated mechanism to back up a MongoDB database to an S3-compatible object storage service. The script (`run.sh`) performs the following actions:

1. Reads configuration and secrets either from environment variables or from files referenced by `_FILE` environment variables, as well as from a separate `env.sh` file.
2. Runs `mongodump` to create a gzip-compressed archive of your MongoDB database.
3. Uploads the resulting backup archive to an S3 bucket (AWS S3 or S3-compatible endpoint).
4. Optionally cleans up old backups that exceed a specified retention period.

**Key Features:**

- **Docker Secrets & Env Files**: Easily inject credentials and configurations via Docker secrets or environment variables, securely decoupling sensitive data from the code.
- **Configurable S3 Endpoint & Region**: Supports custom S3 endpoints and regions, enabling use with AWS, MinIO, or other S3-compatible object stores.
- **Backup Retention**: Automatically clean up old backups based on a defined retention period.
- **Multi-Architecture Support**: Build and push images for both `linux/amd64` and `linux/arm64` platforms.

## Getting Started

### Environment Variables

You can provide configuration via environment variables directly or point them to files containing secrets. The `env.sh` file is sourced at runtime to centralize configuration defaults. Variables ending with `_FILE` take precedence if the referenced file is available.

**Supported Variables:**

| Variable                    | Description                                                                           | Required | Default     |
|-----------------------------|---------------------------------------------------------------------------------------|----------|-------------|
| `MONGODB_HOST`              | Hostname or IP address of the MongoDB server.                                         | Yes      | N/A         |
| `MONGODB_HOST_FILE`         | File containing the MongoDB host.                                                     | No       | N/A         |
| `MONGODB_USER`              | MongoDB username for authentication.                                                  | No       | N/A         |
| `MONGODB_USER_FILE`         | File containing the MongoDB username.                                                 | No       | N/A         |
| `MONGODB_PASS`              | MongoDB password for authentication.                                                  | No       | N/A         |
| `MONGODB_PASS_FILE`         | File containing the MongoDB password.                                                 | No       | N/A         |
| `AWS_ACCESS_KEY_ID`         | AWS or S3-compatible access key ID.                                                   | Yes      | N/A         |
| `AWS_ACCESS_KEY_ID_FILE`    | File containing the AWS access key ID.                                                | No       | N/A         |
| `AWS_SECRET_ACCESS_KEY`     | AWS or S3-compatible secret access key.                                               | Yes      | N/A         |
| `AWS_SECRET_ACCESS_KEY_FILE`| File containing the AWS secret access key.                                            | No       | N/A         |
| `S3_BUCKET`                 | S3 bucket name to store the backups.                                                  | Yes      | N/A         |
| `S3_PREFIX`                 | S3 prefix/path inside the bucket (optional).                                          | No       | `""`        |
| `S3_REGION`                 | AWS region or S3-compatible region (optional).                                        | No       | `""`        |
| `S3_ENDPOINT`               | Custom S3 endpoint URL (optional).                                                    | No       | `""`        |
| `S3_ENDPOINT_FILE`          | File containing the S3 endpoint URL (optional).                                       | No       | `""`        |
| `BACKUP_KEEP_DAYS`          | Number of days to keep old backups before deletion.                                    | No       | `7`         |

### Usage with Docker

```bash
docker run --rm \
    -e MONGODB_HOST="mongo:27017" \
    -e AWS_ACCESS_KEY_ID="your_access_key" \
    -e AWS_SECRET_ACCESS_KEY="your_secret_key" \
    -e S3_BUCKET="your_s3_bucket" \
    -e S3_REGION="us-east-1" \
    -v /run/secrets:/run/secrets:ro \
    ghcr.io/aspian-io/mongodb-backup-s3:latest
```

If you prefer Docker secrets:
```bash
docker run --rm \
    -e MONGODB_HOST_FILE="/run/secrets/mongodb_host" \
    -e AWS_ACCESS_KEY_ID_FILE="/run/secrets/aws_access_key_id" \
    -e AWS_SECRET_ACCESS_KEY_FILE="/run/secrets/aws_secret_access_key" \
    -e S3_BUCKET="your_s3_bucket" \
    -v /run/secrets:/run/secrets:ro \
    ghcr.io/aspian-io/mongodb-backup-s3:latest
```

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
      BACKUP_KEEP_DAYS: "14"
    depends_on:
      - mongo
    # Optionally, mount secrets or configure a cron-like scheduler externally
```
Change the tag (e.g. aspian87/mongodb-backup-s3:7.0 or 8.0) as needed.

### Kubernetes CronJob Example

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mongodb-backup
spec:
  schedule: "0 2 * * *" # daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: mongodb-backup
              image: ghcr.io/aspian-io/mongodb-backup-s3:latest
              env:
                - name: MONGODB_HOST
                  value: "my-mongo-service:27017"
                - name: S3_BUCKET
                  value: "my-s3-bucket"
                - name: BACKUP_KEEP_DAYS
                  value: "14"
              # If using secrets:
              # env:
              # - name: AWS_ACCESS_KEY_ID_FILE
              #   value: /run/secrets/aws_access_key_id
              # - name: AWS_SECRET_ACCESS_KEY_FILE
              #   value: /run/secrets/aws_secret_access_key
              volumeMounts:
                - name: secrets
                  mountPath: /run/secrets
                  readOnly: true
          volumes:
            - name: secrets
              secret:
                secretName: aws-credentials
          restartPolicy: OnFailure
```

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