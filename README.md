# ThinkTank AI

> 8 个 AI Agent 像专家团队一样协作，输入一个问题，自动完成检索、评判、补搜、撰写全链路，输出带精确引用的深度研究报告。

<p align="center">
  <img src="https://img.shields.io/badge/Python-3.10+-blue?logo=python" alt="Python">
  <img src="https://img.shields.io/badge/FastAPI-0.115+-009688?logo=fastapi" alt="FastAPI">
  <img src="https://img.shields.io/badge/Vue-3-42b883?logo=vue.js" alt="Vue">
  <img src="https://img.shields.io/badge/LangGraph-1.x-ff6b6b" alt="LangGraph">
  <img src="https://img.shields.io/badge/Milvus-2.5-00e6a0?logo=milvus" alt="Milvus">
  <img src="https://img.shields.io/badge/PostgreSQL-16-336791?logo=postgresql" alt="PostgreSQL">
  <img src="https://img.shields.io/badge/LLM-通义千问_DashScope-ff6a00" alt="Qwen">
</p>

---

## 核心亮点

传统 RAG 项目只有「检索 → 生成」两步，ThinkTank AI 在此基础上构建了完整的**证据闭环**：

```
提问 → 意图路由 → 问题拆解 → 双源并行检索（Web + 本地知识库）
         ↓
    证据裁判（去重 / 评分 / 冲突检测）
         ↓
    分析结论 → 证据不足？→ 自动补搜迭代
         ↓
    撰写报告（含精确引用链接 + 幻觉检测）
```

**与普通 RAG 的差异**：不是搜出来直接喂给 LLM 完事，而是**先评判证据质量**，不够就**自动补搜**，写完后还要**校验引用是否真实存在**。

---

## 架构总览

```
┌──────────────────────────────────────────────────────┐
│                    用户提问                            │
└──────────────────────┬───────────────────────────────┘
                       ↓
              ┌────────────────┐
              │ Intent Router  │  意图识别：闲聊 / 深度调研
              └───────┬────────┘
          ┌───────────┴───────────┐
          ↓                       ↓
  ┌──────────────┐        ┌──────────────┐
  │ Direct Answer│        │   Planner    │  问题拆解 + 检索策略制定
  │  (快速回复)   │        └──────┬───────┘
  └──────────────┘        ┌──────┴──────┐
                          ↓              ↓
                   ┌───────────┐  ┌───────────┐
                   │ Web Scout │  │Local Scout│  双源并行检索
                   │(Bocha搜索)│  │(Milvus向量)│
                   └─────┬─────┘  └─────┬─────┘
                         └──────┬───────┘
                                ↓
                    ┌───────────────────┐
                    │ Evidence Judge    │  去重 / 可信度评分 / 冲突检测
                    └────────┬──────────┘
                             ↓
                    ┌───────────────────┐
                    │    Analyst        │  证据分析 + 判断是否充分
                    └────────┬──────────┘
                    ┌────────┴──────────┐
                    ↓                   ↓
            证据充分？              证据不足
                    ↓                   ↓
          ┌─────────────┐    ┌────────────────┐
          │   Writer    │    │  Reflect       │  制定补搜策略
          │ 撰写报告    │    │ (回到双源检索)  │
          │ 引用校验    │    └────────────────┘
          └─────────────┘
                    ↓
           深度研究报告（含精确引用）
```

### 8 个 Agent 职责

| Agent | 职责 |
|-------|------|
| **Intent Router** | 判断问题是闲聊还是深度调研，路由到对应路径 |
| **Direct Responder** | 处理简单对话，快速回复 |
| **Planner** | 拆解复杂问题为子课题，制定检索策略 |
| **Web Scout** | 调用 Bocha Search API 联网搜索 |
| **Local Scout** | 从 Milvus 本地知识库中向量检索 |
| **Evidence Judge** | 对搜索结果去重、评分、冲突检测 |
| **Analyst** | 分析证据质量，判断是否需要补搜 |
| **Writer** | 撰写报告并校验引用真实性（幻觉检测） |

---

## 技术栈

### 后端
| 组件 | 技术 | 说明 |
|------|------|------|
| Web 框架 | FastAPI + Uvicorn | SSE 流式响应，热重载开发 |
| Agent 编排 | LangGraph 1.x + LangChain | 有状态多 Agent 工作流 |
| LLM | 通义千问 Qwen-Plus | DashScope / 百炼 Workspace |
| Embedding | DashScope text-embedding-v1 | 向量化维度 1536 |
| 向量数据库 | Milvus 2.5 | 本地知识库 + 跨会话记忆 |
| 关系数据库 | PostgreSQL 16 | 三层记忆（短期/长期/语义） |
| Web 搜索 | Bocha Search API | Agent 联网检索工具 |
| 文档解析 | PyPDF / python-docx / markdown | 本地知识库文档导入 |

### 前端
| 组件 | 技术 |
|------|------|
| 框架 | Vue 3 + TypeScript |
| 构建工具 | Vite 7 |
| UI 框架 | Element Plus |
| 状态管理 | Pinia |
| 通信协议 | SSE (Server-Sent Events) |

---

## 快速开始

### 前置要求
- Docker & Docker Compose
- Python 3.10+
- Node.js 22+

### 1. 启动依赖服务

```bash
docker compose up -d
```

自动拉起 PostgreSQL 16 + Milvus 2.5（含 etcd + MinIO）。

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填写以下必填项：

```env
# 百炼 DashScope（通义千问）
DASHSCOPE_API_KEY=sk-your-api-key
DASHSCOPE_HTTP_BASE_URL=https://dashscope.aliyuncs.com/api/v1   # 标准 Key
# DASHSCOPE_HTTP_BASE_URL=https://ws-xxx.cn-beijing.maas.aliyuncs.com/api/v1  # Workspace Key

# Web 搜索
BOCHA_API_KEY=sk-your-bocha-key

# PostgreSQL（使用 docker-compose 的默认值即可）
POSTGRES_DSN=postgresql://root:root123@127.0.0.1:5432/mydb

# Milvus
MILVUS_URI=http://127.0.0.1:19530
```

### 3. 一键启动

**Windows：**
```powershell
.\start.ps1
```

**手动启动：**

后端：
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate   # Windows
pip install -r requirements.txt
python run.py
```

前端：
```bash
cd front/agent_front
npm install
npm run dev
```

### 4. 访问

| 服务 | 地址 |
|------|------|
| 前端 | http://localhost:5173 |
| 后端 API | http://localhost:8000 |
| API 文档 | http://localhost:8000/api/v1/docs |

---

## 项目结构

```
deep_research/
├── app/
│   ├── app_main.py                 # FastAPI 应用入口
│   ├── backend/
│   │   ├── config/settings.py      # 后端配置
│   │   ├── router.py               # API 路由注册
│   │   └── service/
│   │       └── workflow_service.py # 工作流服务层（SSE 流式）
│   └── mult_agents/
│       ├── main.py                 # Agent 构建 & 运行入口
│       ├── graph.py                # LangGraph 状态图定义
│       ├── nodes.py                # 8 个 Agent 节点实现
│       ├── state.py                # 研究状态 Schema
│       ├── tools.py                # Agent 工具集（搜索/检索/计算）
│       ├── prompts.py              # 各 Agent 系统提示词
│       ├── config.py               # Multi-Agent 配置
│       ├── utils.py                # 公共工具函数
│       ├── memory/                 # 三层记忆系统
│       │   ├── short_term.py       # 短期记忆（会话上下文）
│       │   ├── long_term.py        # 长期记忆（跨会话知识）
│       │   └── manager.py          # 记忆管理器
│       └── rag/                    # RAG 核心模块
│           ├── core.py             # 检索器 & 重排序
│           └── ingest.py           # 文档导入 & 向量化
├── front/agent_front/              # Vue 3 前端
├── docker-compose.yml              # 依赖服务编排
├── start.ps1                       # Windows 一键启动脚本
├── .env.example                    # 环境变量模板
└── requirements.txt                # Python 依赖
```

---

## 工作流程

### 完整研究链路示例

**用户提问**：*「2025 年 AI Agent 领域有哪些重要进展？对比 OpenAI、Anthropic 和 Google 的策略差异」*

1. **Intent Router** → 识别为深度调研
2. **Planner** → 拆解为：
   - 2025 AI Agent 里程碑事件
   - OpenAI Agent 战略
   - Anthropic Agent 战略
   - Google Agent 战略
   - 三方策略对比分析
3. **Web Scout + Local Scout** → 并行搜索网络 + 本地知识库
4. **Evidence Judge** → 去重、评分、标记可信度
5. **Analyst** → 分析证据覆盖度，发现 Google 策略信息不足
6. **Reflect** → 触发第二轮补搜（关键词调整）
7. **Web Scout → Evidence Judge** → 补搜结果加入证据池
8. **Analyst** → 证据充分，进入写作阶段
9. **Writer** → 生成结构报告，每段附引用链接，自动检测移除幻觉引用

### SSE 流式输出

前端通过 SSE 实时接收每个 Agent 的中间输出，用户可以看到完整的思考过程而非干等最终结果：

```
event: intent
data: {"intent":"research","reasoning":"这是一个需要多维度对比的深度调研问题"}

event: plan
data: {"sub_topics":["2025里程碑","OpenAI策略","Anthropic策略","Google策略","对比分析"]}

event: web_search
data: {"query":"2025 AI agent breakthroughs","results_count":12}

...
```

---

## 配置说明

| 环境变量 | 必填 | 说明 |
|----------|------|------|
| `DASHSCOPE_API_KEY` | ✅ | 通义千问 API Key（标准 `sk-` 或 Workspace `sk-ws-`） |
| `DASHSCOPE_HTTP_BASE_URL` | ❌ | Workspace Key 需设置为专属域名 |
| `BOCHA_API_KEY` | ✅ | 博查 Web 搜索 API Key |
| `POSTGRES_DSN` | ✅ | PostgreSQL 连接串 |
| `MILVUS_URI` | ✅ | Milvus 连接地址 |
| `MODEL` | ❌ | 对话模型，默认 `qwen-plus` |
| `EMBEDDING_MODEL` | ❌ | 嵌入模型，默认 `text-embedding-v1` |
| `MAX_ITERATIONS` | ❌ | 最大研究迭代次数，默认 2 |
| `REDIS_URL` | ❌ | Redis 缓存（可选） |

---

