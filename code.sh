#!/bin/bash
# Qcby VxCode 一键部署脚本（交互自定义端口 + Docker 镜像加速）
# 支持：直接传参 或 运行后手动输入端口

set -e

# ========== 可自定义变量 ==========
# 镜像加速器地址
REGISTRY_MIRROR="https://docker.1ms.run"
# Redis 密码（留空无密码）
REDIS_PASSWORD=""
# 镜像版本（可通过第二个参数或后面手动输入修改）
IMAGE_TAG=${2:-latest}
# =================================

echo "=== Qcby VxCode 一键安装脚本 ==="
echo "镜像加速: $REGISTRY_MIRROR"

# ---- 端口处理 ----
if [ -n "$1" ]; then
    PORT="$1"
else
    read -p "请输入访问端口（默认 8110）: " input_port
    PORT=${input_port:-8110}
fi
echo "访问端口: $PORT"
echo "镜像版本: $IMAGE_TAG"

# 1. 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo "Docker 未安装，正在自动安装..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker && systemctl start docker
    echo "Docker 安装完成。"
else
    echo "Docker 已安装。"
fi

# 2. 配置 Docker 镜像加速器
echo "正在配置 Docker 镜像加速器..."
mkdir -p /etc/docker
DAEMON_FILE="/etc/docker/daemon.json"

if [ -f "$DAEMON_FILE" ]; then
    if command -v jq &> /dev/null; then
        tmp=$(mktemp)
        jq --arg mirror "$REGISTRY_MIRROR" \
           '.["registry-mirrors"] |= (if . then (. + [$mirror] | unique) else [$mirror] end)' \
           "$DAEMON_FILE" > "$tmp" && mv "$tmp" "$DAEMON_FILE"
    else
        echo "未找到 jq，将直接覆盖 daemon.json，原有配置会被清除。"
        echo "如需保留原配置，请先备份，或安装 jq 后重新执行本脚本。"
        cat > "$DAEMON_FILE" <<EOF
{
  "registry-mirrors": ["$REGISTRY_MIRROR"]
}
EOF
    fi
else
    cat > "$DAEMON_FILE" <<EOF
{
  "registry-mirrors": ["$REGISTRY_MIRROR"]
}
EOF
fi

systemctl restart docker
echo "Docker 镜像加速器配置完成。"

# 3. 拉取镜像
echo "正在拉取镜像 qcby/qcby-vxcode:$IMAGE_TAG ..."
docker pull qcby/qcby-vxcode:$IMAGE_TAG
docker pull redis:7-alpine

# 4. 创建网络与数据卷
docker network create qcby-net 2>/dev/null || true
docker volume create qcby-vxcode-data 2>/dev/null || true
docker volume create qcby-redis-data 2>/dev/null || true

# 5. 停止并删除旧容器
docker rm -f qcby-vxcode qcby-redis 2>/dev/null || true

# 6. 启动 Redis
echo "启动 Redis..."
docker run -d \
  --name qcby-redis \
  --network qcby-net \
  -v qcby-redis-data:/data \
  --restart always \
  redis:7-alpine redis-server --appendonly yes

# 7. 启动主容器
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

# 8. 显示状态
sleep 3
echo "======================================"
echo "✅ 部署完成！"
echo "访问地址: http://$(curl -s ifconfig.me):$PORT"
echo "首次访问会自动进入初始化页面，请设置管理员账号。"
echo "容器状态："
docker ps --filter "name=qcby-"
