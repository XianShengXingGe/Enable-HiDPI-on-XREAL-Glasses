# Enable HiDPI on XREAL Glasses — Security policy / 安全策略

## Scope / 范围

This tool requests administrator privileges to write or restore specific macOS display override files. It does not collect or transmit user data, and it does not fetch or execute remote code.

本工具需要管理员权限来写入或恢复特定 macOS 显示 Override 文件。它不收集或传输用户数据，也不会获取或执行远程代码。

## Reporting a vulnerability / 报告安全问题

Please use GitHub private vulnerability reporting after it is enabled for this repository. Until then, contact the maintainer through a private channel listed in the repository profile. Do not open a public issue for a suspected vulnerability.

本仓库启用 GitHub 私密漏洞报告后，请使用该渠道。在此之前，请通过仓库资料中列出的私密渠道联系维护者。请勿针对疑似漏洞创建公开 Issue。

Do not share full EDID dumps, complete `ioreg` output, device identifiers, personal paths, or unredacted system logs in any report.

请勿在任何报告中分享完整 EDID 转储、完整 `ioreg` 输出、设备识别参数、个人路径或未脱敏系统日志。

## Recovery / 恢复

Keep `uninstall-hidpi.command` available after installation. It uses the local installation record to restore an existing configuration or remove only the configuration written by this tool. Restart macOS after recovery.

安装后请保留 `uninstall-hidpi.command`。它会使用本地安装记录恢复既有配置，或仅移除本工具写入的配置。恢复后请重启 macOS。
