# SSE 网页自动刷新演示（补全版）

视频《网页如何实现自动刷新？一分钟秒懂SSE技术》里只展示了 FastAPI 后端的 SSE 代码。
本补全版补上了**前端订阅页面**，让整套演示可以直接跑起来，浏览器打开即可看到页面“自动刷新”（每秒收到服务器推送的时间，无需刷新页面、无需轮询）。

## 文件说明
- `sse_server.py` —— FastAPI 后端：`/stream` 推送时间流（SSE）；`/` 返回前端页面
- `index.html` —— 前端页面：用 `EventSource` 订阅 `/stream` 并实时更新
- `sse_server.py` 里同时保留了视频中的原始 SSE 代码逻辑

## 运行步骤
```bash
pip install fastapi uvicorn
python sse_server.py
```

然后浏览器打开：<http://127.0.0.1:8000>

页面左下角状态会显示「已连接，正在接收推送」，中间的大字时间每秒自动更新，即为 SSE 实现的“网页自动刷新”。

## 原理回顾
1. 后端 `async def event_generator()` 每秒生成一条符合 SSE 规范的消息（`data: 内容\n\n`）。
2. `StreamingResponse(..., media_type="text/event-stream")` 以流式方式持续推送给浏览器。
3. 前端 `new EventSource('/stream')` 建立长连接，收到 `onmessage` 事件后更新页面 —— 这就是无需轮询的实时自动刷新。
