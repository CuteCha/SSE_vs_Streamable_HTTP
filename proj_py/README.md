# SSE 网页自动刷新演示（补全版）

视频《网页如何实现自动刷新？一分钟秒懂SSE技术》里只展示了 FastAPI 后端的 SSE 代码。
本补全版补上了**前端订阅页面**，让整套演示可以直接跑起来，浏览器打开即可看到页面“自动刷新”（每秒收到服务器推送的时间，无需刷新页面、无需轮询）。

## 文件说明
- `sse_server.py` —— FastAPI 后端：`/stream` 推送时间流（SSE）；`/` 返回前端页面
- `sse_server_sanic.py` —— Sanic 后端：与上面功能完全一致（`/stream` + `/`），用 `ResponseStream` 实现
- `index.html` —— 前端页面：用 `EventSource` 订阅 `/stream` 并实时更新（两个后端共用同一个页面）
- `sse_server.py` 里同时保留了视频中的原始 SSE 代码逻辑

## 运行步骤
环境要求：Python 3.13+（在 conda 环境 `py313lang` 下验证通过）

FastAPI 版：
```bash
pip install fastapi uvicorn
python sse_server.py
```

Sanic 版（默认 8000 端口，可用 `PORT=8001` 覆盖）：
```bash
pip install sanic
python sse_server_sanic.py
```

然后浏览器打开：<http://127.0.0.1:8000>

页面左下角状态会显示「已连接，正在接收推送」，中间的大字时间每秒自动更新，即为 SSE 实现的“网页自动刷新”。

## 原理回顾
1. 后端 `async def event_generator()` 每秒生成一条符合 SSE 规范的消息（`data: 内容\n\n`）。
2. 以流式响应持续推送给浏览器：
   - FastAPI：`StreamingResponse(..., media_type="text/event-stream")`
   - Sanic：`ResponseStream(event_generator, content_type="text/event-stream")`，回调内 `await response.write(...)`
3. 前端 `new EventSource('/stream')` 建立长连接，收到 `onmessage` 事件后更新页面 —— 这就是无需轮询的实时自动刷新。

## 已验证（Sanic 25.12.1 / Python 3.13.5）
- `GET /` 返回 `index.html`（200）
- `GET /stream` 持续每秒推送：`data: 当前时间是 17:22:55`（连接断开时 Sanic 日志记录 `DISCONNECTED`）
