
# 🚀 Qcby VxCode

> **微信小程序 Code 可视化管理面板** —— 一键部署，多架构支持，开箱即用。

---

## 📦 镜像地址

| 镜像 | 说明 |
|------|------|
| `qcby/qcby-vxcode:latest` | 最新稳定版（自动匹配架构） |
| `qcby/qcby-vxcode:<版本号>` | 指定版本（自动匹配架构） |

✅ **多架构支持**：AMD64 / x86_64 自动拉取 AMD 版；ARM64 / aarch64 自动拉取 ARM 版。

---

## 🔧 快速开始

### 1️⃣ 拉取镜像

```bash
# 最新版
docker pull qcby/qcby-vxcode:latest

# 指定版本（例如 1.0.4）
docker pull qcby/qcby-vxcode:1.0.4
```

2️⃣ 创建网络与数据卷

```bash
docker network create qcby-net 2>/dev/null
docker volume create qcby-vxcode-data
docker volume create qcby-redis-data
```

3️⃣ 启动 Redis

```bash
docker run -d \
  --name qcby-redis \
  --network qcby-net \
  -v qcby-redis-data:/data \
  --restart always \
  redis:7-alpine redis-server --appendonly yes
```

4️⃣ 启动 VxCode

```bash
docker run -d \
  --name qcby-vxcode \
  --network qcby-net \
  -p 8110:8110 \
  -v qcby-vxcode-data:/app/data \
  -v /sys:/host-sys:ro \
  -v /etc/machine-id:/host-etc/machine-id:ro \
  -e REDIS_ADDR=qcby-redis:6379 \
  --restart always \
  qcby/qcby-vxcode:latest
```

5️⃣ 访问面板

```
http://你的服务器IP:8110/
```

首次访问会自动进入初始化页面，请设置管理员账号、密码和安全码。

---

🐳 Docker Compose 方式（推荐）

创建 docker-compose.yml：

```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: qcby-redis
    command: redis-server --appendonly yes
    volumes:
      - qcby-redis-data:/data
    restart: always

  qcby-vxcode:
    image: qcby/qcby-vxcode:latest   # 多架构自动适配
    container_name: qcby-vxcode
    depends_on:
      - redis
    ports:
      - "8110:8110"
    volumes:
      - qcby-vxcode-data:/app/data
      - /sys:/host-sys:ro
      - /etc/machine-id:/host-etc/machine-id:ro
    environment:
      - REDIS_ADDR=redis:6379
    restart: always

volumes:
  qcby-vxcode-data:
  qcby-redis-data:
```

启动：

```bash
docker compose up -d
```

---

⬆️ 升级指南

升级不会删除 Redis 数据或 qcby-vxcode-data 数据卷，配置和业务数据完整保留。

```bash
# 拉取新镜像
docker pull qcby/qcby-vxcode:latest

# 删除旧容器
docker rm -f qcby-vxcode

# 启动新容器（使用相同参数）
docker run -d \
  --name qcby-vxcode \
  --network qcby-net \
  -p 8110:8110 \
  -v qcby-vxcode-data:/app/data \
  -v /sys:/host-sys:ro \
  -v /etc/machine-id:/host-etc/machine-id:ro \
  -e REDIS_ADDR=qcby-redis:6379 \
  --restart always \
  qcby/qcby-vxcode:latest
```

---

🛠 常用命令

操作 命令
📋 查看容器状态 docker ps
📜 查看业务日志 docker logs -f qcby-vxcode
📜 查看 Redis 日志 docker logs -f qcby-redis
🔄 重启业务容器 docker restart qcby-vxcode
🔄 重启 Redis docker restart qcby-redis

---

🔐 忘记密码怎么办？

```bash
docker exec qcby-vxcode sh -c 'rm -f /app/data/admin_auth.json' && docker restart qcby-vxcode
```

然后重新访问 http://服务器IP:8110/ 即可重新设置管理员账号、密码和安全码。

---

💾 数据持久化

数据类型 数据卷位置
后台配置 / 鉴权数据 qcby-vxcode-data:/app/data
Redis 缓存数据 qcby-redis-data:/data

⚠️ 请勿随意删除数据卷，否则可能导致配置丢失或登录状态失效。

---

🌐 接口说明

🔹 后台入口 /admin

· 首次访问：http://IP:8110/admin/ 进入初始化
· 之后访问：http://IP:8110/admin/你的安全码（例如 http://IP:8110/admin/123）
· 登录后自动跳转至 http://IP:8110/admin/
· 未登录或过期直接访问 /admin/ 会返回 404

---

🔹 获取小程序 Code —— /mywc

```
GET http://IP:8110/mywc?wxid=xxx&appId=xxx
```

成功返回：

```json
{
  "err": 0,
  "msg": "success",
  "appId": "wxa28c31d4ffxxxxxx",
  "status": "ok",
  "code": "0e108Xll2S1FWh4csNlxxxxxx",
  "codeType": "short_code",
  "codeLength": 32,
  "timestamp": 1782467484
}
```

---

🔹 修改微信步数 —— /mybs

```
GET http://IP:8110/mybs?wxid=xxx&num=步数（最大 98000）
```

成功返回：

```json
{
  "err": 0,
  "msg": "success",
  "wxid": "wxid_xxxxxxxx",
  "num": 12345,
  "status": "ok",
  "data": {},
  "timestamp": 1782467484
}
```

---

🔹 获取手机号 —— /mysjh

```
GET http://IP:8110/mysjh?wxid=openid&appId=xxx
```

成功返回：

```json
{
  "err": 0,
  "msg": "success",
  "wxid": "owNAX6vf06tD********",
  "appId": "wxa28c31d4f**********",
  "status": "ok",
  "data": {},
  "timestamp": 1782467484
}
```


🔹 调用云函数 —— /myyhs（POST）

支持 protocol 参数：vx 或 yyb，不传时根据 wxid/openid 长度自动判断。

```bash
curl -X POST "http://IP:8110/myyhs" \
  -H "Content-Type: application/json" \
  -d '{
    "wxid": "wxid_xxxxxxxx",
    "appId": "wxa28c31d4f*****",
    "protocol": "vx",
    "data": {
      "api_name": "qbase_commapi",
      "data": {
        "qbase_api_name": "tcbapi_get_cloudbase_info",
        "qbase_req": "{}"
      },
      "operate_directly": false
    }
  }'
```

成功返回：

```json
{
  "err": 0,
  "msg": "success",
  "wxid": "wxid_xxxxxxxx",
  "appId": "wxa28c31d4ff7********",
  "protocol": "vx",
  "status": "ok",
  "data": {},
  "timestamp": 1782467484
}
```


📌 注意事项

· ✅ 容器启动需要挂载宿主机系统信息（只读）：
  ```bash
  -v /sys:/host-sys:ro
  -v /etc/machine-id:/host-etc/machine-id:ro
  ```
· ✅ 若服务器开启防火墙，请放行 TCP 8110 端口。


📄 许可证

本项目由 Qcby 维护，仅供学习交流使用，请勿用于非法用途。


⭐ 如果觉得有用，请给个 Star 支持一下！
