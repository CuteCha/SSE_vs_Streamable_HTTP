package com.example.serviceb.controller;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Date;

import javax.servlet.http.HttpServletResponse;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * SSE（Server-Sent Events，服务端推送事件）示例控制器。
 * 浏览器通过 EventSource 订阅接口，服务端按 SSE 规范（data: 内容\n\n）单向持续推送消息。
 */
@Controller
public class SseEmitterController {

    /**
     * 持续推送：每隔 1 秒向浏览器推送一次当前时间，连接保持不断开。
     * 客户端断开（IOException）时结束推送，避免线程空转。
     */
    @GetMapping(value = "/sse", produces = "text/event-stream;charset=UTF-8")
    @ResponseBody
    public void streamTime(HttpServletResponse httpServletResponse) throws IOException {
        httpServletResponse.setContentType("text/event-stream");
        httpServletResponse.setCharacterEncoding("utf-8");
        // 反向代理通常会对空闲连接做超时，这里显式关闭缓存并提示不缓冲
        httpServletResponse.setHeader("Cache-Control", "no-cache");
        httpServletResponse.setHeader("Connection", "keep-alive");

        PrintWriter pw = httpServletResponse.getWriter();
        while (true) {
            try {
                Thread.sleep(1000L);
                pw.write("data: " + new Date() + "\n\n");
                pw.flush();
                if (pw.checkError()) {
                    // 客户端已断开，写出错时结束循环
                    break;
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }
    }

    /**
     * 带 retry 配置的版本：推送一次后结束，并告知浏览器断开后 2 秒自动重连。
     * retry 后的毫秒数即浏览器自动重连的间隔。
     */
    @GetMapping(value = "/sse-retry", produces = "text/event-stream;charset=UTF-8")
    @ResponseBody
    public void streamTimeWithRetry(HttpServletResponse httpServletResponse) throws IOException {
        httpServletResponse.setContentType("text/event-stream");
        httpServletResponse.setCharacterEncoding("utf-8");
        httpServletResponse.setHeader("Cache-Control", "no-cache");

        String s = "retry: 2000\n";
        s += "data: " + new Date() + "\n\n";
        PrintWriter pw = httpServletResponse.getWriter();
        pw.write(s);
        pw.flush();
    }
}
