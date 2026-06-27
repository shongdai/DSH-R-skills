---
name: "DSH-r-usage"
description: "为 R 绘图脚本生成标准化使用说明：产出 .Rmd 文档和 .html 网页。当用户要求为 R 脚本生成使用说明、撰写 R 代码文档、制作 Rmd 说明书或渲染 HTML 说明页面时调用。"
---

# DSH-r-usage — R 代码使用说明生成


---

## 何时调用

- 用户希望为 R 脚本生成使用说明文档
- 用户要求生成 `.Rmd` 文档
- 用户要求将 `.Rmd` 渲染为 `.html` 网页
- 用户说"写个说明书"/"生成使用说明"/"制作 Rmd"
- 新建脚本后需要配套说明文档

---

## 产品交付物

每套使用说明包含两个文件，放在脚本同级目录：

| 文件 | 命名规则 | 示例 |
|------|----------|------|
| Rmd 源文件 | `【P编号】脚本名使用说明.Rmd` | `【P004】桑基气泡图使用说明.Rmd` |
| HTML 网页 | `【P编号】脚本名使用说明.html` | `【P004】桑基气泡图使用说明.html` |

---

## Rmd 标准结构（九章节）

完整模板见 [templates/template.Rmd](file:///d:/R/.agents/skills/DSH-r-usage/templates/template.Rmd)

| 章节 | 标题 | 核心内容 |
|------|------|----------|
| 一 | 概述 | 功能简介（用途 + 功能列表）+ 效果预览（结果图 + 图示说明） |
| 二 | 软件安装 | R 版本要求 + R包安装（source + 手动）+ 加载代码 + 包功能说明表 |
| 三 | 快速开始 | 一行命令运行 + 分步调试 + 查看结果表 |
| 四 | 数据准备 | 输入文件格式表 + 示例数据 + 数据导入代码 + 数据检查 |
| 五 | 参数配置 | 按参数组分类解释（输出/标签/颜色/图形等） |
| 六 | 代码详解 | 数据处理 + 绘图原理 + 核心函数 + 绘制流程 |
| 七 | 结果解读 | 输出文件说明 + 图中各元素含义表 + 结果解读指南 |
| 八 | 常见问题 | 运行错误表 + 图形问题表 + 数据问题表 |
| 九 | 参考资源 | `sessionInfo()` 块 + 参考文档链接 + 版权声明 + 页脚 |

---

## YAML 头部固定格式

所有 Rmd 统一使用以下 YAML：

```yaml
---
title: "[脚本功能名]"
author: "科研木鱼"
date: "`r Sys.Date()`"
output:
  html_document:
    toc: true
    toc_depth: 3
    toc_float:
      collapsed: false
      smooth_scroll: true
    highlight: tango
    self_contained: true
    fig_caption: true
    df_print: paged
---
```

**关键参数说明**：

| 参数 | 值 | 原因 |
|------|-----|------|
| `theme` | **不设置**（使用 rmarkdown 默认 Bootstrap 3.3.5） | 与现有 30+ HTML 完全一致；如设置成 flatly/cosmo 等会替换侧边 tocify 浮动目录 |
| `toc_float` | `collapsed: false` | 左侧浮动的章节目录（基于 jQuery UI + tocify 1.9.1） |
| `highlight` | `tango` | Pandoc tango 语法高亮，render_usage.R 渲染时叠加自定义颜色 |
| `self_contained` | `true` | HTML 自包含图片/CSS，方便分发 |

---

## setup chunk 固定格式

```r
```{r setup, include = FALSE}
options(device = function(...) { NULL })
if (!interactive()) {
  pdf(file = NULL)
}

suppressPackageStartupMessages({
  library(包1)
  library(包2)
  # ... 该脚本实际用到的所有包
})
```
```

> **注意**：setup chunk 中的 `library()` 必须与对应 R 脚本的 `suppressPackageStartupMessages({...})` 中的包列表**完全一致**。

---

## 各章节内容规范

### 一、概述

```markdown
# 一、概述

## 1.1 功能简介

[脚本功能描述]，用于[应用场景]。

**主要功能：**

- 功能1：[名称] - [说明]
- 功能2：[名称] - [说明]
- ...

## 1.2 效果预览

<div style="text-align: center;">
![图片名](图片文件名.png)
**[图片标题]**
</div>

**图示说明：**

- **[元素1]**：[说明]
- **[元素2]**：[说明]
```

- 结果图片放在脚本同级目录，Rmd 内用相对路径引用
- 「功能1/2/…」从 R 脚本头部的「描述」和「依赖」提取

### 二、软件安装

本章覆盖 R 语言环境 + R包安装，替代旧的"R包安装"章：

```markdown
# 二、软件安装

## 2.1 R 安装

**R和RStudio的下载链接：**

- 官网下载：https://cran.r-project.org/
- Window的老R版本：https://cran.r-project.org/bin/windows/base/old/
- RStudio 下载：https://posit.co/download/rstudio-desktop/

## 2.2 R包安装

```{r install-packages, eval = FALSE}
# 方式1：运行安装脚本（推荐）
source("install_dependencies.R")

# 方式2：手动安装
install.packages(c("包1", "包2"))
# Bioconductor
BiocManager::install(c("包3"))
```

## 2.3 R包加载

**包功能说明：**

| 包名 | 用途 | 必需 |
|------|------|------|
| 包1 | 用途说明 | 是 |
```

- 包列表来自 `install_dependencies.R` + R 脚本 `library()` 调用
- 「用途」列填写该包在脚本中的具体作用

### 三、快速开始

让用户最快看到结果，合并了旧的"脚本运行"章：

```markdown
# 三、快速开始

## 3.1 准备工作

1. 下载 R 脚本文件
2. 将数据文件放置在脚本同目录
3. 打开 RStudio，若路径不对，则输入：`setwd("脚本所在文件夹的完整路径")`，例如：`setwd("D:/R/【P004】桑基气泡图/")`

## 3.2 一键运行

```{r quickstart, eval = FALSE}
# 方式1：R控制台
source("脚本名.R")

# 方式2：终端命令行
Rscript 脚本名.R
```

## 3.3 分步运行

按脚本章节（0→5）逐段执行，观察中间变量：

1. 常量配置
2. R包安装和载入
3. 数据读取与预处理
4. 图形绘制
5. 图片输出

## 3.4 运行结果

| 文件名 | 格式 | 说明 |
|--------|------|------|
| 输出1.pdf | PDF | 适合论文出版 |
| 输出1.png | PNG | 适合网页/PPT展示 |
```

### 四、数据准备

保持与旧"三、数据准备"一致：

```markdown
# 四、数据准备

## 4.1 输入文件格式

**必需文件：**

| 文件名 | 格式 | 编码 | 说明 |
|--------|------|------|------|
| 文件1.tsv | TSV | UTF-8 | 说明 |

**数据列要求：**

| 列名 | 类型 | 必需 | 说明 |
|------|------|------|------|
| 列1 | 数值 | 是 | 说明 |

**示例数据：**
```

- 文件信息来自 R 脚本头部的「输入文件」字段
- 列名来自脚本中的 `cols` 列表或 `read_tsv/read.table` 调用
- 示例数据从实际数据文件中取前 3-5 行

### 五、参数配置

保持与旧"四、参数配置"一致：

按脚本中的参数分组（图片输出、标签、颜色、图形等），每组一个 `##` 小节：

```markdown
# 五、参数配置

## 5.1 图片输出设置

```{r output-params, eval = FALSE}
plot_width  <- 10  # 图片宽度（英寸）
plot_height <- 8   # 图片高度（英寸）
```

## 5.2 颜色参数

...
```

- 代码块必须加 `eval = FALSE`（仅展示，不执行）
- 保留脚本原有行尾注释

### 六、代码详解

> **核心要求：整个章节所有代码块的每一行右侧都必须添加 `# 中文注释`，解释该行代码的作用。这是 DSH-r-usage 的强制规范，目的让用户无需查阅 R 文档即可逐行理解代码含义。**

合并了旧的"五、数据处理"和"六、图形绘制"，一整章讲完代码逻辑。

**必须为每行代码添加右侧中文注释**（`# 注释内容`），解释该行代码的作用，让用户无需查阅 R 文档即可理解每一行。

```markdown
# 六、代码详解

## 6.1 数据读取与预处理

```{r data-processing, eval = FALSE}
# ========== 数据读取 ==========
data <- read_tsv("输入文件.tsv")          # 读取 TSV 格式数据文件
colnames(data) <- make.names(colnames(data))   # 规范化列名，替换特殊字符
data <- data %>% drop_na()                # 删除包含缺失值的行

# ========== 数据预处理 ==========
data$Sample <- factor(data$Sample,        # 将 Sample 列转为因子
  levels = c("Control", "Treat"))         # 设置因子水平顺序
```

## 6.2 绘图原理

[图类型]由以下元素组成：

| 元素 | 含义 | 映射方式 |
|------|------|----------|
| 元素1 | 含义 | 映射方式说明 |

**绘图原理：** [一句话解释]

## 6.3 核心绘制代码

```{r core-drawing, eval = FALSE}
# ========== 主图绘制 ==========
p <- ggplot(data, aes(                    # 初始化 ggplot 对象
  x = Group,                              # X 轴：分组变量
  y = Value,                              # Y 轴：数值变量
  fill = Category)) +                     # 填充色：类别变量
  geom_bar(stat = "identity",             # 绘制条形图，使用原始值
    position = position_dodge(0.8),       # 分组并列排列
    width = 0.7) +                        # 柱子宽度
  scale_fill_manual(                      # 自定义填充颜色
    values = my_colors) +                 # 使用预设颜色向量
  theme_minimal() +                       # 应用简洁主题
  theme(                                  # 自定义主题细节
    axis.text.x = element_text(           # 修改 X 轴文字
      angle = 45, hjust = 1))             # 旋转 45 度方便阅读
```

**主要参数：**

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 参数1 | [说明] | 默认值 |
```

- 代码块一律 `eval = FALSE`
- **每行代码右侧必须有 `# 中文注释`**，解释该行的作用
- 长函数调用可分行写，每行参数单独加注释
- 在关键代码块前加一行分隔注释（如 `# ========== 数据读取 ==========`）
- 注释使用简洁直白的中文，让用户一眼看懂

### 七、结果解读

保持与旧"八、结果解读"一致：

```markdown
# 七、结果解读

## 7.1 输出文件说明

**输出文件：**

- `输出1.pdf`：PDF格式图片，适合论文出版
- `输出1.png`：PNG格式图片，适合演示和网页

**图中各元素含义：**

| 元素 | 含义 | 解读方法 |
|------|------|----------|
| 元素1 | 含义 | 如何解读 |

## 7.2 结果解读指南

**正常结果特征：**

- 特征1
```

- 元素含义表要结合具体图形元素逐个说明

### 八、常见问题

使用三个表格分别覆盖：
- 运行错误（包加载失败 / 找不到文件 / 版本不兼容...）
- 图形问题（显示不全 / 颜色异常 / 标签重叠...）
- 数据问题（格式错误 / 缺失值 / 列名不匹配...）

每个问题含三列：`问题 | 原因 | 解决方法`。

### 九、参考资源

```markdown
# 九、参考资源

## 9.1 环境信息

```{r session-info, echo = TRUE, eval = TRUE}
suppressPackageStartupMessages({
  library(包1)
  library(包2)
})
sessionInfo()
```

## 9.2 参考文档

- [包名1官方文档](URL1)
- [包名2官方文档](URL2)

## 9.3 版权声明

本文档及相关代码由**科研木鱼**创作，仅供学习和研究使用。

---
<div style="text-align: center; color: #666; margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd;">
<small>
作者：科研木鱼<br>
生成时间：`r Sys.Date()`<br>
如有问题请联系：闲鱼/小红书：科研木鱼
</small>
</div>
```

- `sessionInfo()` 块用 `echo = TRUE, eval = TRUE`（实际执行）
- 参考文档链接按脚本用到的包逐一列出

---

## 从 HTML 渲染 Rmd

**本机 R 安装路径：**

```
C:\Program Files\R\R-4.6.0\bin\Rscript.exe
```

**渲染命令**（在 R 控制台或 RStudio 中执行）：

```r
rmarkdown::render("【P001】富集cnet图使用说明.Rmd")
```

或在脚本所在目录直接运行：

```r
# 设置工作目录
setwd("d:/R/【P001】富集cnet图/")
rmarkdown::render("【P001】富集cnet图使用说明.Rmd")
```

**命令行批量渲染：**

```powershell
cd "d:\R\【P004】桑基气泡图"
& "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" render_usage.R
```

RStudio 用户也可点击 Rmd 编辑器上方的 **Knit** 按钮。

---

## 生成使用说明的工作流

当用户要求"生成使用说明"时，按以下流程执行：

1. **读取 R 脚本**：获取头部信息（标题、描述、依赖、输入/输出文件）、`library()` 调用、参数配置常量、核心绘图函数
2. **读取数据文件**：获取列名、示例数据（前 3-5 行）
3. **查结果图片**：确认 `.png` 或 `.pdf` 输出文件名（用于效果预览）
4. **按模板生成 Rmd**：
   - 章节一→十按序填充
   - `title` 取脚本头部「标题」字段
   - 所有 R 代码块 `eval = FALSE`（仅 `sessionInfo` 块除外）
   - 参数配置按脚本常量注释分组
   - 常见问题结合包依赖和脚本特性
5. **命名 Rmd**：`【P编号】脚本名使用说明.Rmd`
6. **渲染 HTML**：`rmarkdown::render("xxx.Rmd")`
7. **放置文件**：Rmd 和 HTML 均放入 R 脚本同级目录

---

## 命名规则

| 场景 | Rmd 文件名 | HTML 文件名 |
|------|-----------|-------------|
| 有 P 编号 | `【P001】富集cnet图使用说明.Rmd` | `【P001】富集cnet图使用说明.html` |
| 无编号 | `富集棒棒图使用说明.Rmd` | `富集棒棒图使用说明.html` |
| 简名 | `GO_barplot使用说明.Rmd` | `GO_barplot使用说明.html` |

---

## 示例文件

- [templates/template.Rmd](file:///d:/R/.agents/skills/DSH-r-usage/templates/template.Rmd) — 完整 Rmd 模板（九章节 + 占位符）
- [scripts/render_usage.R](file:///d:/R/.agents/skills/DSH-r-usage/scripts/render_usage.R) — 批量渲染 Rmd→HTML 脚本