checkuser=$(echo whoami)
checkport=$(awk '{print substr($1,2); }' /etc/hostname)

if [[ $checkuser != root ]]; then

cd $HOME && wget https://downloads.percona.com/downloads/Percona-Server-5.7/Percona-Server-5.7.35-38/binary/tarball/Percona-Server-5.7.35-38-Linux.x86_64.glibc2.12-minimal.tar.gz && tar -xzvf Percona-Server-5.7.35-38-Linux.x86_64.glibc2.12-minimal.tar.gz && rm Percona-Server-5.7.35-38-Linux.x86_64.glibc2.12-minimal.tar.gz && mv Percona-Server-5.7.35-38-Linux.x86_64.glibc2.12-minimal/ mysql/ && mkdir mysql/mysql_secure

cd $HOME/mysql && ./bin/mysqld --initialize-insecure --user=$checkuser --basedir=$HOME/mysql/ --datadir=$HOME/mysql/data

cd $HOME/mysql && ./bin/mysqld --basedir=$HOME/mysql/ --datadir=$HOME/mysql/data --log-error=$HOME/mysql/data/mysql.err --pid-file=$HOME/mysql/mysql.pid --secure-file-priv=$HOME/mysql/mysql_secure --socket=$HOME/mysql/thesock --port=30$checkport &

else echo "DON'T RUN THIS SCRIPT AS ROOT!"
fi
