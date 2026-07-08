#!/bin/bash
# Qcby VxCode 一键部署脚本
# 适用系统：Ubuntu / Debian / CentOS 7+（已安装 Docker 可直接运行）

set -e

# ========== 可自定义变量 ==========
PORT=${1:-8110}                # 访问端口，可通过第一个参数修改，如 ./install.sh 8888
IMAGE_TAG=${2:-latest}         # 镜像标签，可通过第二个参数修改，如 ./install.sh 8110 1.0.4
REDIS_PASSWORD=""              # 如需 Redis 密码，可在此设置（留空则无密码）
# =================================

echo "=== Qcby VxCode 一键安装脚本 ==="
echo "访问端口: $PORT"
echo "镜像版本: $IMAGE_TAG"

# 1. 检查 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在自动安装..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker && systemctl start docker
    echo "Docker 安装完成。"
else
    echo "Docker 已安装。"
fi

# 2. 拉取镜像
echo "正在拉取镜像 qcby/qcby-vxcode:$IMAGE_TAG ..."
docker pull qcby/qcby-vxcode:$IMAGE_TAG
docker pull redis:7-alpine

# 3. 创建网络与数据卷
docker network create qcby-net 2>/dev/null || true
docker volume create qcby-vxcode-data 2>/dev/null || true
docker volume create qcby-redis-data 2>/dev/null || true

# 4. 停止并删除旧容器（避免端口冲突）
docker rm -f qcby-vxcode qcby-redis 2>/dev/null || true

# 5. 启动 Redis
echo "启动 Redis..."
docker run -d \
  --name qcby-redis \
  --network qcby-net \
  -v qcby-redis-data:/data \
  --restart always \
  redis:7-alpine redis-server --appendonly yes

# 6. 启动主容器
echo "启动 Qcby VxCode 主容器..."
docker run -d \
  --name qcby-vxcode \
  --network qcby-net \
  -p $PORT:8110 \
  -v qcby-vxcode-data:/app/data \
  -v /sys:/host-sys:ro \
  -v /etc/machine-id:/host-etc/machine-id:ro \
  -e REDIS_ADDR=qcby-redis:6379 \
  ${REDIS_PASSWORD:+-e REDIS_PASSWORD=$REDIS_PASSWORD} \
  --restart always \
  qcby/qcby-vxcode:$IMAGE_TAG

# 7. 等待几秒，显示状态
sleep 3
echo "======================================"
echo "✅ 部署完成！"
echo "访问地址: http://$(curl -s ifconfig.me):$PORT"
echo "首次访问会自动进入初始化页面，请设置管理员账号。"
echo "容器状态："
docker ps --filter "name=qcby-"
