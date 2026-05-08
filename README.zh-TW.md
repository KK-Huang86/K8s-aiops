# kagent-aiops-infra-iac

以 Terraform 在 Linode LKE 上一鍵佈建的 Kubernetes 可觀測性與自動化事件應變平台。

當告警觸發時，系統會自動透過 kagent AI agent（Gemini）調查叢集狀態，並將分析結果發送到 Discord，無需人工介入即可完成第一線分診。

---

## 架構

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LKE Cluster（3x g6-standard-2，ap-northeast）                          │
│                                                                         │
│  ┌──────────── 監控層 ──────────────────┐  ┌──── 長期指標儲存 ──────────┐ │
│  │  Alloy（daemonset）                  │  │  Thanos Query             │ │
│  │    → Prometheus   → Alertmanager    │  │  Thanos Store Gateway     │ │
│  │    → Loki                           │  │  Thanos Compactor         │ │
│  │  Grafana（儀表板 + 告警規則）         │  │    ↕ Linode Object Storage│ │
│  └──────────────────────────────────────┘  └───────────────────────────┘ │
│                                                                         │
│  ┌──────────── 告警路由 ────────────────┐  ┌──── AI 自動調查 ───────────┐ │
│  │  Alertmanager → Keep                │  │  kagent controller        │ │
│  │  Keep workflows：                   │  │  alert-investigator Agent │ │
│  │    warning  → Discord               │  │    ↔ kagent-tool-server   │ │
│  │    critical → Discord               │  │       （K8s MCP 工具）     │ │
│  │           + → kagent trigger        │  │    ↔ discord-mcp          │ │
│  │  Robusta → Discord（K8s 事件）       │  │       （send_discord_msg） │ │
│  └──────────────────────────────────────┘  └───────────────────────────┘ │
│                                                                         │
│  NGINX Ingress（LoadBalancer）→ Keep UI / Keep API                      │
└─────────────────────────────────────────────────────────────────────────┘
                                     │
                              Discord 頻道
                  （warning 告警 / critical 告警 / AI 分析報告）
```

## 告警流程

1. Grafana 告警規則觸發（CPU 或記憶體超過閾值）
2. Alertmanager 透過 webhook 將告警送至 Keep
3. Keep workflow 依嚴重程度分流：
   - **warning** — 發送通知到 Discord
   - **critical** — 發送通知到 Discord，同時呼叫 `discord-mcp` trigger endpoint
4. `discord-mcp` 接收觸發後呼叫 kagent A2A API
5. `alert-investigator` agent 開始調查：
   - 呼叫 `k8s_get_resources`、`k8s_describe_resource`、`k8s_get_events` 檢查叢集狀態
   - 呼叫 `send_discord_message` 輸出結構化的根因分析
6. Discord 收到 AI 生成的調查報告

## 元件說明

| 元件 | 功能 | Namespace |
|---|---|---|
| Prometheus | 抓取叢集指標；透過 Alertmanager 將告警路由至 Keep | `monitoring` |
| Grafana | 儀表板與告警規則（CPU/Memory 80%/90% 閾值） | `monitoring` |
| Alloy | 指標與日誌收集器（daemonset） | `monitoring` |
| Loki | 日誌聚合後端 | `monitoring` |
| Thanos | 長期指標儲存，搭配 Linode Object Storage（S3） | `monitoring` |
| Keep | 告警聚合、去重與 workflow 引擎 | `keep` |
| Robusta | 監聽 Kubernetes 事件並推送至 Discord | `robusta` |
| NGINX Ingress | LoadBalancer ingress，對外開放 Keep UI 與 API | `ingress-nginx` |
| kagent | Kubernetes-native AI agent 框架 | `kagent` |
| alert-investigator | Declarative AI agent：接收告警、查詢 K8s、發送分析至 Discord | `kagent` |
| discord-mcp | 自製 Python MCP server，串接 Keep webhook 觸發與 kagent A2A 及 Discord | `kagent` |

## 告警規則

| 規則 | Warning 閾值 | Critical 閾值 |
|---|---|---|
| Node CPU 使用率 | > 80%，持續 30 秒 | > 90%，持續 30 秒 |
| Node 記憶體使用率 | > 80%，持續 30 秒 | > 90%，持續 30 秒 |

## 前置需求

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Task](https://taskfile.dev/installation/)
- Linode 帳號與 API token
- Google Gemini API key（免費方案即可）
- Discord webhook URL

## 部署方式

```bash
# 1. 複製範本並填入密鑰
cp terraform.tfvars.example terraform.tfvars

# 2. 初始化 providers
terraform init

# 3. 佈建全部資源
terraform apply
```

執行 `terraform apply` 後會一次完成：建立 LKE 叢集、安裝所有 Helm charts、部署 kagent agents 與 MCP server、設定所有告警 workflows。

## 常用指令

```bash
task apply          # terraform apply
task destroy        # terraform destroy

task nodes          # kubectl get nodes
task pods           # kubectl get pods -A

task grafana-ip     # 顯示 Grafana LoadBalancer IP
task keep-url       # 顯示 Keep UI 網址
task keep-status    # kubectl get pods -n keep
task keep-logs      # 追蹤 keep-backend 日誌

task traffic-start  # 啟動 cpu-stress job 觸發告警
task traffic-stop   # 刪除 cpu-stress job
task traffic-logs   # 追蹤 cpu-stress pod 日誌
task traffic-status # 查看 pod 狀態與節點資源使用量
```

## 變數說明

| 變數 | 說明 |
|---|---|
| `linode_token` | Linode API token |
| `grafana_admin_password` | Grafana 管理員密碼 |
| `gemini_api_key` | Google Gemini API key（供 kagent ModelConfig 使用） |
| `keep_secret_key` | Keep 平台 JWT secret |
| `discord_webhook_url` | Discord incoming webhook URL |
| `robusta_signing_key` | Robusta 平台 signing key |

## 注意事項

- `terraform.tfvars` 與所有 `terraform.tfstate*` 檔案已加入 `.gitignore`，請勿提交，state 檔案包含明文密鑰。
- discord-mcp server 監聽兩個 port：`:8085`（MCP/Streamable-HTTP，供 kagent 工具呼叫）與 `:8086`（HTTP trigger endpoint，由 Keep workflow 呼叫）。
- Thanos 保留策略：raw 指標 30 天、5 分鐘降採樣 90 天、1 小時降採樣 1 年。
