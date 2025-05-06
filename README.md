# HMengine-DB

HMengine-DB 是一个基于 MySQL 8 构建并进行了性能调优的数据库引擎，数据库读写性能相较默认参数的 MySQL 有着翻倍提升。

对应镜像及版本：

- `hazx/hmengine-db:1.3-r0`
- `hazx/hmengine-db:1.3-r0-arm`

# 组件版本

- MySQL：8.0.42

# 使用镜像

你可以直接下载使用我编译好的镜像 `docker pull hazx/hmengine-db:1.3-r0`（ARM64 平台使用 1.3-r0-arm），你也可以参照 [编译与打包](#编译与打包) 部分的说明自行编译打包镜像。

## 内部路径映射参考

- 数据目录：`/db_server/data`
- 自定义配置文件：`/db_server/etc/custom.cnf`
- 运行日志：`/db_server/db.log`
- Socket: `/db_server/socket/mysql.sock`

*自定义配置文件仅会将填写的配置替换默认配置，不会影响其他性能调优参数。部分参数仅能通过环境变量配置。*

## 内部端口映射参考

- 6000/TCP：数据库默认端口

## 创建容器示例

```shell
docker run -d --cap-add SYS_NICE \
    --name db \
    -p 6000:6000 \
    -v /home/db_data:/db_server/data \
    -e DB_PASSWORD=PaSsWoRd1234 \
    hazx/hmengine-db:1.3-r0
```

## 环境变量

环境变量 | 功能说明 | 参数值 | 默认值 | 仅可通过环境变量配置
---|---|---|---|---
DB_PASSWORD | 数据库root账户密码 (必填) | 字符串 | | √
DB_PORT | 数据库监听端口 | 数字 | 6000 | √
DB_AUTHPLUG | 认证插件 | caching_sha2_password/<br />mysql_native_password/<br />sha256_password | caching_sha2_password | 
DB_IIC | 存储IOPS | 数字 (小于40000) | 1000 | 
DB_IRLC | 重做日志大小 | 容量 | 256M | 
DB_LCTN | 表名大小写不敏感 | false/true | false | 
DB_MAXPKT | 数据包限制大小 | 容量 | 32M | 
DB_MEM | 工作内存 | 容量 | 主机可用内存 | √

**Tips:**

- `DB_PASSWORD` : 仅在首次初始化时生效。
- `DB_IIC` 调优建议: 机械硬盘100\~200，SATA固态2000\~8000，PCIE固态10000\~20000，带缓存的固态集群可更高。可参考实际存储测试的IOPS结果。（对应参数：innodb_io_capacity）
- `DB_IRLC` 调优建议: 存储快、CPU强则可开到1G、2G甚至更高。调大可提高读写性能，但会增加数据库意外关闭后的启动(恢复)时间。（对应参数：innodb_redo_log_capacity）
- `DB_MEM` : 用于自动调优参考的内存容量，非实际使用或限制的容量。不可大于主机内存。参考写法：1024M、8G。

## 数据库默认参数

参数名 | 参数值
---|---
datadir | /db_server/data
log_bin | /db_server/data/mysql-bin
pid_file | /db_server/mysqld.pid
plugin_dir | /db_server/lib/plugin
secure_file_priv | /db_server/mysql-files
socket | /db_server/socket/mysql.sock
slow_query_log_file | /db_server/data/db-slow.log
tmpdir | /db_server/tmp
bind_address | 0.0.0.0
character_set_server | utf8mb4
collation_server | utf8mb4_general_ci
default_authentication_plugin | caching_sha2_password
default_storage_engine | innodb
lower_case_table_names | 0
slow_query_log | 0
back_log | 3000
binlog_cache_size | 2097152
binlog_transaction_dependency_history_size | 500000
binlog_transaction_dependency_tracking | WRITESET
default_time_zone | +08:00
event_scheduler | off
explicit_defaults_for_timestamp | 
innodb_buffer_pool_instances | (动态调优)
innodb_buffer_pool_size | (动态调优)
innodb_flush_log_at_trx_commit | 2
innodb_flush_method | O_DIRECT
innodb_io_capacity | 1000
innodb_io_capacity_max | 40000
innodb_lru_scan_depth | (动态调优)
innodb_max_dirty_pages_pct | 75
innodb_open_files | 20000
innodb_page_cleaners | (动态调优)
innodb_purge_threads | (动态调优)
innodb_redo_log_capacity | 256M
innodb_sort_buffer_size = 4M
innodb_sync_array_size | 128
interactive_timeout | 7200
join_buffer_size | (动态调优)
long_query_time | 10
max_allowed_packet | 32M
max_connections | 2000
max_error_count | 64
max_heap_table_size | 67108864
max_user_connections | 1000
max_write_lock_count | 102400
myisam_sort_buffer_size | 262144
open_files_limit | 1048576
optimizer_trace_max_mem_size | 16384
read_buffer_size | (动态调优)
server_id | 1
skip_binlog_order_commits
skip_name_resolve
sort_buffer_size = 4M
sql_mode | ONLY_FULL_GROUP_BY,<br />STRICT_TRANS_TABLES,<br />NO_ZERO_IN_DATE,<br />NO_ZERO_DATE,<br />ERROR_FOR_DIVISION_BY_ZERO,<br />NO_ENGINE_SUBSTITUTION
table_definition_cache | (动态调优)
table_open_cache | (动态调优)
thread_cache_size | 100
tmp_table_size | 2M
transaction_isolation | READ-COMMITTED
wait_timeout | 86400

# 编译与打包

*需要注意，编译和打包阶段需要 Docker 环境，且依赖互联网来安装编译和运行环境。*

## 编译并打包

> 编译阶段下载安装的依赖环境不会应用到你的系统环境，且在编译完成后不保留临时编译环境镜像。

你可以按需修改 `build` 文件夹下的内容。

然后执行以下命令开始编译与打包：

```shell
bash build.sh
```

编译过程默认采用 2 线程进行，若你想提高编译线程数，可以执行如下命令，在结尾带上线程数字：

```shell
bash build.sh 8
```

## 编译参数

编译默认采用如下参数配置 MySQL ，如有特殊需求可自行修改。

```shell
cmake .. \
    -DCMAKE_INSTALL_PREFIX=/db_server \
    -DMYSQL_DATADIR=/db_server/data \
    -DWITH_BOOST=../boost \
    -DDOWNLOAD_BOOST=1 \
    -DSYSCONFDIR=/db_server/etc \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DENABLED_LOCAL_INFILE=ON \
    -DWITH_SSL=system \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DWITH_ZLIB=bundled \
    -DWITH_LIBWRAP=0
```





