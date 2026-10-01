#!/usr/bin/env bash
# service-b 打包脚本：清理 -> 编译 -> 打成可执行 jar
# 用法：./scripts/build.sh
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$BASE_DIR"

echo "==> 开始打包：$BASE_DIR"
mvn -B clean package -DskipTests

JAR_FILE="$BASE_DIR/target/service-b.jar"
echo "==> 打包完成：$JAR_FILE"
ls -lh "$JAR_FILE"
