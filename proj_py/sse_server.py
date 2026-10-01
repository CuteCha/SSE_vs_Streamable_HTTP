import asyncio
from datetime import datetime
from pathlib import Path

from fastapi import FastAPI
from fastapi.responses import FileResponse, StreamingResponse

app = FastAPI()

# 持续生成服务器数据的异步函数
async def event_generator():
    while True:
        # 获取当前时间
        current_time = datetime.now().strftime("%H:%M:%S")
        # 符合SSE规范的格式：必须以 "data: 内容\n\n" 结尾
        yield f"data: 当前时间是 {current_time}\n\n"
        # 每隔1秒发送一次
        await asyncio.sleep(1)


@app.get("/stream")
def get_stream():
    # 使用 StreamingResponse 将数据以流的形式持续推送到前端
    return StreamingResponse(event_generator(), media_type="text/event-stream")


@app.get("/")
def index():
    # 返回前端订阅页面，浏览器打开首页即可看到页面"自动刷新"
    return FileResponse(Path(__file__).parent / "index.html", media_type="text/html")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="127.0.0.1", port=8000)
