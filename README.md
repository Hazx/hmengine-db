# HMengine-DB

HMengine-DB 是一个基于 MySQL 8 构建并进行了性能调优的数据库引擎，数据库读写性能相较传统 MySQL （默认参数）有着翻倍提升。~~如需高可用集群化部署可以使用 [HMengine-DBC](https://github.com/Hazx/hmengine-dbc)。~~

对应镜像及版本：

- `hazx/hmengine-db:1.1-r1`
- `hazx/hmengine-db:1.1-r1-arm`

# 组件版本

- MySQL：8.0.41

# 使用镜像

你可以直接下载使用我编译好的镜像 `docker pull hazx/hmengine-db:1.1-r1`（ARM64 平台使用 1.1-r1-arm），你也可以参照 [编译与打包](#编译与打包) 部分的说明自行编译打包镜像。

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
    hazx/hmengine-db:1.1-r1
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
DB_MEM | 工作内存 | 容量 | 主机可用内存 | √

**Tips:**

- `DB_PASSWORD` : 仅在首次初始化时生效。
- `DB_IIC` : 调优建议：机械硬盘100\~200，SATA固态2000\~8000，PCIE固态10000\~20000，带缓存的固态集群可更高。可参考实际存储测试的IOPS结果。（对应参数：innodb_io_capacity）
- `DB_IRLC` : 调优建议：存储快、CPU强则可开到1G、2G甚至更高。调大可提高读写性能，但会增加数据库意外关闭后的启动(恢复)时间。（对应参数：innodb_redo_log_capacity）
- `DB_MEM` : 用于自动调优参考的内存容量，非实际使用或限制的容量。不可大于主机内存。参考写法：1024M、8G。

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





