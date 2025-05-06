#!/bin/bash

## 源码编译-源码来源
## https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.42.tar.gz


docker_path=hazx
docker_img=hmengine-db
docker_tag=1.3-r0
docker_base=ubuntu:jammy-20240911.1
## 编译线程数
make_threads=${1:-2}

arch=$(uname -p)
if [[ $arch == "aarch64" ]] || [[ $arch == "arm64" ]];then
    docker_tag=${docker_tag}-arm
fi

## 清理工作目录
rm -fr build_${docker_img}
rm -f output/${docker_img}-${docker_tag}.tar

## 准备工作
mkdir -p build_${docker_img}
cp -R build build_${docker_img}/
echo "export set_make_threads=\"${make_threads}\"" >> build_${docker_img}/build/IDR-buildvar-sh
if [ $http_proxy ];then
    echo "export http_proxy=${http_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
if [ $https_proxy ];then
    echo "export https_proxy=${https_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
if [ $no_proxy ];then
    echo "export no_proxy=${no_proxy}" >> build_${docker_img}/build/IDR-buildvar-sh
fi
pwd_dir=$(cd $(dirname $0); pwd)
export BUILDKIT_STEP_LOG_MAX_SIZE=-1


## 构建编译环境镜像
echo "构建编译环境镜像..."
cat <<EOF > build_${docker_img}/build/Dockerfile
FROM ${docker_base}
COPY IDR-build-base-sh /root/hazx/build.sh
RUN chmod a+x /root/hazx/*.sh ;\
    /root/hazx/build.sh
EOF
docker build --progress=plain -t ${docker_img}:${docker_tag}-build-base build_${docker_img}/build/


## 编译MySQL
echo "准备开始编译MySQL..."
rm -f build_${docker_img}/build/Dockerfile
cat <<EOF > build_${docker_img}/build/Dockerfile
FROM ${docker_img}:${docker_tag}-build-base
COPY src /root/hazx/src
COPY IDR-build-export-sh /root/hazx/export.sh
COPY IDR-build-mysql-sh /root/hazx/build.sh
COPY IDR-buildvar-sh /root/hazx/buildvar.sh
RUN chmod a+x /root/hazx/*.sh ;\
    /root/hazx/build.sh
CMD /root/hazx/export.sh
EOF
docker build --progress=plain -t ${docker_img}:${docker_tag}-build-mysql build_${docker_img}/build/
mkdir -p build_${docker_img}/package
docker run --rm --name tmp-hmengine-build-export-mysql \
    -v ${pwd_dir}/build_${docker_img}/package:/export \
    ${docker_img}:${docker_tag}-build-mysql


## 打包最终镜像
echo "正在打包最终镜像..."
mkdir -p output
cp build/IDR-imginit-sh build_${docker_img}/package/img_init.sh
cp build/IDR-dbserver-sh build_${docker_img}/package/dbserver.sh
cp build/etc/default.cnf build_${docker_img}/package/default.cnf
cp build/etc/init.cnf build_${docker_img}/package/init.cnf
rm -f build_${docker_img}/package/Dockerfile
cat <<EOF > build_${docker_img}/package/Dockerfile
FROM ${docker_base}
LABEL maintainer="hazx632823367@gmail.com"
LABEL Version="${docker_tag}"
COPY db_server /db_server
COPY img_init.sh /
COPY dbserver.sh /db_server/
COPY default.cnf /root/
COPY init.cnf /root/
RUN chmod a+x /img_init.sh ;\
    /img_init.sh ;\
    rm -f /img_init.sh
WORKDIR /db_server
ENV PATH=/db_server/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
CMD /db_server/dbserver.sh
EXPOSE 6000
EOF
docker build --progress=plain -t ${docker_path}/${docker_img}:${docker_tag} build_${docker_img}/package/
docker save ${docker_path}/${docker_img}:${docker_tag} | gzip -c > output/${docker_img}-${docker_tag}.tar.gz

## 清理垃圾
docker rmi ${docker_img}:${docker_tag}-build-base
docker rmi ${docker_img}:${docker_tag}-build-mysql
docker rmi ${docker_path}/${docker_img}:${docker_tag}
rm -fr build_${docker_img}

echo ""
echo "Docker镜像制作完成"
echo "镜像地址: ${docker_path}/${docker_img}:${docker_tag}"
echo "镜像文件: output/${docker_img}-${docker_tag}.tar.gz"
echo "Tips: 一些设备（例如绿联NAS）不支持.tar.gz扩展名，你需要在上传前重命名为.tar"
echo ""
