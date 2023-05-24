#!/bin/bash

#In "xxx" place put your data
#Location to place backups.
BACKUP_DIR="/storage/xxx/"

#String to append to the name of the backup files
BACKUP_DATE=`date +%d-%m-%Y-%H%M%S`

#DataBase settings
DB_NAME="xxx"
DB_HOST="xxx"
DB_PORT="xxx"
DB_USER="postgres"
DB_PASSWORD="xxx"

#Numbers of days you want to keep copie of your databases
NUMBER_OF_DAYS=180
echo "Dumping database to ${BACKUP_DIR}${DB_NAME}_${BACKUP_DATE}.sql" 

if [ ! -d "${BACKUP_DIR}" ]; then
    mkdir -p "${BACKUP_DIR}"
fi 
   
PGPASSWORD="${DB_PASSWORD}" pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -w --format=custom | xz > "${BACKUP_DIR}${DB_NAME}_${BACKUP_DATE}.xz"

find "${BACKUP_DIR}" -type f -prune -mtime +"${NUMBER_OF_DAYS}" -exec rm -f {} \;
