# DSH-R-skills

R 代码工作流三件套技能，用于 Trae CN IDE。

## 技能列表

| 技能 | 用途 |
|------|------|
| **DSH-r-style** | 统一 R 代码风格：标准代码头部、install_dependencies.R、styler 自动格式化 |
| **DSH-r-usage** | 为 R 绘图脚本生成标准化使用说明（Rmd + HTML） |
| **DSH-code-marketing** | 整理发布/营销物料：截图（代码/数据/说明）+ 小红书笔记 + 闲鱼商品设置 |

## 协作流水线

```
R 脚本 ——(DSH-r-style)→ 风格统一的脚本
               ↓
      (DSH-r-usage)→ Rmd + HTML 使用说明
               ↓
      (DSH-code-marketing)→ 发布/ 文件夹（截图+文案）
               ↓
          小红书 / 闲鱼 发布
```

## 部署方式

将各技能目录复制到 Trae CN 的 `builtin_skills` 目录：

```
C:\Users\<用户名>\.trae-cn\builtin_skills\
```
