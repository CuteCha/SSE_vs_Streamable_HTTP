import asyncio
import os
from datetime import datetime
from pathlib import Path

from sanic import Sanic
from sanic.response import ResponseStream, file

app = Sanic("sse-sanic-demo")

BASE_DIR = Path(__file__).parent


# 持续生成服务器数据的异步函数（与 FastAPI 版逻辑一致）
async def event_generator(response):
    try:
        while True:
            # 获取当前时间
            current_time = datetime.now().strftime("%H:%M:%S")
            # 符合SSE规范的格式：必须以 "data: 内容\n\n" 结尾
            await response.write(f"data: 当前时间是 {current_time}\n\n")
            # 每隔1秒发送一次
            await asyncio.sleep(1)
    except (asyncio.CancelledError, ConnectionError, OSError):
        # 客户端断开连接，结束推送
        return


@app.get("/stream")
async def get_stream(request):
    # 使用 ResponseStream 将数据以流的形式持续推送到前端
    return ResponseStream(
        event_generator,
        content_type="text/event-stream",
        headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
    )


@app.get("/")
async def index(request):
    # 返回前端订阅页面，浏览器打开首页即可看到页面"自动刷新"
    return await file(BASE_DIR / "index.html", mime_type="text/html")


if __name__ == "__main__":
    app.run(
        host="127.0.0.1",
        port=int(os.getenv("PORT", "8000")),
        access_log=True,
    )
