#!/usr/bin/env bash
# service-b jar 包启停脚本
# 用法：./scripts/app.sh start | stop | restart | status
#
# 可选环境变量：
#   PORT       服务端口，默认 8080
#   JAVA_OPTS  JVM 参数，默认 "-Xms128m -Xmx256m"
set -uo pipefail

APP_NAME="service-b"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JAR_FILE="${BASE_DIR}/target/${APP_NAME}.jar"
LOG_DIR="${BASE_DIR}/logs"
LOG_FILE="${LOG_DIR}/app.log"
PID_FILE="${LOG_DIR}/app.pid"
PORT="${PORT:-8080}"
JAVA_OPTS="${JAVA_OPTS:--Xms128m -Xmx256m}"

mkdir -p "${LOG_DIR}"

current_pid() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid="$(cat "${PID_FILE}")"
        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            echo "${pid}"
            return 0
        fi
    fi
    return 1
}

do_start() {
    local pid
    if pid="$(current_pid)"; then
        echo "${APP_NAME} 已在运行，PID=${pid}"
        return 0
    fi
    if [[ ! -f "${JAR_FILE}" ]]; then
        echo "未找到 ${JAR_FILE} ，请先执行 ./scripts/build.sh 打包"
        return 1
    fi
    echo "启动 ${APP_NAME} （端口 ${PORT}）..."
    nohup java ${JAVA_OPTS} -jar "${JAR_FILE}" --server.port="${PORT}" >> "${LOG_FILE}" 2>&1 &
    pid=$!
    echo "${pid}" > "${PID_FILE}"
    echo "${APP_NAME} 已启动，PID=${pid} ，日志：${LOG_FILE}"
}

do_stop() {
    local pid
    if ! pid="$(current_pid)"; then
        echo "${APP_NAME} 未在运行"
        rm -f "${PID_FILE}"
        return 0
    fi
    echo "停止 ${APP_NAME} ，PID=${pid} ..."
    kill "${pid}" 2>/dev/null
    for _ in $(seq 1 20); do
        if ! kill -0 "${pid}" 2>/dev/null; then
            rm -f "${PID_FILE}"
            echo "${APP_NAME} 已停止"
            return 0
        fi
        sleep 0.5
    done
    echo "优雅停止超时，强制 kill -9"
    kill -9 "${pid}" 2>/dev/null
    rm -f "${PID_FILE}"
    echo "${APP_NAME} 已强制停止"
}

do_status() {
    local pid
    if pid="$(current_pid)"; then
        echo "${APP_NAME} 运行中，PID=${pid} ，端口 ${PORT}"
    else
        echo "${APP_NAME} 未运行"
    fi
}

case "${1:-}" in
    start)   do_start ;;
    stop)    do_stop ;;
    restart) do_stop; do_start ;;
    status)  do_status ;;
    *)
        echo "用法：$0 start | stop | restart | status"
        exit 1
        ;;
esac
