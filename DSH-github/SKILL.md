---
name: "DSH-github"
description: "GitHub 仓库管理：创建仓库、推送代码、上传技能。已内置 shongdai 账号凭证。当用户要求推送代码到 GitHub、创建仓库、或管理 GitHub 资源时调用。"
---

# DSH-github — GitHub 仓库管理

---

## 凭据（内置于技能）

| 配置项 | 值 |
|--------|-----|
| 用户名 | `shongdai` |
| Token | `<YOUR_GITHUB_TOKEN>` |
| Git 邮箱 | `shongdai@users.noreply.github.com` |
| Git 用户名 | `shongdai` |

---

## 何时调用

- 用户要求推送代码到 GitHub
- 用户要求创建 GitHub 仓库
- 用户要求上传文件/技能到 GitHub
- 用户说"推到 GitHub"/"创建仓库"/"上传到 github"
- 从 DSH-code-marketing 等技能发布物料到 GitHub

---

## 安全规则（必须遵守）

1. **Token 仅用于 git remote URL 和 API Header**，禁止在日志、echo、Write-Host 中打印完整 token
2. **远程 URL 格式**：`https://shongdai:TOKEN@github.com/shongdai/REPO.git`
3. **API 认证头**：`Authorization = "token TOKEN"`
4. **不要修改全局 git config**，每次操作临时设置 `git config user.name` / `user.email`

---

## 操作 1 — 创建 GitHub 仓库

使用 PowerShell + GitHub API。**必须用 Invoke-RestMethod，不能用 curl**（PowerShell 的 curl 是 Invoke-WebRequest 别名，参数不兼容）。

```powershell
$headers = @{
  Authorization = "token <YOUR_GITHUB_TOKEN>"
  Accept = "application/vnd.github+json"
}
$body = @{
  name        = "REPO_NAME"
  description = "REPO_DESCRIPTION"
  private     = $false
  auto_init   = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
  -Method Post -Headers $headers -Body $body
```

返回结果中 `html_url` 即仓库地址，`clone_url` 用于 git remote。

---

## 操作 2 — 推送代码到仓库

### 2.1 已有仓库（首次推送）

```powershell
Set-Location "项目目录"
git init
git config user.email "shongdai@users.noreply.github.com"
git config user.name "shongdai"
git add -A
git commit -m "COMMIT_MESSAGE"
git remote add origin "https://shongdai:<YOUR_GITHUB_TOKEN>@github.com/shongdai/REPO.git"
git push -u origin main
```

### 2.2 已有仓库（后续推送）

```powershell
Set-Location "项目目录"
git add -A
git commit -m "COMMIT_MESSAGE"
git push
```

### 2.3 分支名处理

- GitHub 新仓库默认分支为 `main`
- Windows 本地 `git init` 默认创建 `master`
- 推送前执行：`git branch -m master main`

---

## 操作 3 — 上传技能到 GitHub

将 `d:\R\.agents\skills\` 下的技能打包上传：

```powershell
# 1. 准备临时目录
mkdir -Force "d:\R\_git_upload\REPO_NAME" | Out-Null
Copy-Item "d:\R\.agents\skills\SKILL_NAME" "d:\R\_git_upload\REPO_NAME\SKILL_NAME" -Recurse -Force

# 2. 添加 README.md（如需要）
# ...

# 3. 推送到 GitHub（使用 操作 2 流程）
```

完成后清理：`Remove-Item "d:\R\_git_upload" -Recurse -Force`

---

## 操作 4 — 检查仓库是否存在

```powershell
$headers = @{
  Authorization = "token <YOUR_GITHUB_TOKEN>"
}
try {
  Invoke-RestMethod -Uri "https://api.github.com/repos/shongdai/REPO_NAME" `
    -Headers $headers -Method Get
  Write-Host "仓库已存在"
} catch {
  Write-Host "仓库不存在"
}
```

---

## 工作流模板

### 模板 A：首次发布新仓库

```
1. 操作 4 检查仓库是否存在
2. 操作 1 创建仓库（如不存在）
3. 准备本地文件 + README.md
4. 操作 2.1 初始化并推送
5. 清理临时目录
```

### 模板 B：更新已有仓库

```
1. 确认仓库已存在
2. 更新/添加文件
3. 操作 2.2 提交并推送
```

### 模板 C：批量上传多个技能

```
1. 操作 1 创建仓库
2. 循环操作 3 复制各技能目录
3. 添加 README
4. 操作 2.1 一次性推送
5. 清理
```

---

## 与 DSH 系列技能协作

| 场景 | 调用 DSH-github |
|------|-----------------|
| DSH-code-marketing 生成发布物料 | 推送到 `DSH-R-skills` 仓库 |
| DSH-r-style 更新模板 | 推送更新到远程 |
| 新建 R 项目 | 创建独立仓库并推送代码 |

---

## 注意事项

- PowerShell 中 `git push` 的认证信息在 remote URL 中，**命令日志可能暴露 token**，操作前确认 `blocking: false` 或 `requires_approval: true`
- 优先使用 HTTPS + Token，避免 SSH 配置问题
- Windows 环境下 LF/CRLF 警告可忽略（`git config core.autocrlf true` 已默认）
- 推送前始终确认分支名（`main` vs `master`）
