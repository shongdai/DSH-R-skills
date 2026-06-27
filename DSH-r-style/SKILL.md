---
name: "DSH-r-style"
description: "统一 R 代码风格规范：产出标准代码头部、install_dependencies.R 和格式规范，集成 styler 自动格式化。当用户要求统一 R 代码风格、添加代码头部或生成依赖脚本时调用。"
---
# DSH-r-style — R 代码风格统一规范

*基于 `d:\R` 现有 30+ 脚本（P001–P027 系列）提炼的统一 R 代码风格规范*

---

## 何时调用

- 用户希望统一 / 规范化 R 脚本风格
- 用户希望为 R 脚本补齐标准代码头部
- 用户希望生成或更新 `install_dependencies.R`
- 用户希望把现有零散 R 脚本重构为符合既定风格的版本
- 新建 R 脚本时希望一次写对（不返工）

---

## 风格来源

本规范提炼自 `d:\R` 目录中以下脚本族：

- 富集分析：`【P001】富集cnet图`、`【P002】富集圈图`、`【P004】桑基气泡图`、…、`【P027】分类桑基气泡图`
- 火山图：`火山图/EnhancedVolcano火山图`、`火山图/ggVolcano火山图`、`火山图/两组火山图`
- Venn 图：`venn图/6组venn`、`venn图/蛋白venn`

这些脚本的共有约定构成了本 skill 的三大核心要素：

1. **标准代码头部**（shebang + 多行注释块）
2. **标准 install_dependencies.R**（镜像 + 日志 + 4 类包 + 4 个安装函数）
3. **统一代码格式**（章节分隔、命名、缩进、注释、日志）+ **styler 自动格式化**

---

## 要素 1 — 标准代码头部

**所有 R 脚本必须以如下头部开头**（位置：`d:\R\<项目目录>\<script_name>.R`）：

```r
#!/usr/bin/env Rscript
# =============================================================================
# <script_name> - <功能简述>
#
# 描述: <一段话说明脚本功能、适用场景>
# 作者: <作者名>
# 联系方式: <邮箱 / 闲鱼 / 小红书 等>
# 创建日期: <YYYY-MM-DD>
# 修改日期: <YYYY-MM-DD>
#
# 依赖:
#   - R版本: 4.6.0
#   - R路径: C:\Program Files\R\R-4.6.0\bin\Rscript.exe
#   - 主要包: <pkg1>, <pkg2>, ...
#
# 输入文件:
#   - <input1>: <说明>
#   - <input2>: <说明>
#
# 输出文件:
#   - <output1>: <说明>
#   - <output2>: <说明>
#
# 使用方法:
#   - R控制台: source("<script_name>.R")
#   - 命令行:  "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" <script_name>.R
# =============================================================================
```

**头部信息核对清单**：

- [ ] 第一行必须是 `#!/usr/bin/env Rscript`
- [ ] 上下两条 `===` 注释行长度对齐（推荐 80 字符）
- [ ] 必填字段：标题、描述、作者、联系方式、创建/修改日期、依赖、输入/输出文件、使用方法
- [ ] 包名与 `install_dependencies.R` 中 4 个清单完全一致

---

## 要素 2 — install_dependencies.R 标准模板

完整模板见 [templates/install_dependencies.R](file:///d:/R/.agents/skills/DSH-r-style/templates/install_dependencies.R)

**模板骨架**（章节编号统一为 `## N. xxx --`）：

| 编号 | 章节 | 关键内容 |
|------|------|----------|
| 0 | 镜像设置 | `options(repos=...)` + `options(BioC_mirror=...)` |
| 1 | 日志工具 | `log_msg(level, fmt, ...)` |
| 2 | 包清单 | `cran_packages` / `bioc_packages` / `github_packages` / `version_packages` |
| 3 | 缓存已安装 | `ipk <- rownames(installed.packages(...))` + `need()` |
| 4 | 安装函数 | `install_cran` / `install_bioc` / `install_github` / `install_version` |
| 5 | 执行 | 依次调用 + 起止日志横幅 |

**镜像选择（按优先级）**：

```r
# 推荐（科研常用）
options(repos = c(CRAN = "https://mirrors.westlake.edu.cn/CRAN/"))
options(BioC_mirror = "https://mirrors.westlake.edu.cn/bioconductor/")

# 备选
# options(repos = c(CRAN = "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"))
# options(repos = c(CRAN = "https://cloud.r-project.org"))
```

**包清单填写规则**：

```r
# CRAN 包
cran_packages <- c(
  "ggplot2",
  "tidyverse"
)

# Bioconductor 包
bioc_packages <- c(
  "clusterProfiler",
  "enrichplot"
)

# GitHub 包（"用户名/仓库名"）
github_packages <- c(
  # "用户名/仓库名"
)

# 指定版本包（pkg = "版本号"）
version_packages <- c(
  # "package_name" = "1.0.0"
)
```

---

## 要素 3 — 统一代码格式规范 + styler 自动格式化

### 3.1 styler 自动格式化

**styler 是 R 社区标准代码格式化工具**（RStudio `Ctrl+Shift+A` 后端）。

**在风格统一工作流中的位置**：完成头部修复和依赖同步后，运行 styler 自动处理缩进、空格、换行等机械性格式问题，人工只需关注命名、注释、章节结构等语义层面。

| API | 用途 |
|-----|------|
| `styler::style_file("script.R")` | 格式化单个文件 |
| `styler::style_dir("project/")` | 格式化目录下所有 .R/.Rmd |
| `styler::style_pkg(".")` | 格式化整个 R 包 |

**styler 能自动处理**：空格、缩进、换行位置、赋值符 `=` → `<-`（可选）、花括号位置、行尾空白等。

**styler 不能自动处理**（需人工完成）：代码头部补齐、章节分隔符、命名风格转换、注释补全、管道符迁移（`%>%` → `|>`）、install_dependencies.R 同步。

### 3.2 章节结构（每个脚本统一遵循）

主章节用 `# ===...` 分隔（与现有源脚本一致）：

```r
# =============================================================================
# 0. R 包安装和载入
# =============================================================================

# =============================================================================
# 1. 常量配置
# =============================================================================

# =============================================================================
# 2. 数据读取与预处理
# =============================================================================

# =============================================================================
# 3. 绘图
# =============================================================================

# =============================================================================
# 4. 图片输出
# =============================================================================

# =============================================================================
# 5. 输出打印
# =============================================================================
```

子章节用 `## N.N 子标题 ---...---`：

```r
## 2.1 读取富集分析数据 ----------------------------------------------
## 2.2 读取 fold change 数据 -----------------------------------------
```

### 3.3 R 包加载模板

```r
# 安装依赖（install_dependencies.R 必须与脚本同目录）
source("install_dependencies.R")

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
})
```

### 3.4 命名规范

| 类型 | 风格 | 示例 |
|------|------|------|
| 变量 | snake_case（名词） | `enrich_data`, `gene_fc`, `dot_data` |
| 函数 | snake_case（动词） | `process_data`, `plot_enrich_circle` |
| 常量 | UPPER_SNAKE_CASE | `MAX_ITERATIONS`, `DEFAULT_THRESHOLD` |
| 列名映射 | `list(短键 = "列名")` | `cols <- list(id = "geneID")` |
| 文件名 | 下划线 | `cnetplot.R`, `install_dependencies.R` |

### 3.5 缩进 / 行宽 / 换行

由 **styler** 自动处理（`styler::style_file()` 执行后即符合 Tidyverse Style Guide）：

- 缩进：2 空格（永远不用 Tab）
- 行宽：尽量 < 80 字符
- 长函数调用：每个参数一行
- 长管道：每个主要步骤一行，闭合括号单独一行

```r
# 长函数调用
enrichData <- read_tsv("enrich.tsv") |>
  select(!!!cols) |>
  mutate(
    count = as.numeric(count),
    ratio = sapply(ratio, function(x) {
      if (grepl("/", x)) eval(parse(text = x)) else as.numeric(x)
    })
  )

# 多参数换行
ggsave("plot.pdf", p,
  width = 10, height = 8,
  device = cairo_pdf
)
```

### 3.6 注释规范

```r
# 章节标题
# =============================================================================
# 3. 绘图
# =============================================================================

# 行尾注释：# 后接一个空格
img_width <- 10  # 图片输出宽度（英寸）

# 块注释：每行 # + 空格
# 数据预处理：选择列、计算新变量、排序和分组取前 10
df <- raw_data |> select(!!!cols)
```

### 3.7 控制台日志约定

使用 `cat()` 输出关键信息，**标签统一**：

| 标签 | 含义 | 示例 |
|------|------|------|
| `INFO:` | 普通信息 | `cat("INFO: 已读取差异表达数据\n")` |
| `WARN:` | 警告 | `cat("WARN: 批量安装失败，转入逐个重试\n")` |
| `ERROR:` | 错误 | `cat("ERROR: 包安装失败\n")` |
| `SUCCESS:` | 成功 | `cat("SUCCESS: CRAN 批量安装完成\n")` |
| 无标签 | 输出结果 | `cat("图形已保存:\n  - plot.pdf\n")` |

### 3.8 函数定义规范

```r
# 函数：动词命名，snake_case
plot_enrich_circle <- function(data, top_n = 10) {
  # 入参显式校验
  if (!is.data.frame(data)) {
    stop("`data` must be a data.frame")
  }

  # 单一职责
  result <- data |> dplyr::slice_head(n = top_n)

  # 隐式返回
  result
}
```

### 3.9 赋值与管道

- 赋值统一用 `<-`，**不用 `=`**（函数参数除外）
- 管道统一用原生 `|>`，**不用 `%>%`**

> **兼容注意**：`|>` 为 R 4.1+ 原生管道。若用户 R 版本 < 4.1 或脚本中依赖 `%>%` 的 `.` 占位符语义，可保留 `%>%`，不做强制替换。

---

## 标准脚本骨架

完整示例见 [examples/cnetplot_demo.R](file:///d:/R/.agents/skills/DSH-r-style/examples/cnetplot_demo.R)

```r
#!/usr/bin/env Rscript
# =============================================================================
# <script_name> - <功能简述>
#
# 描述: ...
# 作者: 科研木鱼
# 联系方式: 闲鱼/小红书:科研木鱼
# 创建日期: 2026-01-01
# 修改日期: 2026-01-01
#
# 依赖:
#   - R版本: 4.5.2
#   - 主要包: tidyverse, ggplot2
#
# 输入文件: input.tsv
# 输出文件: output.pdf, output.png
#
# 使用方法: source("<script_name>.R")
# =============================================================================

# =============================================================================
# 0. R 包安装和载入
# =============================================================================

source("install_dependencies.R")

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
})

# =============================================================================
# 1. 常量配置
# =============================================================================
plot_width  <- 10
plot_height <- 8

# =============================================================================
# 2. 数据读取与处理
# =============================================================================
data <- read_tsv("input.tsv")

# =============================================================================
# 3. 绘图
# =============================================================================
p <- ggplot(data, aes(x, y)) + geom_point()

# =============================================================================
# 4. 图片输出
# =============================================================================
ggsave("output.pdf", p, width = plot_width, height = plot_height)
ggsave("output.png", p, width = plot_width, height = plot_height, dpi = 300)

# =============================================================================
# 5. 输出打印
# =============================================================================
cat("图形已保存:\n")
cat("  - output.pdf\n")
cat("  - output.png\n")
```

---

## 整理现有脚本的工作流

当用户要求"统一现有 R 代码"时，按以下流程执行：

1. **扫描** `d:\R` 下所有 `.R` 文件（跳过 `install_dependencies.R`）
2. **识别脚本类型**（数据读取 / 绘图 / 火山图 / Venn / 富集 …）
3. **逐项对照**三大要素检查：
   - 是否有 shebang + 完整代码头部？
   - 是否有 `source("install_dependencies.R")` 且脚本同目录有该文件？
   - 章节结构、命名、注释、日志是否统一？
4. **修复头部**：补齐或重写 `#!/usr/bin/env Rscript` + 注释块
5. **同步依赖**：把脚本里 `library()/require()` 出现的所有包，**去重**后归入 `install_dependencies.R` 的 4 个清单（CRAN/Bioc/GitHub/Version）。
6. **运行 styler 自动格式化**：
   ```r
   source("install_dependencies.R")
   styler::style_file("script.R")
   ```
   styler 自动处理：缩进、空格、换行、赋值符花括号位置等机械性问题。
7. **人工语义修正**（styler 无法处理的）：
   - 管道符：`%>%` → `|>`（注意兼容性，见 3.9 节）
   - 命名风格：统一为 snake_case
   - 注释补全：补齐缺失的章节注释和日志
8. **加入日志**：在关键节点（读文件 / 画图 / 存图）加 `cat("INFO: ...")`
9. **验证**：确保 `source("install_dependencies.R")` + `source("<script>.R")` 顺序能跑通

---

## 注意事项

- **不要修改脚本的绘图逻辑**，只动格式与依赖清单
- **不要删除原始注释**，仅在缺失时补齐
- **GitHub 包必须写完整 `用户名/仓库名`**，例如 `"YuLab-SMU/clusterProfiler"`
- **版本包** 用 `version_packages <- c("pkg" = "1.0.0")` 形式
- **路径**：所有读写文件使用相对路径，文件名即用途（如 `enrich.txt`、`diff.txt`）
- **输出图片双格式**：PDF + PNG（PNG 设 `dpi = 300`），文件名同名不同后缀
- **styler 格式化后应人工复核**：styler 是辅助工具，不能完全替代人工对命名、注释、日志的审查

---

## 示例文件

- [templates/install_dependencies.R](file:///d:/R/.agents/skills/DSH-r-style/templates/install_dependencies.R) — 完整 install_dependencies.R 模板
- [examples/cnetplot_demo.R](file:///d:/R/.agents/skills/DSH-r-style/examples/cnetplot_demo.R) — 标准脚本骨架示例