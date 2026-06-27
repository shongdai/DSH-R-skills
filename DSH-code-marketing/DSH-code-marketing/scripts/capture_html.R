#!/usr/bin/env Rscript
# =============================================================================
# capture_html.R — HTML 使用说明长截图（截到第一张图即停）
#
# 描述: 用 xml2 解析 HTML，定位第一个 <img>，删除其后所有兄弟节点，
#       再用 Headless Edge/Chrome 全屏截图。
# 用法: source("capture_html.R"); capture_html("使用说明.html", "output.png")
# 依赖: xml2
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

#' 截取 HTML 为长图 — 截到第一张图即停
#'
#' @param html_path        HTML 文件路径（绝对路径）
#' @param target           输出 PNG 路径
#' @param stop_at_image    是否截到第一张 <img> 即停（默认 TRUE）
capture_html <- function(html_path, target, stop_at_image = TRUE) {
  if (!file.exists(html_path)) stop("HTML 文件不存在: ", html_path)

  # ---- 1. 找浏览器 ----
  browser <- NULL
  for (p in c(
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe"
  )) {
    if (file.exists(p)) { browser <- p; break }
  }
  if (is.null(browser))
    stop("未找到 Edge/Chrome，请安装 Microsoft Edge")

  work_html <- html_path

  # ---- 2. 截到第一张图：逐层 display:none 隐藏（保留 DOM 为 TOC）----
  if (stop_at_image && requireNamespace("xml2", quietly = TRUE)) {
    doc <- tryCatch(
      xml2::read_html(html_path, encoding = "UTF-8"),
      error = function(e) NULL
    )
    if (!is.null(doc)) {
      img <- xml2::xml_find_first(doc, "//img")
      if (length(img) > 0 && !is.na(img)) {
        # 辅助函数：给元素加 display:none!important
        hide_node <- function(node) {
          s <- xml2::xml_attr(node, "style")
          if (is.na(s)) s <- ""
          xml2::xml_attr(node, "style") <- paste0(s, "display:none!important;")
        }

        # 从 img 向上走，每层隐藏其后的所有兄弟节点
        # 在 .col-sm-* / .row / .container-fluid 处停止
        node <- img
        while (!is.na(node)) {
          parent <- xml2::xml_parent(node)
          if (is.na(parent)) break

          pclass <- xml2::xml_attr(parent, "class")
          pid    <- xml2::xml_attr(parent, "id")
          if (!is.na(pclass) && grepl("col-sm-|row|container-fluid|main-container", pclass)) break
          if (!is.na(pid)    && grepl("main|header", pid, ignore.case = TRUE)) break

          # 隐藏 node 在当前父级中的所有后续兄弟
          sibs <- xml2::xml_find_all(node, "xpath:following-sibling::*")
          for (s in sibs) hide_node(s)

          node <- parent
        }

        # 注入紧凑 CSS：消除多余 margin/padding
        head <- xml2::xml_find_first(doc, "//head")
        if (length(head) > 0 && !is.na(head)) {
          tight_css <- paste0(
            "\n<style>",
            "body{padding-top:6px!important;padding-bottom:0!important;margin:0!important}",
            ".container-fluid{padding-left:15px!important;padding-right:15px!important}",
            "#header{margin-top:0!important;margin-bottom:8px!important}",
            "h1{font-size:24px!important;margin-top:0!important}",
            "h2{font-size:18px!important;margin-top:8px!important;margin-bottom:4px!important}",
            "h3{font-size:15px!important}",
            ".section{padding-top:0!important}",
            "p{margin-bottom:4px!important}",
            "img{max-height:480px!important}",
            "</style>"
          )
          xml2::xml_add_child(head, xml2::read_html(tight_css))
        }

        work_html <- tempfile(fileext = ".html")
        xml2::write_html(doc, work_html)
      }
    }
  }

  # ---- 3. Headless 浏览器截图（紧凑窗口） ----
  abs_html   <- normalizePath(work_html, winslash = "/")
  abs_target <- normalizePath(target, winslash = "/", mustWork = FALSE)

  cmd <- sprintf(
    '"%s" --headless=new --disable-gpu --no-sandbox --hide-scrollbars --force-device-scale-factor=4 --window-size=1200,1200 --virtual-time-budget=5000 --screenshot="%s" "file:///%s"',
    browser, abs_target, abs_html
  )
  res <- system(cmd, wait = TRUE, ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (res != 0) stop("浏览器截图失败，状态码: ", res)
  if (!file.exists(target) || file.info(target)$size < 1000)
    stop("截图未生成或文件过小")

  # ---- 4. 自动裁剪底部和右侧空白 ----
  tryCatch({
    png_data <- png::readPNG(target, native = FALSE)
    # 找到非白色像素的边界
    is_content <- png_data[, , 1] < 0.99 | png_data[, , 2] < 0.99 | png_data[, , 3] < 0.99
    rows <- which(rowSums(is_content) > 0)
    cols <- which(colSums(is_content) > 0)
    if (length(rows) > 0 && length(cols) > 0) {
      png_data <- png_data[min(rows):max(rows), min(cols):max(cols), , drop = FALSE]
      png::writePNG(png_data, target)
    }
  }, error = function(e) NULL)  # png 包不存在则跳过裁剪
}


# ---- CLI 入口 ----
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2L)
    stop("用法: Rscript capture_html.R <使用说明.html> <output.png>")
  capture_html(args[1], args[2])
  cat("capture_html OK: ", args[2], "\n")
}
