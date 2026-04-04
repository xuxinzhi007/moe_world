---
name: "moe-community-api"
description: "萌社区 API 对接文档。包含后端 API、本地 AI (Ollama) 对接信息。在对接或修改任何 API 相关代码前先调用此技能。"
---

# 萌社区 - API 对接文档

## 后端 API (Go-Zero)

### 基础信息
- **后端项目路径**: `C:\Users\ZhuanZ1\Desktop\moe_social\backend`
- **API 服务端口**: 8888 (REST API)
- **RPC 服务端口**: 8080 (gRPC)
- **默认 API 地址**: `http://localhost:8888/api`

### 后端配置文件
- **路径**: `C:\Users\ZhuanZ1\Desktop\moe_social\backend\config\config.yaml`
- **app_client.public_api_base_url**: 生产环境 API 地址

---

## 后端 API 接口

### 获取客户端配置
- **路径**: `GET /api/public/client-config`
- **功能**: 获取生产环境 API 地址等配置
- **响应**:
  ```json
  {
    "api_base_url": "http://localhost:8888/api"
  }
  ```

### 用户登录
- **路径**: `POST /api/user/login`
- **功能**: 用户登录，支持用户名或邮箱
- **请求体**:
  ```json
  {
    "username": "用户名",
    "email": "邮箱 (可选)",
    "password": "密码"
  }
  ```
- **响应**:
  ```json
  {
    "token": "JWT Token",
    "user": {
      "id": 1,
      "username": "用户名",
      "email": "邮箱",
      "avatar": "头像"
    }
  }
  ```

### 用户注册
- **路径**: `POST /api/user/register`
- **功能**: 用户注册
- **请求体**:
  ```json
  {
    "username": "用户名",
    "email": "邮箱",
    "password": "密码"
  }
  ```
- **响应**:
  ```json
  {
    "id": 1,
    "username": "用户名",
    "email": "邮箱",
    "avatar": "头像"
  }
  ```

---

## 本地 AI (Ollama)

### 基础信息
- **API 地址**: `http://localhost:11434/api/generate`
- **默认模型**: llama2
- **需要启动 Ollama 服务**

### 请求格式
```json
{
  "model": "llama2",
  "prompt": "用户消息",
  "stream": false
}
```

### 响应格式
```json
{
  "response": "AI 回复内容"
}
```

---

## 操作说明

### 启动后端服务
```bash
cd C:\Users\ZhuanZ1\Desktop\moe_social\backend\api
go run .\super.go
```

### 启动 Ollama 服务
```bash
ollama serve
```

### Godot 验证命令
```powershell
& "D:\godot4.4.1\Godot_v4.4.1-stable_mono_win64\Godot_v4.4.1-stable_mono_win64.exe" --headless --check-only .
```

---

## 重要提示
1. **API 服务端口 8888** - 游戏调用这个端口
2. **RPC 端口 8080** - 后端内部使用
3. **Ollama 需要单独启动** - 地址 http://localhost:11434
4. **配置中的邮箱地址无效** - 如果 public_api_base_url 是 xuxinzhi19@gmail.com，会自动使用默认地址
