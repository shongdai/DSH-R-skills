#!/usr/bin/env Rscript
# =============================================================================
# capture_table.R — 数据表截图
#
# 描述: 读取数据文件前 N 行，渲染为紧凑 HTML 表格，用 webshot2 截图。
#       自动按列数+内容宽度计算视口，确保所有列完整显示无截断。
# 用法: source("capture_table.R"); capture_table("data.tsv", "output.png", nrows = 5)
# 依赖: knitr, webshot2
# =============================================================================

#' 截取数据表为 PNG
#'
#' @param data_path  数据文件路径（.tsv / .csv / .txt / .xlsx）
#' @param target     输出 PNG 路径
#' @param nrows      读取行数，默认 5
capture_table <- function(data_path, target, nrows = 5) {
  if (!requireNamespace("knitr", quietly = TRUE))
    stop("请安装 knitr: install.packages('knitr')")
  if (!requireNamespace("webshot2", quietly = TRUE))
    stop("请安装 webshot2: install.packages('webshot2')")
  if (!file.exists(data_path))
    stop("数据文件不存在: ", data_path)

  ext <- tolower(tools::file_ext(data_path))
  df <- switch(ext,
    tsv  = read.delim(data_path, nrows = nrows, check.names = FALSE,
                      stringsAsFactors = FALSE, comment.char = ""),
    csv  = read.csv(  data_path, nrows = nrows, check.names = FALSE,
                      stringsAsFactors = FALSE, comment.char = ""),
    txt  = read.delim(data_path, nrows = nrows, check.names = FALSE,
                      stringsAsFactors = FALSE, comment.char = ""),
    xlsx = {
      if (requireNamespace("readxl", quietly = TRUE))
        readxl::read_excel(data_path, n_max = nrows)
      else stop("请安装 readxl 以读取 .xlsx")
    },
    stop("不支持的文件类型: ", ext)
  )

  nc <- ncol(df)
  # 估算每列平均字符宽度（表头 + 首行内容）
  col_widths <- pmax(
    nchar(names(df)),
    vapply(df[1, ], function(x) nchar(as.character(x)), numeric(1))
  )
  # 视口宽度 = 列数 × 每列像素宽（11px 字体，~7px per char）+ body padding
  vw <- round(sum(col_widths) * 7.5 + 24)
  # 高度 = 表头行高度 + N行数据
  vh <- nrow(df) * 23 + 32

  tab <- knitr::kable(df, format = "html", row.names = FALSE,
                      table.attr = 'style="width:auto;white-space:nowrap;font-size:11px"')

  html <- paste0(
    '<!DOCTYPE html><html><head><meta charset="utf-8"><style>',
    '*{margin:0;padding:0;box-sizing:border-box}',
    'body{font-family:"Segoe UI",Arial,sans-serif;font-size:11px;',
    'padding:4px 8px;background:#fff;display:inline-block;width:auto}',
    'table{border-collapse:collapse;font-size:11px}',
    'td,th{border:1px solid #d0d7de;padding:3px 7px;text-align:left}',
    'th{background:#f6f8fa;font-weight:600;color:#1f2328}',
    'td{color:#24292f}',
    'tr:nth-child(even){background:#f6f8fa}',
    '</style></head><body>', tab, '</body></html>'
  )

  tmp <- tempfile(fileext = ".html")
  writeLines(html, tmp, useBytes = TRUE)
  webshot2::webshot(tmp, target, vwidth = vw, vheight = vh, delay = 0.3,
                    cliprect = "viewport", zoom = 4)

  # 自动裁剪白边（左右/上下不均匀时也会裁齐）
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
    stop("用法: Rscript capture_table.R <data.tsv> <output.png> [nrows=5]")
  }
  nr <- if (length(args) >= 3L) as.integer(args[3]) else 5L
  capture_table(args[1], args[2], nrows = nr)
  cat("capture_table OK: ", args[2], "\n")
}
