#!/bin/bash

file_name=mysql*.tar.gz
file_path=/opt/$file_name
down_url=https://cdn.mysql.com/archives/mysql-5.7/mysql-5.7.44-linux-glibc2.12-x86_64.tar.gz

echo -e "\033[0;32m1.检查是否已经下载需要的安装包\033[0m"

if [ -e $file_path ]; then
    echo -e "\033[0;32m1.1安装包已存在，开始解压\033[0m"
    cd /opt ; tar -zxf $file_name ; rm -rf $file_name ; mv mysql* mysql 
    
else  
    echo -e "\033[0;32m1.1安装包不存在，开始下载\033[0m"
    wget -P $down_url /opt
    cd /opt ; tar -zxf $file_name ; rm -rf $file_name ; mv mysql* mysql
fi

echo -e "\033[0;32m2.准备工作\033[0m"
echo "2.1下载必要的依赖包"
dnf install -y ncurses-devel bison

echo "2.2创建组和用户"
groupadd mysql
useradd -r -g mysql -s /sbin/nologin -d /opt/mysql mysql
chmod -R mysql:mysql /opt/mysql

echo "2.3配置my.cnf"
cat <<EOL | tee /etc/my.cnf > /dev/null
[client]
#default login user
user=root
#default password
password=123

[mysqld-5.7]
expire_logs_days=4

[mysqld-8.0]
#auto clear binnary log , day
binlog_expire_logs_seconds=604800

[mysqld]
#########genarel config##########
#the user runnging mysqld process
user=mysql
#base directory
basedir=/opt/mysql
#data directory
datadir=/opt/mysql/data
#db server character set
character_set_server=utf8
#default engine
default_storage_engine=innodb
#server id
server_id=1
#service port
port=3306
#max connections
max_connections=1000
#skip resolve name
skip_name_resolve=on
#pid file's directory
pid-file=/opt/mysql/data/db1.pid
#ignore table name case
lower_case_table_names=1
#copy proceduer on replication
log_bin_trust_function_creators=1


######log part####
#swith on genarel log
#general_log=on
#name and directory of genarel log
general_log_file=/opt/mysql/data/db1.general
#swith on binnary log and set the file
log-bin=/opt/mysql/data/db1-bin
#index of bannary log
log_bin_index=/opt/mysql/data/db1.index
#swith bannary log
slow_query_log=on
#name and directory of slow query log
slow_query_log_file=/opt/mysql/data/db1.slow
#the unit of slow log ，second
long_query_time=1
#record query not use index into slow log
log_queries_not_using_indexes=1
#error log setting
log_error=/opt/mysql/data/db1.err
#auto clear binnary log , day
#set datetime format with system
log_timestamps=SYSTEM

######innodb setting ######
#innodb memory size，byte
innodb_buffer_pool_size=2048M
#innodb instance number
innodb_buffer_pool_instances=2
#dump cache from memory to disk when server shutdown
innodb_buffer_pool_dump_at_shutdown=off
#record page cache immediate
innodb_buffer_pool_dump_now=off
#import cache from disk to memory when server startup
innodb_buffer_pool_load_at_startup=off
#immediate cache buffer_pool
innodb_buffer_pool_load_now=off
#log buffer 8M to 32M
innodb_log_buffer_size=8M
#the size of binnary log
innodb_log_file_size=256M
#the action of write log to disk:0--flush per second;1--flush on tranction commit(default); 2--0 and 1
innodb_flush_log_at_trx_commit=1
#enable innodb monitor
innodb_monitor_enable=all
#innodb can open files
innodb_open_files=32263
table_open_cache=32263
open_files_limit=65536
innodb_data_file_path=ibdata1:2G:autoextend
innodb_undo_tablespaces=2

######MyIsam setting######
key_buffer_size=64M
read_buffer_size=256K
read_rnd_buffer_size=256K
sort_buffer_size=256K
join_buffer_size=256K


####replication setting#########
log-bin-trust-function-creators=1
#enable gtid mode
gtid_mode=ON
#enforce gtid consistency
enforce_gtid_consistency=ON
#master info storage in table
master_info_repository=TABLE
#relay log info storage in table
relay_log_info_repository=TABLE
#relay log file name
relay_log=/opt/mysql/data/db1-relay
#write binlog when slave apply relay-log
log_slave_updates=ON
#binlog format
binlog_format=ROW
#semi_sync
#rpl_semi_sync_master_enabled=on
#rpl_semi_sync_master_timeout=1000
#rpl_semi_sync_slave_enabled=on
#multi thread
slave_parallel_type=logical_clock
slave_parallel_workers=4

#####group replication####
#slave_preserve_commit_order=1
#binlog_checksum=NONE
#collection trasaction information
#transaction_write_set_extraction=XXHASH64
#name of relication group
#loose-group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
#do nothing when server start
#loose-group_replication_start_on_boot=off
#local host address and port
#loose-group_replication_local_address="10.2.5.15:33061"
#address and port of server in the replication group
#loose-group_replication_group_seeds="10.2.5.15:33061,10.2.5.16:33061,10.2.5.17:33061,10.2.5.18:33061"
#the init server set on,any time only one swtich on
#loose-group_replication_bootstrap_group=off
EOL

echo "2.4创建数据文件夹"
mkdir -p /opt/mysql/data

echo -e "\033[0;32m3.开始安装\033[0m"
/opt/mysql/bin/mysqld --no-defaults --initialize --user=mysql --basedir=/opt/mysql --datadir=/opt/mysql/data --innodb-data-file-path=ibdata1:2G:autoextend --innodb_undo_tablespaces=2 --lower-case-table-names=1

echo "启动mysql服务"
/opt/mysql/support-files/mysql.server start
