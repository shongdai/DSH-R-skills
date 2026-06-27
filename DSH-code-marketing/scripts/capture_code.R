#!/usr/bin/env Rscript
# =============================================================================
# capture_code.R — R 代码语法高亮截图
#
# 描述: 将 R 脚本前 N 行渲染为带 tango 语法高亮的 HTML，再用 webshot2 截图
# 用法: source("capture_code.R"); capture_code("output.png", "script.R", n = 50)
# 依赖: webshot2
# 浏览器: Microsoft Edge（自动检测路径）
# =============================================================================

# ---- 自动设置浏览器路径 ----
edge_paths <- c(
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "C:/Program Files/Microsoft/Edge/Application/msedge.exe"
)
for (p in edge_paths) {
  if (file.exists(p)) { Sys.setenv(CHROMOTE_CHROME = p); break }
}

#' 截取 R 代码文件前 N 行为 PNG
#'
#' 逐字符扫描分词 → HTML 转义 → 语法高亮 → webshot2 截图。
#' 避免了正则顺序替换导致的 HTML 标签污染（如 "co"> 泄露）。
#'
#' @param target 输出 PNG 路径
#' @param script R 脚本路径（.R）
#' @param n     截取行数，默认 50
capture_code <- function(target, script, n = 50) {
  if (!requireNamespace("webshot2", quietly = TRUE))
    stop("请安装 webshot2: install.packages('webshot2')")
  if (!file.exists(script)) stop("脚本不存在: ", script)

  raw <- readLines(script, n = n, warn = FALSE)

  # ---- 语法关键字表 ----
  KW <- c(
    "library", "source", "function", "if", "else", "for", "while",
    "return", "TRUE", "FALSE", "NULL", "NA", "Inf", "NaN",
    "require", "stop", "cat", "print", "sprintf", "message",
    "tryCatch", "error", "warning", "paste", "paste0",
    "switch", "lapply", "sapply", "vapply", "do.call",
    "install.packages", "suppressPackageStartupMessages", "suppressMessages",
    "regmatches", "gsub", "regexpr", "gregexpr", "sub", "grep",
    "setNames", "file.path", "dir.create", "list.files",
    "readLines", "writeLines", "file.exists", "file.copy", "file.info",
    "normalizePath", "basename", "dirname", "read.csv", "read.delim",
    "read.table", "read_tsv", "read_csv", "read_excel",
    "mutate", "select", "filter", "arrange", "group_by", "summarise",
    "summarize", "pull", "rename", "separate_rows", "unnest",
    "distinct", "bind_rows", "left_join", "inner_join",
    "ggplot", "aes", "geom_", "scale_", "theme_", "facet_",
    "labs", "ggtitle", "xlab", "ylab", "coord_", "element_",
    "colorRampPalette", "brewer.pal"
  )

  # ---- 逐字符扫描高亮 ----
  highlight <- function(line) {
    out <- character(0)
    i <- 1
    n <- nchar(line)
    while (i <= n) {
      ch <- substr(line, i, i)
      if (ch == "#") {
        # 注释：到行尾
        txt <- substr(line, i, n)
        txt <- gsub("&", "&amp;", txt)
        txt <- gsub("<", "&lt;",  txt)
        txt <- gsub(">", "&gt;",  txt)
        out <- c(out, '<span class="co">', txt, '</span>')
        break
      } else if (ch == '"' || ch == "'") {
        # 字符串：匹配闭合引号
        q <- ch
        j <- i + 1L
        while (j <= n && substr(line, j, j) != q) j <- j + 1L
        txt <- substr(line, i, j)
        txt <- gsub("&", "&amp;", txt)
        txt <- gsub("<", "&lt;",  txt)
        txt <- gsub(">", "&gt;",  txt)
        out <- c(out, '<span class="st">', txt, '</span>')
        i <- j + 1L
      } else {
        # 代码段：收集到下一个注释/引号
        chunk <- ch
        i <- i + 1L
        while (i <= n) {
          nc <- substr(line, i, i)
          if (nc == "#" || nc == '"' || nc == "'") break
          chunk <- paste0(chunk, nc)
          i <- i + 1L
        }
        # HTML 转义
        chunk <- gsub("&", "&amp;", chunk)
        chunk <- gsub("<", "&lt;",  chunk)
        chunk <- gsub(">", "&gt;",  chunk)
        # 高亮：数字
        chunk <- gsub("\\b(\\d+\\.?\\d*)\\b",
                      '<span class="dv">\\1</span>', chunk, perl = TRUE)
        # 高亮：函数调用
        chunk <- gsub("\\b([A-Za-z.][A-Za-z0-9._]*)\\s*\\(",
                      '<span class="fu">\\1</span>(', chunk, perl = TRUE)
        # 高亮：关键字
        for (kw in KW) {
          chunk <- gsub(sprintf("\\b(%s)\\b", kw),
                        sprintf('<span class="kw">%s</span>', kw),
                        chunk, perl = TRUE)
        }
        out <- c(out, chunk)
      }
    }
    paste(out, collapse = "")
  }

  hl_lines <- vapply(raw, highlight, "", USE.NAMES = FALSE)

  # ---- 构建 HTML（tango 亮色主题，与使用说明一致） ----
  html <- paste0(
    '<!DOCTYPE html><html><head><meta charset="utf-8"><style>',
    '*{margin:0;padding:0;box-sizing:border-box}',
    'body{font-family:Consolas,"Courier New",monospace;font-size:13px;',
    'background:#f8f8f8;padding:16px 20px;line-height:1.6;color:#2e3436}',
    'pre{white-space:pre;margin:0}',
    '.kw{color:#204a87;font-weight:bold}',
    '.st{color:#4e9a06}',
    '.co{color:#204a87;font-style:italic}',
    '.fu{color:#000000}',
    '.dv{color:#0000cf}',
    '</style></head><body><pre>',
    paste(hl_lines, collapse = "\n"),
    '</pre></body></html>'
  )

  tmp <- tempfile(fileext = ".html")
  writeLines(html, tmp, useBytes = TRUE)

  # 宽度按最长行自适应
  w <- min(1200, max(840, max(nchar(raw)) * 8.5 + 60))
  h <- 80L + length(raw) * 22L

  webshot2::webshot(tmp, target, vwidth = w, vheight = h, delay = 0.2, zoom = 4)

  # 自动裁剪白边
  tryCatch({
    png_data <- png::readPNG(target, native = FALSE)
    is_content <- png_data[, , 1] < 0.99 | png_data[, , 2] < 0.99 | png_data[, , 3] < 0.99
    rows <- which(rowSums(is_content) > 0)
    cols <- which(colSums(is_content) > 0)
    if (length(rows) > 0 && length(cols) > 0) {
      png_data <- png_data[min(rows):max(rows), min(cols):max(cols), , drop = FALSE]
      png::writePNG(png_data, target)
    }
  }, error = function(e) NULL)

  invisible(target)
}


# ---- CLI 入口 ----
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L) {
    stop("用法: Rscript capture_code.R <output.png> <script.R> [n=50]")
  }
  n <- if (length(args) >= 3L) as.integer(args[3]) else 50L
  capture_code(args[1], args[2], n = n)
  cat("capture_code OK: ", args[1], "\n")
}
