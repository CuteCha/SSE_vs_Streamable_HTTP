# service-b —— SSE 服务端推送事件演示

用 Spring Boot 演示 SSE（Server-Sent Events）服务端主动推送：浏览器通过 `EventSource` 建立长连接，服务端持续单向推送数据，页面无需刷新、无需轮询即可自动更新。

核心代码：
- 前端 `index.html`：通过 `EventSource` 订阅 SSE 接口，实时更新页面（实现"网页自动刷新"）
- 后端 `SseEmitterController.java`：按 SSE 规范（`data: 内容\n\n`）用 `PrintWriter` 持续推送

项目已包含启动类、`pom.xml`、`application.yml`，开箱即用。

## 项目结构
```
proj_java/
├── pom.xml                                   # Spring Boot 2.7（spring-boot-starter-web）
├── .gitignore                                # 忽略 target/、logs/ 等构建产物
├── scripts/
│   ├── build.sh                              # 打包脚本（mvn clean package）
│   └── app.sh                                # jar 启停脚本（start/stop/restart/status）
└── src/main/
    ├── java/com/example/serviceb/
    │   ├── ServiceBApplication.java          # 启动类
    │   └── controller/SseEmitterController.java  # SSE 接口（核心代码）
    └── resources/
        ├── application.yml                   # 端口 8080
        ├── static/index.html                 # 前端订阅页面（订阅 /sse，持续推送）
        └── static/sse-retry.html             # retry 演示页面（订阅 /sse-retry，自动重连）
```

## 接口
| 接口 | 说明 |
|---|---|
| `GET /sse` | 每隔 1 秒推送一次当前时间，连接持续不断开 |
| `GET /sse-retry` | 推送一次后结束连接，并通过 `retry: 2000` 让浏览器 2 秒后自动重连 |
| `GET /index.html` | 前端页面，`EventSource` 订阅 `/sse`（持续推送版） |
| `GET /sse-retry.html` | 前端页面，`EventSource` 订阅 `/sse-retry`（自动重连版） |

## 运行步骤（需 JDK 17+ 与 Maven）
```bash
cd proj_java
mvn spring-boot:run
```

启动后浏览器打开：<http://localhost:8080/index.html>

## 打包与运行 jar
```bash
# 1. 打成可执行 jar（跳过测试），产物：target/service-b.jar
mvn -B clean package -DskipTests

# 2. 前台运行 jar
java -jar target/service-b.jar

# 指定端口 / JVM 参数运行
java -Xms128m -Xmx256m -jar target/service-b.jar --server.port=9090

# 后台运行（日志写入 logs/app.log）
mkdir -p logs && nohup java -jar target/service-b.jar > logs/app.log 2>&1 &
```

## 一键脚本
| 脚本 | 说明 |
|---|---|
| `scripts/build.sh` | 打包：`mvn -B clean package -DskipTests`，产物 `target/service-b.jar` |
| `scripts/app.sh start` | 启动（已在运行则提示 PID，不重复启动） |
| `scripts/app.sh stop` | 停止（先 `kill` 优雅退出，超时后 `kill -9`） |
| `scripts/app.sh restart` | 重启（先停后启） |
| `scripts/app.sh status` | 查看运行状态与 PID |

```bash
chmod +x scripts/*.sh        # 首次使用需赋予执行权限
./scripts/build.sh           # 打包
./scripts/app.sh start       # 启动
curl -N http://localhost:8080/sse
./scripts/app.sh restart     # 重启
./scripts/app.sh status      # 查看状态
./scripts/app.sh stop        # 停止
```

脚本说明：
- 端口与 JVM 参数可用环境变量覆盖：`PORT=9090 JAVA_OPTS="-Xmx512m" ./scripts/app.sh start`
- 进程 PID 记录在 `logs/app.pid`，日志追加到 `logs/app.log`

页面上的 `#sse` 区域会每秒自动刷新显示服务器推送的时间（如 `Fri Nov 04 21:40:46 CST 2022`），即"网页自动刷新"效果。

## 两点实现说明
1. **响应头设置**：`Content-Type` 为 `text/event-stream;charset=UTF-8`，并加 `Cache-Control: no-cache`，避免中间层缓冲导致推送延迟。
2. **前端订阅地址使用相对路径 `/sse`**：本项目默认跑在 8080，使用 `http://localhost/sse`（80 端口）这类绝对地址会跨域失败；改为同源相对路径后开箱即用。若服务确实跑在 80 端口，改回绝对地址亦可。

## /sse-retry 怎么用
`/sse-retry` 演示的是 **SSE 的断线重连机制**，它和 `/sse` 的区别：

| 对比 | `/sse` | `/sse-retry` |
|---|---|---|
| 连接 | 一条长连接持续推送 | 推 1 条后服务端主动结束响应 |
| 首行 | 无 | `retry: 2000`（重连间隔 2000ms） |
| 客户端行为 | 一直收数据 | 断开后由 `EventSource` 每 2 秒自动重连，再收 1 条，如此循环 |
| 适用场景 | 高频实时数据 | 低频/一次性数据，避免长期占用连接 |

使用方法：启动后浏览器打开 <http://localhost:8080/sse-retry.html>，
页面会实时显示每次「连接建立 → 收到 1 条时间 → 连接断开 → 2 秒后重连」的完整过程，
并可统计重连次数、消息条数，支持开始/停止/清空日志。原 `/index.html` 不受影响。

只看单次请求（curl 会收到 1 条后立刻结束）：
```bash
curl -N http://localhost:8080/sse-retry
# retry: 2000
# data: Fri Nov 04 21:40:46 CST 2022
# （空行，连接随即关闭）
```

## 验证 SSE 流
启动后可用 curl 直接观察推送：
```bash
curl -N http://localhost:8080/sse
# 每秒输出形如：
# data: Fri Nov 04 21:40:46 CST 2022
# （空行）
```

## 已验证
- `mvn compile` 编译通过（JDK 21 + Maven 3.9.2，编译级别 17）
- `mvn spring-boot:run` 启动后：`/index.html`、`/sse`（持续推送）、`/sse-retry`（`retry: 2000`）均正常返回
- `scripts/build.sh` 打包产出 `target/service-b.jar`，`scripts/app.sh` 的 start / status / restart / stop 均已实测通过
- `/sse-retry` 重连行为实测：7 秒内自动重连 4 次（间隔约 2s），每次收到 1 条推送
