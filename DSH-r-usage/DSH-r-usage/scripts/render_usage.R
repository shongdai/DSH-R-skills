#!/usr/bin/env Rscript
# =============================================================================
# render_usage - Rmd 使用说明渲染脚本
#
# 描述: 将指定目录下的 Rmd 使用说明书渲染为 HTML 网页文件。
#       统一应用 DSH-r-usage 规范：默认 Bootstrap 主题 + Pandoc tango 代码高亮 +
#       居中标题/作者/日期 + 统一 h1-h6 颜色 + 表格样式 + 分页表格。
#       支持单个文件渲染和批量渲染。
# 作者: 科研木鱼
# 联系方式: 闲鱼/小红书:科研木鱼
# 创建日期: 2026-06-09
# 修改日期: 2026-06-10
#
# 依赖:
#   - R版本: 4.6.0
#   - R路径: C:\Program Files\R\R-4.6.0\bin\Rscript.exe
#   - 主要包: rmarkdown
#
# 输入文件:
#   - *.Rmd: R Markdown 使用说明书
#
# 输出文件:
#   - *.html: HTML 网页文件（风格: 默认 Bootstrap + 自定义 DSH-r-usage 样式）
#
# 使用方法:
#   - R控制台: source("render_usage.R")
#   - 命令行:  "C:\Program Files\R\R-4.6.0\bin\Rscript.exe" render_usage.R
# =============================================================================

# =============================================================================
# 0. 常量配置
# =============================================================================

# 要渲染的 Rmd 文件名列表（留空则自动扫描当前目录）
rmd_files <- c()

# =============================================================================
# 1. R包安装和载入
# =============================================================================
if (!requireNamespace("rmarkdown", quietly = TRUE)) {
  install.packages("rmarkdown")
}

suppressPackageStartupMessages({
  library(rmarkdown)
})

# =============================================================================
# 2. 渲染配置
# =============================================================================

unify_options <- list(
  theme         = "default",
  highlight     = "tango",
  df_print      = "paged"
)

# =============================================================================
# 3. DSH-r-usage 自定义样式（注入到 </head> 之前）
# =============================================================================

# 与 P004 0.html / P008 / P022 视觉风格一致
dsh_custom_head <- '
<style type="text/css">

body {
  font-family: \'Microsoft YaHei\', \'WenQuanYi Micro Hei\', \'Heiti SC\', \'Times New Roman\', serif !important;
  font-size: 16px;
  line-height: 1.6;
  color: #333;
}

h1, h2, h3, h4, h5, h6 {
  font-family: \'Microsoft YaHei\', \'WenQuanYi Micro Hei\', \'Heiti SC\', \'Times New Roman\', serif !important;
  font-weight: bold;
}

h1.title {
  font-size: 30px !important;
  text-align: center;
  margin-bottom: 30px;
  color: #333;
}

h1 {
  font-size: 26px !important;
  margin-top: 30px;
  margin-bottom: 15px;
  color: #2c3e50;
  border-bottom: 2px solid #eee;
  padding-bottom: 10px;
}

h2 {
  font-size: 22px !important;
  margin-top: 25px;
  margin-bottom: 12px;
  color: #34495e;
  border-bottom: 1px solid #eee;
  padding-bottom: 8px;
}

h3 {
  font-size: 20px !important;
  margin-top: 20px;
  margin-bottom: 10px;
  color: #546e7a;
}

h4 {
  font-size: 18px !important;
  margin-top: 18px;
  margin-bottom: 8px;
}

h5, h6 {
  font-size: 16px !important;
  margin-top: 15px;
  margin-bottom: 8px;
}

pre, code {
  font-family: \'Consolas\', \'Monaco\', \'Courier New\', monospace;
  font-size: 14px;
}

p {
  margin: 12px 0;
  line-height: 1.8;
}

ul {
  margin: 12px 0;
  padding-left: 2em;
}

ul li {
  line-height: 1.8;
  margin: 8px 0;
}

ol {
  margin: 12px 0;
  padding-left: 2em;
}

ol li {
  line-height: 1.8;
  margin: 2px 0;
}

table {
  font-size: 14px;
  border-collapse: collapse;
  width: 100%;
  margin: 20px 0;
  background-color: transparent;
  border-spacing: 0;
}

table th, table td {
  border: 1px solid #ddd;
  padding: 8px;
  text-align: left;
  vertical-align: top;
}

table th {
  background-color: #f5f5f5;
  font-weight: bold;
  color: #333;
  border-bottom: 2px solid #ddd;
}

table tr:nth-child(even) {
  background-color: #f9f9f9;
}

table tr:hover {
  background-color: #f5f5f5;
}

blockquote {
  border-left: 4px solid #3498db;
  padding: 15px 20px;
  margin: 20px 0;
  background-color: #f8f9fa;
  font-style: normal;
}

img {
  max-width: 100%;
  height: auto;
  display: block;
  margin: 20px auto;
}

.author, .date {
  text-align: center;
}

pre {
  background-color: #f8f9fa;
  border: 1px solid #e9ecef;
  border-radius: 4px;
  padding: 15px;
  overflow-x: auto;
}

.alert {
  padding: 15px 20px;
  margin: 20px 0;
  border-radius: 4px;
}

.alert-info {
  background-color: #d1ecf1;
  border: 1px solid #bee5eb;
  color: #0c5460;
}

.alert-warning {
  background-color: #fff3cd;
  border: 1px solid #ffeeba;
  color: #856404;
}

.alert-success {
  background-color: #d4edda;
  border: 1px solid #c3e6cb;
  color: #155724;
}

hr {
  border: none;
  border-top: 1px solid #ddd;
  margin: 30px 0;
}

/* 侧栏 TOC 样式 */
.tocify {
  width: 20%;
  max-height: 90%;
  overflow: auto;
  margin-left: 2%;
  position: fixed;
  left: 0;
  top: 20px;
  border: 1px solid #ccc;
  border-radius: 6px;
  background-color: #fff;
  box-shadow: 0 2px 5px rgba(0,0,0,0.1);
  padding: 10px;
}

.tocify ul, .tocify li {
  list-style: none;
  margin: 0;
  padding: 0;
  border: none;
  line-height: 30px;
}

.tocify-header {
  text-indent: 10px;
}

.tocify-subheader {
  text-indent: 20px;
  display: none;
}

.tocify-subheader li {
  font-size: 12px;
}

.tocify-subheader .tocify-subheader {
  text-indent: 30px;
}

.tocify-subheader .tocify-subheader .tocify-subheader {
  text-indent: 40px;
}

.tocify .tocify-item > a,
.tocify .nav-list .nav-header {
  margin: 0px;
}

.tocify .tocify-item a,
.tocify .list-group-item {
  padding: 5px 10px;
  font-size: 14px;
  color: #333;
  text-decoration: none;
  border-bottom: 1px solid #f0f0f0;
}

.tocify .tocify-item a:hover {
  color: #2980b9;
  background-color: #f8f9fa;
}

.tocify-item.active a,
.tocify .tocify-item.active a,
.tocify .list-group-item.active {
  color: #2980b9 !important;
  font-weight: bold !important;
  background-color: #e8f4fc !important;
  border-left: 3px solid #2980b9;
}

.tocify-item a:hover,
.tocify .tocify-item a:hover {
  background-color: #f0f0f0 !important;
}

/* 代码高亮颜色 - VS Code Light+ 风格（白底高辨识度） */
.sourceCode .kw { color: #0000ff; font-weight: bold; }   /* keyword     - 蓝色 */
.sourceCode .st { color: #a31515; }                       /* string      - 暗红 */
.sourceCode .co { color: #1a6daa; font-style: italic; }   /* comment     - 蓝色 */
.sourceCode .fu { color: #795e26; }                       /* function    - 棕色 */
.sourceCode .cf { color: #0000ff; font-weight: bold; }    /* 控制流      - 蓝色 */
.sourceCode .dv { color: #098658; }                       /* 数值        - 青绿 */
.sourceCode .fl { color: #098658; }                       /* 浮点数      - 青绿 */
.sourceCode .bn { color: #098658; }                       /* 基数        - 青绿 */
.sourceCode .ot { color: #267f99; }                       /* 其他        - 青色 */
.sourceCode .ch { color: #a31515; }                       /* 字符        - 暗红 */
.sourceCode .va { color: #001080; }                       /* 变量        - 深蓝 */

html {
  scroll-behavior: smooth;
}

@media screen and (max-width: 768px) {
  .tocify {
    position: static;
    width: 100%;
    max-height: 300px;
    margin-left: 0;
    margin-bottom: 20px;
  }
  .main-container {
    margin-left: 0;
    padding-right: 0;
  }
}
</style>
'

# =============================================================================
# 4. 辅助函数
# =============================================================================

inject_dsh_styles <- function(html_path, head_content) {
  # 读取生成的 HTML，在 </head> 之前注入自定义样式
  # 同时修复 tocify showAndHide 选项
  size <- file.info(html_path)$size
  if (is.na(size)) return(FALSE)
  
  raw <- readBin(html_path, what = "raw", n = size)
  html_str <- rawToChar(raw)
  
  # 修复 tocify: showAndHide = false → true（恢复 collapsed: false 效果）
  html_str <- gsub(
    "options.showAndHide = false;",
    "options.showAndHide = true;",
    html_str, fixed = TRUE
  )
  
  # 在 </head> 之前插入自定义内容
  head_end <- regexpr("</head>", html_str, fixed = TRUE)[1]
  if (head_end <= 0) return(FALSE)
  
  html_str <- paste0(
    substr(html_str, 1, head_end - 1),
    head_content,
    substr(html_str, head_end, nchar(html_str))
  )
  
  # 写回文件
  con <- file(html_path, open = "wb")
  writeChar(html_str, con, eos = NULL)
  close(con)
  
  return(TRUE)
}

# =============================================================================
# 5. 自动扫描与渲染
# =============================================================================

if (length(rmd_files) == 0) {
  rmd_files <- list.files(
    path = ".",
    pattern = "使用说明\\.Rmd$",
    full.names = FALSE
  )
}

if (length(rmd_files) == 0) {
  stop("未找到任何 *使用说明.Rmd 文件，请确认文件存在或手动指定 rmd_files")
}

cat("INFO: 找到", length(rmd_files), "个 Rmd 文件\n")

for (f in rmd_files) {
  if (!file.exists(f)) {
    cat("WARN: 文件不存在，跳过:", f, "\n")
    next
  }

  html_output <- sub("\\.Rmd$", ".html", f)
  
  cat("INFO: 正在渲染:", f, "\n")
  render(f, output_options = unify_options, quiet = TRUE)
  
  # 后处理：注入 DSH-r-usage 自定义样式到 </head> 之前
  if (file.exists(html_output)) {
    if (inject_dsh_styles(html_output, dsh_custom_head)) {
      cat("INFO: 自定义样式已注入\n")
    } else {
      cat("WARN: 样式注入未完全成功，但 HTML 已生成\n")
    }
    cat("SUCCESS: 渲染完成 ->", html_output, "\n")
  }
}

# =============================================================================
# 6. 输出汇总
# =============================================================================

html_files <- sub("\\.Rmd$", ".html", rmd_files)
cat("\n渲染结果:\n")
for (f in html_files) {
  if (file.exists(f)) {
    cat("  [OK]", f, "\n")
  } else {
    cat("  [FAIL]", f, "\n")
  }
}
