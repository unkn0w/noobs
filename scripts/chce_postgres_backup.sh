#!/usr/bin/env bash

# Zaladuj biblioteke noobs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/noobs_lib.sh" || exit 1

#In "your_location" place put your data
#Location to place backups.
BACKUP_DIR="/storage/your_location/"

#String to append to the name of the backup files
BACKUP_DATE=`date +%d-%m-%Y-%H%M%S`

#DataBase settings keep it secret
DB_NAME="data_base_name"
DB_HOST="data_base_host"
DB_PORT="data_base_port"
DB_USER="data_base_user"
DB_PASSWORD="data_base_password"

#Numbers of days you want to keep copy of your databases
NUMBER_OF_DAYS=30
echo "Dumping database to ${BACKUP_DIR}${DB_NAME}_${BACKUP_DATE}.sql"

if [ ! -d "${BACKUP_DIR}" ]; then
    mkdir -p "${BACKUP_DIR}"
fi

# Attempt to create the backup
if PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -w --format=custom | xz > "${BACKUP_DIR}${DB_NAME}_${BACKUP_DATE}.xz"; then
    echo "Dumping database finished successfully"

    # Delete old backups, but only if a current backup exists
    find "${BACKUP_DIR}" -type f -prune -mtime +"${NUMBER_OF_DAYS}" -exec rm -f {} \;
    echo "Old backups deleted"
else
    echo "Error: Dumping database failed"
fi
