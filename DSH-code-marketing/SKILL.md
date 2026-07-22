---
name: "DSH-code-marketing"
description: "为 R 绘图脚本整理发布/营销物料：自动生成图片（代码截图+输入数据截图+使用说明长图+结果图复制）和文案（笔记.txt+商品设置.txt）。当用户要求整理代码的发布物料、生成营销目录、生成小红书图片、生成闲鱼商品设置或为 R 脚本打包发布素材时调用。"
---

# DSH-code-marketing — R 代码营销物料整理

*基于 `d:\R` 现有 27 套 `【Pxxx】*/发布/` 子文件夹提炼的统一营销物料结构*

---

## 何时调用

- 用户要求为 R 脚本整理发布/营销物料
- 用户要求生成 `发布/` 子文件夹
- 用户要求生成 `笔记.txt` / `商品设置.txt`
- 用户要求截图代码、输入数据、使用说明 HTML
- 用户要求打包 R 脚本的营销资源

---

## 目录名称

**路径**：`d:\R\【Pxxx】<项目名>\发布\`

> 旧版使用 `小红书/` 作为目录名，已统一改名为 `发布/`。
> 原因：`发布/` 同时覆盖小红书图文、闲鱼商品、知乎/公众号等多种发布渠道。

---

## 产品交付物

每个 P 项目目录下生成一个 `发布/` 子文件夹，包含 8 类文件：

| 文件 | 命名 | 来源 | 自动化 |
|------|------|------|--------|
| 代码截图 | `code.png` | 截 R 脚本前 60 行 | ✅ |
| 代码预览图 | `code_preview.png` | 截 R 脚本前 30 行（带主题色） | ✅ |
| 输入数据截图 1 | `input_data.png` | 截主输入文件前 5 行 | ✅ |
| 输入数据截图 2..N | `input_data_2.png` ... | 截附加输入文件前 5 行 | ✅ |
| 输出表格截图 | `output_data.png` / `output_data_2.png` ... | 截输出 CSV/TSV 文件前 10 行 | ✅ |
| 数据预览 | `数据.png` / `数据1.png` | 截数据文件前 5 行（无表头） | ✅ |
| 结果图（全部） | `*.png` | 复制代码当前文件夹所有 PNG | ✅ |
| 使用说明长图 | `使用说明.png` | 截 Rmd/HTML 渲染结果 | ✅ |
| 小红书笔记 | `笔记.txt` | 模板复制 → **技能核查后手填** | ⚠️ 半自动 |
| 商品设置 | `商品设置.txt` | 模板复制 → **技能核查后手填** | ⚠️ 半自动 |

> ⚠️ **重要**：笔记.txt 与商品设置.txt 的内容**不要用代码自动填充**。
> 收集脚本（collect.R）只负责从模板复制占位骨架，**AI 技能**需手动核查项目内容，
> 然后**编辑**这两个文件填入具体信息。

---

## 命名规则

| 文件 | 命名模式 | 示例 |
|------|---------|------|
| 代码截图 | `code.png` | `code.png` |
| 代码预览（小） | `code_preview.png` | `code_preview.png` |
| 单个输入文件 | `input_data.png` | `input_data.png` |
| 多个输入文件 | `input_data.png` / `input_data_2.png` | `input_data.png`, `input_data_2.png` |
| 单个输出表格 | `output_data.png` | `output_data.png` |
| 多个输出表格 | `output_data.png` / `output_data_2.png` | `output_data.png`, `output_data_2.png` |
| 单个数据预览 | `数据.png` | `数据.png` |
| 多个数据预览 | `数据1.png` / `数据2.png` | `数据1.png`, `数据2.png` |
| 结果图（程序输出） | 沿用原文件名 | `sankey_bubble_right.png` |
| 使用说明长图 | `使用说明.png` | `使用说明.png` |

**P002、P004、P011 等例外**：同时存在 `代码.png` 和 `code_preview.png`，保留两个；其他项目只用 `code_preview.png`。

---

## 截图工具与代码

三种截图各由独立脚本实现，均在 [scripts/](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/) 下：

| 脚本 | 函数 | 用途 | 依赖 |
|------|------|------|------|
| [capture_code.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/capture_code.R) | `capture_code(target, script, n=50)` | R 代码语法高亮截图（逐字符扫描+HTML转义，tango 亮色主题） | webshot2 |
| [capture_table.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/capture_table.R) | `capture_table(data_path, target, nrows=10)` + `capture_table_batch(csv_dir, ...)` | 通用表格截图：支持 csv/tsv/txt/xlsx，自动格式化数值列，compact/display 双样式，批量截图 | knitr, webshot2, readr |
| [capture_html.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/capture_html.R) | `capture_html(html_path, target, stop_at_image=TRUE)` | 使用说明 HTML 长截图（xml2 解析 + Headless Edge 截图，截到第一张图即停） | xml2 |

> [screenshot.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/screenshot.R) 与 [collect.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/collect.R) 为旧版聚合文件，保留向后兼容。

**前置条件**：
- R 包：webshot2 (>= 0.1.0), knitr, xml2
- 浏览器：Microsoft Edge 或 Google Chrome 任一安装
- 代码高亮原理：**逐字符扫描**分离 代码段 / 字符串 / 注释，各自 HTML 转义后再上色，避免正则交叉污染

---

## templates 目录

[scripts/collect.R](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/scripts/collect.R) 是一键收集脚本，模板存放：

| 模板 | 路径 | 用途 |
|------|------|------|
| 笔记.txt | [templates/note.md](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/templates/note.md) | 小红书笔记骨架（标题+正文+标签） |
| 商品设置.txt | [templates/product.md](file:///c:/Users/Administrator/.trae-cn/builtin_skills/DSH-code-marketing/templates/product.md) | 闲鱼商品设置（5 段标准） |

> 模板仅提供**占位骨架**（如 `<脚本功能一句话>`），不是最终文案。
> 技能必须先**核查**项目（R 脚本标题、描述、输入输出、关键函数），再**编辑**填入实际内容。

---

## 工作流

### 步骤 1 — 扫描与确认

```powershell
# 扫描项目
$project = "d:\R\【P004】桑基气泡图"
Get-ChildItem $project\*.R, $project\*.Rmd, $project\*.tsv
```

确认需要纳入物料的文件清单。

### 步骤 2 — 复制模板（不填充内容）

```r
# R 控制台：复制模板占位骨架到 发布/
source("d:/R/.agents/skills/DSH-code-marketing/scripts/collect.R")
collect("d:/R/【P004】桑基气泡图")
```

或者命令行：
```powershell
Rscript "c:\Users\Administrator\.trae-cn\builtin_skills\DSH-code-marketing\scripts\collect.R" "d:\R\【P004】桑基气泡图"
```

此步骤只完成：
1. 创建 `发布/` 目录
2. 复制所有结果 PNG
3. 复制 `笔记.txt` / `商品设置.txt` 模板（**内容为占位符**）
4. 生成 `code_preview.png` / `input_data.png` / `使用说明.png` 等截图

**不要**用代码提取 R 脚本信息并自动填充文案。

### 步骤 3 — 技能核查（手动）

技能需打开以下文件并通读：
- R 脚本头（标题、描述、依赖、输入输出）
- Rmd 文档（功能说明、核心特性、适用场景）
- 输入数据样本（前 5 行）

**核查清单**：
- [ ] 脚本功能一句话是否准确
- [ ] 副标题卖点是否抓人
- [ ] 三大核心功能是否对应 R 脚本实际能力
- [ ] 适用场景是否真实存在
- [ ] 商品标题的 `Pxxx` 编号是否正确
- [ ] 图表类型描述是否与图片一致
- [ ] 标签是否与目标平台相关

### 步骤 4 — 编辑笔记.txt（手填）

打开 `d:\R\【Pxxx】<项目名>\发布\笔记.txt`，按 [templates/note.md](file:///d:/R/.agents/skills/DSH-code-marketing/templates/note.md) 占位逐项替换：

```
📊 分类桑基气泡图｜BP/CC/MF 三类富集结果一目了然 🔬
...
```

### 步骤 5 — 编辑商品设置.txt（手填）

打开 `d:\R\【Pxxx】<项目名>\发布\商品设置.txt`，按 [templates/product.md](file:///d:/R/.agents/skills/DSH-code-marketing/templates/product.md) 占位逐项替换：

```
【P027】R语言绘图代码|分类桑基气泡图
...
```

### 步骤 6 — 截图存在性校验

```powershell
$required = @("笔记.txt", "商品设置.txt", "code_preview.png", "使用说明.png")
$missing = $required | Where-Object { -not (Test-Path "d:\R\【Pxxx】\发布\$_") }
if ($missing) { Write-Warning "缺失: $missing" } else { Write-Host "OK" }
```

---

## 常见场景

| 场景 | 处理 |
|------|------|
| 单输入文件 | `input_data.png` 一个文件 |
| 多输入文件 | 主输入 `input_data.png` + 副输入 `input_data_2.png` |
| 多输出图 | 全部复制（沿用原文件名） |
| 项目无 Rmd | 跳过 `使用说明.png` |
| 项目无数据文件 | 跳过 `input_data.png` |
| 笔记.txt 已存在 | **保留原内容，不覆盖**（避免丢失人工编辑） |
| 商品设置.txt 已存在 | **保留原内容，不覆盖**（避免丢失人工编辑） |

---

## 检查清单（执行 collect.R 后必须做）

```powershell
$required = @("笔记.txt", "商品设置.txt", "code_preview.png", "使用说明.png")
$optional = @("input_data.png", "code.png")
$missing_required = $required | Where-Object { -not (Test-Path "d:\R\【Pxxx】\发布\$_") }
$missing_optional = $optional | Where-Object { -not (Test-Path "d:\R\【Pxxx】\发布\$_") }
if ($missing_required) { Write-Warning "必备缺失: $missing_required" } else { Write-Host "必备 OK" }
if ($missing_optional) { Write-Warning "可选缺失: $missing_optional" }
```

---

## 与 DSH-r-usage 协同

| Skill | 职责 |
|-------|------|
| [DSH-r-usage](../DSH-r-usage/SKILL.md) | 生成 `使用说明.html` |
| **DSH-code-marketing** | 把 HTML 长截图 + 复制到 `发布/` |
| [DSH-r-style](../DSH-r-style/SKILL.md) | 生成 `code.png` 截的 R 脚本 |

**典型流水线**：
```
R 脚本 (DSH-r-style 规范化)
  ↓
Rmd (DSH-r-usage 生成)
  ↓
HTML (DSH-r-usage 渲染)
  ↓
发布/ (DSH-code-marketing 打包 + 技能核查填文案)
  ↓
小红书发布 / 闲鱼上架
```
