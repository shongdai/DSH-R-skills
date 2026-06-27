#!/usr/bin/env Rscript
# =============================================================================
# 依赖安装脚本
#
# 使用方法:
#   source("install_dependencies.R")
# =============================================================================

## 0. 镜像设置 ----------------------------------------------------------
options(repos = c(CRAN = "https://mirrors.westlake.edu.cn/CRAN/"))
options(BioC_mirror = "https://mirrors.westlake.edu.cn/bioconductor/")

## 1. 日志工具 -----------------------------------------------------------
log_msg <- function(level, fmt, ...) {
  cat(sprintf("[%s] %s ", level, format(Sys.time(), "%H:%M:%S")),
    sprintf(fmt, ...), "\n",
    sep = ""
  )
}

## 2. 包清单 -------------------------------------------------------------
# CRAN 包
cran_packages <- c(
  # 在此填写 CRAN 包名（每行一个），示例：
  # "ggplot2",
  # "tidyverse"
)

# Bioconductor 包
bioc_packages <- c(
  # 在此填写 Bioconductor 包名（每行一个），示例：
  # "clusterProfiler",
  # "enrichplot"
)

# GitHub 包
github_packages <- c(
  # 在此填写 "用户名/仓库名"，示例：
  # "YuLab-SMU/clusterProfiler"
)

# 指定版本包
version_packages <- c(
  # 在此填写 "包名" = "版本号"，示例：
  # "enrichplot" = "1.18.0"
)

## 3. 缓存已安装 ---------------------------------------------------------
ipk <- unique(rownames(installed.packages(fields = "Package")))

need <- function(p, src = "CRAN") {
  miss <- setdiff(p, ipk)
  skip <- intersect(p, ipk)
  if (length(skip)) {
    log_msg("INFO", "已安装的%s包，跳过：%s", src, toString(skip))
  }
  miss
}

## 4. 安装函数 ------------------------------------------------------------
install_cran <- function(pkgs) {
  if (!length(pkgs)) {
    return(invisible())
  }
  tryCatch(
    {
      install.packages(pkgs, dependencies = TRUE)
      log_msg("SUCCESS", "CRAN 批量安装完成: %s", toString(pkgs))
    },
    error = function(e) {
      log_msg("WARN", "批量安装失败，转入逐个重试: %s", e$message)
      for (p in pkgs) {
        tryCatch(install.packages(p, dependencies = TRUE),
          error = function(e) log_msg("ERROR", "%s 安装失败: %s", p, e$message)
        )
      }
    }
  )
}

install_bioc <- function(pkgs) {
  if (!length(pkgs)) {
    return(invisible())
  }
  if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
  }
  BiocManager::install(pkgs, update = FALSE, ask = FALSE)
  log_msg("SUCCESS", "Bioconductor 安装完成: %s", toString(pkgs))
}

install_github <- function(repos) {
  if (!length(repos)) {
    return(invisible())
  }
  if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
  }

  for (repo in repos) {
    pkg <- basename(repo)
    if (pkg %in% ipk) {
      log_msg("INFO", "已安装的GitHub包，跳过：%s", pkg)
      next
    }
    tryCatch(
      {
        devtools::install_github(repo, upgrade = "never")
        log_msg("SUCCESS", "GitHub 包安装完成: %s", pkg)
        ipk <<- c(ipk, pkg)
      },
      error = function(e) {
        log_msg("ERROR", "%s 安装失败: %s", pkg, e$message)
      }
    )
  }
}

install_version <- function(named_vec) {
  if (!length(named_vec)) {
    return(invisible())
  }
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes")
  }

  for (pkg in names(named_vec)) {
    tgt_ver <- named_vec[[pkg]]
    local_ver <- tryCatch(as.character(utils::packageVersion(pkg)),
      error = function(e) NA
    )
    if (!is.na(local_ver) && local_ver == tgt_ver) {
      log_msg("INFO", "已安装的特定版本源包，跳过：%s %s", pkg, tgt_ver)
      next
    }
    tryCatch(
      {
        remotes::install_version(pkg, version = tgt_ver, upgrade = "never")
        log_msg("SUCCESS", "%s 版本 %s 安装完成", pkg, tgt_ver)
      },
      error = function(e) {
        log_msg("ERROR", "%s 版本 %s 安装失败: %s", pkg, tgt_ver, e$message)
      }
    )
  }
}

## 5. 执行 ----------------------------------------------------------------
log_msg("INFO", "========== 开始依赖安装 ==========")
install_cran(need(cran_packages, "CRAN"))
install_bioc(need(bioc_packages, "Bioconductor"))
install_github(need(github_packages, "GitHub"))
install_version(version_packages)
log_msg("INFO", "========== 依赖安装结束 ==========")
