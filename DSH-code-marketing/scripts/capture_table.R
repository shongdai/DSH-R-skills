#!/usr/bin/env Rscript
# =============================================================================
# capture_table.R — 通用表格截图
#
# 描述: 读取 CSV/TSV/TXT/XLSX 文件，自动格式化数值列（p值科学记数、
#       NES/FC四舍五入），渲染为展示级 HTML 表格后用 webshot2 截图。
#
# 用法:
#   source("capture_table.R")
#   capture_table("data.tsv", "output.png")
#   capture_table("data.tsv", "output.png", nrows = 5, title = "输入数据预览")
#   capture_table_batch("结果目录/", out_dir = "发布/", pattern = "\\.csv$")
#
# 依赖: knitr, webshot2, readr
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

#' 通用表格截图
#'
#' @param data_path  数据文件路径（.csv / .tsv / .txt / .xlsx）
#' @param target     输出 PNG 路径
#' @param nrows      截取行数，默认 10
#' @param title      表格标题（NULL 则用文件名）
#' @param cols       保留列名（NULL 则全部保留）
#' @param format_num 是否自动格式化数值列，默认 TRUE
#' @param trunc_cols 需截断的长文本列："auto" 自动检测 / NULL 不截断 / c("geneID", ...)，默认 "auto"
#' @param vwidth     视口宽度，NULL 则自动计算，默认 NULL
#' @param encoding   文件编码，默认 UTF-8
capture_table <- function(data_path, target, nrows = 10, title = NULL,
                          cols = NULL, format_num = TRUE,
                          trunc_cols = "auto",
                          vwidth = NULL, encoding = "UTF-8") {
  if (!requireNamespace("knitr", quietly = TRUE))
    stop("请安装 knitr: install.packages('knitr')")
  if (!requireNamespace("webshot2", quietly = TRUE))
    stop("请安装 webshot2: install.packages('webshot2')")
  if (!file.exists(data_path))
    stop("文件不存在: ", data_path)

  # ---- 读取 ----
  ext <- tolower(tools::file_ext(data_path))
  df <- switch(ext,
    csv = {
      if (!requireNamespace("readr", quietly = TRUE))
        stop("请安装 readr: install.packages('readr')")
      readr::read_csv(data_path, show_col_types = FALSE,
                      locale = readr::locale(encoding = encoding))
    },
    tsv = {
      if (!requireNamespace("readr", quietly = TRUE))
        stop("请安装 readr: install.packages('readr')")
      readr::read_tsv(data_path, show_col_types = FALSE,
                      locale = readr::locale(encoding = encoding))
    },
    txt = {
      if (!requireNamespace("readr", quietly = TRUE))
        stop("请安装 readr: install.packages('readr')")
      readr::read_tsv(data_path, show_col_types = FALSE,
                      locale = readr::locale(encoding = encoding))
    },
    xlsx = {
      if (!requireNamespace("readxl", quietly = TRUE))
        stop("请安装 readxl: install.packages('readxl')")
      readxl::read_excel(data_path, n_max = nrows)
    },
    stop("不支持的文件类型: ", ext)
  )

  # ---- 选取列 ----
  if (!is.null(cols)) {
    keep <- intersect(cols, names(df))
    if (length(keep) == 0) stop("指定的列名均不存在于文件中")
    df <- df[keep]
  }

  # ---- 截取行 ----
  df <- head(df, nrows)

  # ---- 自动格式化数值列（按数据类型自动识别，不依赖列名） ----
  if (format_num) {
    for (col in names(df)) {
      x <- df[[col]]
      if (!is.numeric(x) || all(is.na(x))) next

      x_clean <- x[!is.na(x)]
      if (length(x_clean) == 0) next

      # 类型 1：整数列（所有非NA值都是整数）→ 保持整数
      if (all(x_clean == floor(x_clean))) {
        df[[col]] <- as.integer(round(x))
        next
      }

      # 类型 2：小数值列（round 到 2 位会丢失信息）→ 科学记数法
      if (any(round(x_clean, 2) == 0 & x_clean != 0)) {
        df[[col]] <- format(x, digits = 3, scientific = TRUE)
        next
      }

      # 类型 3：普通小数列 → 四舍五入 2 位
      df[[col]] <- round(x, 2)
    }
  }

  # ---- 计算列宽（取所有行中最长值） ----
  MAX_COL_CHARS <- 40  # 超过此长度的列自动截断
  col_widths <- nchar(names(df))  # 先取列名宽度
  for (i in seq_len(ncol(df))) {
    col_widths[i] <- max(col_widths[i],
                         max(nchar(as.character(df[[i]])), na.rm = TRUE))
  }

  # ---- 自动截断超长列 ----
  wide_cols <- names(df)[col_widths > MAX_COL_CHARS]
  if (!is.null(trunc_cols)) {
    if (identical(trunc_cols, "auto")) {
      trunc_cols <- wide_cols
    } else {
      trunc_cols <- intersect(trunc_cols, wide_cols)
    }
    for (col in intersect(trunc_cols, names(df))) {
      x <- as.character(df[[col]])
      # 尝试按 / 或 , 或 ; 拆分 → 截断 3 项
      if (any(grepl("[/;,]", x))) {
        sep <- if (any(grepl("/", x))) "/"
               else if (any(grepl(";", x))) ";"
               else ","
        df[[col]] <- vapply(strsplit(x, sep, fixed = TRUE), function(parts) {
          n <- length(parts)
          if (n <= 3) return(paste(parts, collapse = sep))
          paste0(paste(head(parts, 3), collapse = sep), sep, "\u2026")
        }, character(1))
      } else {
        df[[col]] <- ifelse(nchar(x) > MAX_COL_CHARS,
          paste0(substr(x, 1, MAX_COL_CHARS), "\u2026"), x)
      }
    }
    # 截断后重新计算列宽
    for (i in seq_len(ncol(df))) {
      col_widths[i] <- max(nchar(names(df)[i]),
                           max(nchar(as.character(df[[i]])), na.rm = TRUE))
    }
  }

  # ---- 标题 ----
  if (is.null(title)) {
    title <- paste0(basename(data_path), " (Top ", nrows, ")")
  }

  # ---- 计算视口 ----
  if (is.null(vwidth)) {
    vwidth <- max(1100, round(sum(col_widths) * 9 + 40))
  }

  # ---- 渲染 HTML ----
  tab <- knitr::kable(df, format = "html", row.names = FALSE,
                      table.attr = 'class="result-table"')
  html <- paste0(
    '<!DOCTYPE html><html><head><meta charset="utf-8"><style>',
    'body{font-family:"Microsoft YaHei","Segoe UI",Arial,sans-serif;',
    'margin:20px;background:#fff}',
    'h2{color:#333;font-size:16px;margin-bottom:12px}',
    '.result-table{border-collapse:collapse;font-size:13px}',
    '.result-table th{background:#4472C4;color:#fff;padding:6px 10px;',
    'text-align:left;font-weight:600;white-space:nowrap}',
    '.result-table td{padding:5px 10px;border-bottom:1px solid #ddd;',
    'white-space:nowrap}',
    '.result-table tr:nth-child(even){background:#f2f2f2}',
    '.result-table tr:hover{background:#e8f0fe}',
    '</style></head><body>',
    '<h2>', title, '</h2>',
    tab,
    '</body></html>'
  )

  tmp <- tempfile(fileext = ".html")
  writeLines(html, tmp, useBytes = TRUE)

  # ---- 截图 ----
  webshot2::webshot(tmp, target, vwidth = vwidth, delay = 0.5, zoom = 2)

  # ---- 自动裁剪白边 ----
  tryCatch({
    png_data <- png::readPNG(target, native = FALSE)
    is_content <- png_data[, , 1] < 0.99 |
                  png_data[, , 2] < 0.99 |
                  png_data[, , 3] < 0.99
    rows <- which(rowSums(is_content) > 0)
    cols <- which(colSums(is_content) > 0)
    if (length(rows) > 0 && length(cols) > 0) {
      png_data <- png_data[min(rows):max(rows), min(cols):max(cols), , drop = FALSE]
      png::writePNG(png_data, target)
    }
  }, error = function(e) NULL)

  invisible(target)
}


#' 批量表格截图
#'
#' @param csv_dir      CSV 文件所在目录
#' @param pattern      文件名匹配模式（正则），默认 "\\.csv$"
#' @param out_dir      输出目录（默认同 csv_dir）
#' @param prefix       输出文件名前缀，默认 "output_"
#' @param suffix       输出文件名后缀，默认 ".png"
#' @param ...          传递给 capture_table() 的其他参数
capture_table_batch <- function(csv_dir, pattern = "\\.csv$", out_dir = csv_dir,
                                prefix = "output_", suffix = ".png", ...) {
  files <- list.files(csv_dir, pattern = pattern, full.names = TRUE,
                      ignore.case = TRUE)
  if (length(files) == 0) {
    cat("未找到匹配的文件: ", csv_dir, " / ", pattern, "\n")
    return(invisible(character(0)))
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  results <- character(0)

  for (f in files) {
    name <- tools::file_path_sans_ext(basename(f))
    target <- file.path(out_dir, paste0(prefix, name, suffix))
    tryCatch({
      capture_table(f, target, ...)
      cat(sprintf("  [OK] %s -> %s\n", name, target))
      results <- c(results, target)
    }, error = function(e) {
      cat(sprintf("  [FAIL] %s: %s\n", name, e$message))
    })
  }

  cat(sprintf("Done: %d/%d succeeded\n", length(results), length(files)))
  invisible(results)
}


# ---- CLI 入口 ----
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L) {
    stop("用法:\n",
         "  单文件: Rscript capture_table.R <data.tsv> <output.png> [nrows=10]\n",
         "  批量:   Rscript capture_table.R --batch <csv_dir> <out_dir> [pattern]")
  }

  if (args[1] == "--batch") {
    csv_dir <- args[2]
    out_dir <- if (length(args) >= 3L) args[3] else csv_dir
    pat     <- if (length(args) >= 4L) args[4] else "\\.csv$"
    capture_table_batch(csv_dir, pattern = pat, out_dir = out_dir)
  } else {
    nr <- if (length(args) >= 3L) as.integer(args[3]) else 10L
    capture_table(args[1], args[2], nrows = nr)
    cat("capture_table OK: ", args[2], "\n")
  }
}
