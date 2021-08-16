#!/bin/bash 

set -e


## 使用方法
## install: sh geth.sh install
## upgrade: sh geth.sh upgrade

if [ -z "$1" ]; then
  exit 1
fi


# 指定 geth 版本
GETH_VERSION=${GETH_VERSION:-geth-linux-amd64-1.10.7-12f0ff40}


mkdir -p /data/eth
cd /data/eth


echo "下载安装 geth"
wget "https://gethstore.blob.core.windows.net/builds/${GETH_VERSION}.tar.gz"
tar -xzvf "${GETH_VERSION}.tar.gz"
rm -f /data/eth/geth && ln -s /data/eth/${GETH_VERSION} /data/eth/geth
ls -la

if  ["$1" == "install"];  then
    echo "安装服务 geth.service"
    cat <<-EOF > /etc/systemd/system/geth.service
[Unit]
Description=Geth
After=network.target

[Service]
LimitNOFILE=65535
Environment="DATA_DIR=/data/eth/gethdata"
Environment="DAG_DIR=/data/eth/gethdata/dag"
Environment="GETH_API_OPTS=--http --http.addr 0.0.0.0"
#Environment="GETH_MINE_OPTS=--mine --miner.etherbase 0x65A07d3081a9A6eE9BE122742c84ffea6964aCd2"
Environment="GETH_ETHASH_OPTS=--ethash.dagdir /data/eth/gethdata/dag"
Environment="GETH_EXTRA_OPTS=--datadir /data/eth/gethdata --maxpeers 1000 --cache 4096 --syncmode fast"
Environment="GETH_METRICS_OPTS=--metrics --metrics.addr 0.0.0.0 --metrics.port 6060"

Type=simple
User=root
Restart=always
RestartSec=12
ExecStart=/data/eth/geth/geth $GETH_API_OPTS $GETH_NETWORK_OPTS $GETH_MINE_OPTS $GETH_ETHASH_OPTS $GETH_METRICS_OPTS $GETH_EXTRA_OPTS

[Install]
WantedBy=default.target
EOF

    mkdir -p /etc/systemd/system/geth.service.d
    cat <<EOF > /etc/systemd/system/geth.service.d/limit.conf
[Service]
LimitNOFILE=65535
EOF
    
fi

echo "启动 geth"
systemctl enable geth
systemctl daemon-reload && systemctl restart geth
systemctl status geth
