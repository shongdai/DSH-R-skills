#!/usr/bin/env Rscript
# =============================================================================
# collect.R - 一键整理 R 脚本的营销物料
#
# 描述: 自动扫描指定项目目录，生成/补齐 发布/ 子文件夹：
#       - 复制代码当前文件夹所有 PNG 到 发布/
#       - 从 R 脚本提取信息，自动生成 笔记.txt / 商品设置.txt
#       - 校验使用说明.png 等可视化物料
#
# 作者: 科研木鱼
# 联系方式: 闲鱼/小红书:科研木鱼
# 创建日期: 2026-06-10
# 修改日期: 2026-06-10
#
# 使用方法:
#   Rscript collect.R "d:/R/【P027】分类桑基气泡图"
# =============================================================================

args <- commandArgs(trailingOnly = TRUE)
project_dir <- if (length(args) >= 1) args[1] else {
  stop("用法: Rscript collect.R <项目目录>\n例如: Rscript collect.R \"d:/R/【P027】分类桑基气泡图\"")
}

marketing_dir <- file.path(project_dir, "发布")
dir.create(marketing_dir, showWarnings = FALSE, recursive = TRUE)

cat("========================================\n")
cat("DSH-code-marketing 营销物料整理\n")
cat("========================================\n")
cat(sprintf("项目目录: %s\n", project_dir))
cat(sprintf("营销目录: %s\n\n", marketing_dir))

# =============================================================================
# 1. 扫描项目文件
# =============================================================================

r_scripts  <- list.files(project_dir, "\\.R$",  full.names = TRUE)
r_markdown <- list.files(project_dir, "\\.Rmd$", full.names = TRUE)
data_files <- list.files(project_dir, "\\.(tsv|csv|txt|xlsx?)$", full.names = TRUE)
html_files <- list.files(project_dir, "\\.html$", full.names = TRUE)
png_files  <- list.files(project_dir, "\\.png$",  full.names = TRUE)

cat(sprintf("[1] 扫描结果:\n"))
cat(sprintf("    R 脚本: %d 个 (%s)\n", length(r_scripts), paste(basename(r_scripts), collapse = ", ")))
cat(sprintf("    Rmd:    %d 个\n", length(r_markdown)))
cat(sprintf("    数据:   %d 个 (%s)\n", length(data_files), paste(basename(data_files), collapse = ", ")))
cat(sprintf("    HTML:   %d 个\n", length(html_files)))
cat(sprintf("    PNG:    %d 个\n\n", length(png_files)))


# =============================================================================
# 2. 从 R 脚本头部提取元信息
# =============================================================================

cat("[2] 提取 R 脚本元信息 ...\n")
meta <- list(
  title      = "",
  desc       = "",
  author     = "科研木鱼",
  contact    = "闲鱼/小红书:科研木鱼",
  packages   = character(0),
  inputs     = character(0),
  outputs    = character(0),
  p_code     = ""  # 形如 P027
)

# 项目编号
meta$p_code <- regmatches(basename(project_dir), regexpr("P\\d+", basename(project_dir)))

if (length(r_scripts) >= 1) {
  # 优先取主脚本（跳过 install_dependencies.R）
  main_scripts <- r_scripts[!grepl("install_dependencies", basename(r_scripts), ignore.case = TRUE)]
  script <- if (length(main_scripts) >= 1) main_scripts[1] else r_scripts[1]
  cat(sprintf("    主脚本: %s\n", basename(script)))
  txt <- readLines(script, warn = FALSE)
  head_block <- txt[1:min(50, length(txt))]
  head_text <- paste(head_block, collapse = "\n")

  # 标题（第 3 行注释后）
  title_line <- head_block[grepl("^- ", head_block)]
  if (length(title_line) > 0) {
    meta$title <- sub("^-\\s*", "", title_line[1])
  } else {
    # 取 "sankey_bubble_right - xxx" 形式
    m <- regmatches(head_text, regexpr("(?<=- )[^\\n#]+", head_text, perl = TRUE))
    if (length(m) > 0) meta$title <- trimws(m[1])
  }

  # 描述
  desc_match <- regmatches(head_text, regexpr("描述:\\s*[^\\n]+(?:\\n\\s+[^\\n#]+)*", head_text))
  if (length(desc_match) > 0) {
    desc_clean <- gsub("\\s+", " ", desc_match)
    desc_clean <- sub("^描述:\\s*", "", desc_clean)
    meta$desc <- desc_clean
  }

  # 包
  pkg_match <- regmatches(head_text, regexpr("主要包:[^\\n]+", head_text))
  if (length(pkg_match) > 0) {
    meta$packages <- trimws(strsplit(sub("主要包:\\s*", "", pkg_match), ",\\s*")[[1]])
  }
  # 兜底：从 suppressPackageStartupMessages({ library(...) }) 中提取
  if (length(meta$packages) == 0) {
    lib_match <- regmatches(head_text, regexpr("suppressPackageStartupMessages\\(\\{[^}]*\\}", head_text))
    if (length(lib_match) > 0) {
      pkgs <- regmatches(lib_match, gregexpr("library\\(\\s*([A-Za-z][A-Za-z0-9.]*)", lib_match))
      if (length(pkgs) > 0 && length(pkgs[[1]]) > 0) {
        meta$packages <- gsub("library\\(\\s*", "", pkgs[[1]])
      }
    }
  }

  # 输入/输出文件
  for (l in head_block) {
    if (grepl("^#\\s*-\\s+\\S+\\.(tsv|csv|txt|xlsx?):", l)) {
      meta$inputs <- c(meta$inputs, sub("^#\\s*-\\s+", "", l))
    }
    if (grepl("^#\\s*-\\s+\\S+\\.(pdf|png|html):", l)) {
      meta$outputs <- c(meta$outputs, sub("^#\\s*-\\s+", "", l))
    }
  }
}

cat(sprintf("    标题: %s\n", meta$title))
cat(sprintf("    描述: %s\n", substr(meta$desc, 1, 60)))
cat(sprintf("    编号: %s\n", meta$p_code))
cat(sprintf("    包:   %s\n", paste(meta$packages, collapse = ", ")))
cat("\n")


# =============================================================================
# 3. 复制结果 PNG 到 发布/
# =============================================================================

cat("[3] 复制结果 PNG 到 发布/ ...\n")
copied <- character(0)
for (png in png_files) {
  fname <- basename(png)
  target <- file.path(marketing_dir, fname)
  if (!file.exists(target) && normalizePath(dirname(png)) != normalizePath(marketing_dir)) {
    file.copy(png, target, overwrite = FALSE)
    copied <- c(copied, fname)
  }
}
if (length(copied) > 0) {
  cat(sprintf("    复制 %d 个文件\n", length(copied)))
} else {
  cat("    无需复制（已存在或无新文件）\n")
}
cat("\n")


# =============================================================================
# 4. 初始化 笔记.txt 和 商品设置.txt（从模板复制+核查）
# =============================================================================

cat("[4] 初始化 笔记.txt 和 商品设置.txt ...\n")

# 模板路径（skill 内置固定路径）
tpl_dir <- "d:/R/.agents/skills/DSH-code-marketing/templates"
note_tpl   <- file.path(tpl_dir, "note.md")
product_tpl <- file.path(tpl_dir, "product.md")

# ---------- 笔记.txt ----------
note_path <- file.path(marketing_dir, "笔记.txt")
if (!file.exists(note_path) && file.exists(note_tpl)) {
  file.copy(note_tpl, note_path, overwrite = FALSE)
  cat("    [COPY] 笔记.txt 已从模板复制（请手动编辑后填充具体内容）\n")
} else if (file.exists(note_path)) {
  cat("    [KEEP] 笔记.txt 已存在\n")
} else {
  cat("    [MISS] 笔记.txt 缺失且未找到模板\n")
}

# ---------- 商品设置.txt ----------
product_path <- file.path(marketing_dir, "商品设置.txt")
if (!file.exists(product_path) && file.exists(product_tpl)) {
  file.copy(product_tpl, product_path, overwrite = FALSE)
  cat("    [COPY] 商品设置.txt 已从模板复制（请手动编辑后填充具体内容）\n")
} else if (file.exists(product_path)) {
  cat("    [KEEP] 商品设置.txt 已存在\n")
} else {
  cat("    [MISS] 商品设置.txt 缺失且未找到模板\n")
}
cat("\n")


# =============================================================================
# 5. 自动生成代码/数据/使用说明截图
# =============================================================================

cat("[5] 自动生成截图（三个独立脚本）...\n")

# 设置 webshot2 用 Edge（无 Chrome 时）
edge_paths <- c(
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "C:/Program Files/Microsoft/Edge/Application/msedge.exe"
)
for (p in edge_paths) {
  if (file.exists(p)) {
    Sys.setenv(CHROMOTE_CHROME = p)
    cat(sprintf("    [INFO] CHROMOTE_CHROME = %s\n", p))
    break
  }
}

script_dir <- "d:/R/.agents/skills/DSH-code-marketing/scripts"
has_webshot2 <- requireNamespace("webshot2", quietly = TRUE)
has_knitr    <- requireNamespace("knitr", quietly = TRUE)

# ---- 5.1 code_preview.png（capture_code.R）----
if (has_webshot2 && file.exists(file.path(script_dir, "capture_code.R"))) {
  source(file.path(script_dir, "capture_code.R"))
  target <- file.path(marketing_dir, "code_preview.png")
  if (!file.exists(target) && length(r_scripts) >= 1) {
    main_scripts <- r_scripts[!grepl("install_dependencies", basename(r_scripts), ignore.case = TRUE)]
    main_script <- if (length(main_scripts) >= 1) main_scripts[1] else r_scripts[1]
    tryCatch({
      capture_code(target, script = main_script, n = 50)
      cat("    [GEN] code_preview.png\n")
    }, error = function(e) cat(sprintf("    [SKIP] code_preview.png 失败: %s\n", e$message)))
  }
} else {
  cat("    [SKIP] code_preview.png — 缺少 webshot2 或 capture_code.R\n")
}

# ---- 5.2 input_data.png（capture_table.R）----
if (has_webshot2 && has_knitr && file.exists(file.path(script_dir, "capture_table.R"))) {
  source(file.path(script_dir, "capture_table.R"))
  main_scripts <- r_scripts[!grepl("install_dependencies", basename(r_scripts), ignore.case = TRUE)]
  main_script <- if (length(main_scripts) >= 1) main_scripts[1] else r_scripts[1]
  input_paths <- character(0)
  if (length(main_scripts) >= 1) {
    txt <- readLines(main_script, warn = FALSE)
    pat <- 'read_(tsv|csv|table)\\(["\']([^"\'\\)]+)["\']'
    m <- regmatches(txt, regexpr(pat, txt))
    if (length(m) > 0) {
      files <- gsub(pat, "\\2", m)
      for (f in unique(files)) {
        fp <- file.path(project_dir, f)
        if (file.exists(fp)) input_paths <- c(input_paths, fp)
      }
    }
  }
  if (length(input_paths) == 0) input_paths <- data_files

  for (i in seq_along(input_paths)) {
    fp <- input_paths[i]
    if (!grepl("\\.(tsv|csv|txt|xlsx?)$", fp, ignore.case = TRUE)) next
    target_name <- if (i == 1) "input_data.png" else paste0("input_data_", i, ".png")
    target <- file.path(marketing_dir, target_name)
    if (!file.exists(target)) {
      tryCatch({
        capture_table(fp, target, nrows = 5)
        cat(sprintf("    [GEN] %s\n", target_name))
      }, error = function(e) cat(sprintf("    [SKIP] %s 失败: %s\n", target_name, e$message)))
    }
  }
} else {
  cat("    [SKIP] input_data.png — 缺少 webshot2/knitr 或 capture_table.R\n")
}

# ---- 5.3 使用说明.png（capture_html.R）----
if (file.exists(file.path(script_dir, "capture_html.R"))) {
  source(file.path(script_dir, "capture_html.R"))
  if (length(html_files) >= 1) {
    target <- file.path(marketing_dir, "使用说明.png")
    if (!file.exists(target)) {
      tryCatch({
        capture_html(html_files[1], target, stop_at_image = TRUE)
        cat("    [GEN] 使用说明.png\n")
      }, error = function(e) cat(sprintf("    [SKIP] 使用说明.png 失败: %s\n", e$message)))
    }
  }
} else {
  cat("    [SKIP] 使用说明.png — 缺少 capture_html.R\n")
}
cat("\n")

# ---- 5.4 输出表格截图（capture_table.R）----
if (has_webshot2 && has_knitr && file.exists(file.path(script_dir, "capture_table.R"))) {
  source(file.path(script_dir, "capture_table.R"))

  # 从 R 脚本中扫描 write_* 输出文件
  output_paths <- character(0)
  if (length(main_scripts) >= 1) {
    txt <- readLines(main_script, warn = FALSE)
    # 匹配 write.csv / write.table / write_tsv / write_csv / write_excel_csv 等
    pat <- '(write\\.(csv|table|tsv|csv2)|write_csv|write_tsv|write_excel_csv)\\([^,]+,\\s*["\']([^"\']+)["\']'
    m <- regmatches(txt, gregexpr(pat, txt, perl = TRUE))
    if (length(m) > 0 && length(m[[1]]) > 0) {
      files <- gsub(pat, "\\3", m[[1]], perl = TRUE)
      output_paths <- unique(files)
    }
  }

  # 兜底：扫描项目目录中的 CSV/TSV，排除输入文件
  if (length(output_paths) == 0) {
    all_csv <- list.files(project_dir, "\\.(csv|tsv)$", full.names = TRUE, ignore.case = TRUE)
    # 排除已知输入文件
    input_basenames <- basename(input_paths)
    output_paths <- all_csv[!basename(all_csv) %in% input_basenames]
  } else {
    # 转为绝对路径
    output_paths <- file.path(project_dir, output_paths)
  }

  # 过滤存在的文件
  output_paths <- output_paths[file.exists(output_paths)]

  if (length(output_paths) > 0) {
    for (i in seq_along(output_paths)) {
      fp <- output_paths[i]
      if (!grepl("\\.(tsv|csv)$", fp, ignore.case = TRUE)) next
      target_name <- if (i == 1) "output_data.png" else paste0("output_data_", i, ".png")
      target <- file.path(marketing_dir, target_name)
      if (!file.exists(target)) {
        tryCatch({
          capture_table(fp, target, nrows = 10)
          cat(sprintf("    [GEN] %s (from %s)\n", target_name, basename(fp)))
        }, error = function(e) cat(sprintf("    [SKIP] %s 失败: %s\n", target_name, e$message)))
      }
    }
  } else {
    cat("    [SKIP] output_data.png — 未找到输出表格文件\n")
  }
} else {
  cat("    [SKIP] output_data.png — 缺少 webshot2/knitr 或 capture_table.R\n")
}
cat("\n")


# =============================================================================
# 6. 校验 + 总结
# =============================================================================

cat("[6] 校验必备文件 ...\n")
required <- c("笔记.txt", "商品设置.txt", "code_preview.png", "使用说明.png", "input_data.png")
for (f in required) {
  p <- file.path(marketing_dir, f)
  if (file.exists(p)) {
    cat(sprintf("    [OK]   %s\n", f))
  } else {
    cat(sprintf("    [MISS] %s\n", f))
  }
}
cat("\n")

cat("========================================\n")
cat("完成！\n")
cat(sprintf("发布目录: %s\n", marketing_dir))
cat("\n当前文件:\n")
all_files <- list.files(marketing_dir)
for (f in sort(all_files)) {
  size <- file.info(file.path(marketing_dir, f))$size
  cat(sprintf("  %-30s  %s bytes\n", f, format(size, big.mark = ",")))
}
cat("========================================\n")
