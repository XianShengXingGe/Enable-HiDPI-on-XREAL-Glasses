# Contributing to Enable HiDPI on XREAL Glasses / 参与贡献

Thanks for helping improve the project.

感谢你帮助改进本项目。

## Before opening a pull request / 提交 Pull Request 前

1. Keep public code, documentation, fixtures, and commit messages free of device identifiers, display parameters, internal names, EDID dumps, and private test data.
2. Preserve support for the macOS system Bash shipped by Apple. Do not introduce Bash 4+ features without an explicit compatibility decision.
3. Run the local checks below.
4. Describe the macOS version, Mac architecture, and test outcome using the PR template. Do not include sensitive hardware output.

1. 请确保公开代码、文档、测试样例和提交信息不包含设备识别参数、显示参数、内部名称、EDID 转储或私有测试数据。
2. 请保持对 macOS 自带 Bash 的兼容性；未明确决定前，不要引入 Bash 4+ 特性。
3. 请运行下列本地校验。
4. 请使用 PR 模板说明 macOS 版本、Mac 架构和测试结果；不要包含敏感硬件输出。

```bash
bash -n hidpi.sh
bash -n uninstall-hidpi.sh
bash -n hidpi.command
bash -n uninstall-hidpi.command
shasum -a 256 -c CHECKSUMS.txt
```

When editing any checksummed release file, regenerate `CHECKSUMS.txt` before submitting the change. Do not include `CHECKSUMS.txt` in its own checksum list.

修改任何已纳入校验的发布文件后，请在提交前重新生成 `CHECKSUMS.txt`。不要把 `CHECKSUMS.txt` 自身纳入校验列表。

## Testing expectations / 测试预期

If you have appropriate hardware, test installation, restart, manual mode selection, repeat installation, restore, and a multi-display setup. CI validates syntax and file integrity only; it cannot prove that macOS loads a display override.

如具备合适硬件，请测试安装、重启、手动选择模式、重复安装、恢复和多显示器场景。CI 仅校验语法和文件完整性，不能证明 macOS 已加载显示 Override。

## Reporting issues / 反馈问题

Use the provided forms and remove personal paths, full EDID data, complete `ioreg` output, and device-identification fields before posting.

请使用提供的表单，并在提交前移除个人路径、完整 EDID 数据、完整 `ioreg` 输出和设备识别字段。
