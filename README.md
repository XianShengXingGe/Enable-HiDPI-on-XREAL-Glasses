# Enable HiDPI on XREAL Glasses

[English](#english) · [中文](#中文)

## English

An experimental macOS helper that registers preset HiDPI modes for compatible XREAL Glasses equipped with the X1 chip. It detects supported devices automatically; users do not need to configure device-specific values manually.

> **Experimental:** This tool modifies macOS display override files and relies on implementation details that can change between macOS releases. Use it at your own risk, back up important work before installation, and keep the restore script available.

### Before you begin

- **Support scope:** This release supports only XREAL Glasses equipped with the **X1 chip**. XREAL Glasses with other chips are not supported.
- Connect and power on a compatible XREAL Glasses device.
- Use a macOS administrator account. The scripts request elevation only to write or restore the relevant system configuration.
- Compatibility depends on macOS version, Mac hardware, cables, docks, and the display chain. Registering a mode does not guarantee that macOS selects it automatically.

### Install

1. Download and extract a release archive.
2. Double-click `hidpi.command`.
3. Enter the administrator password when prompted.
4. Restart the Mac when installation finishes.
5. Open **System Settings → Displays → Show all resolutions**, then select the new HiDPI option.

If macOS blocks the script, right-click `hidpi.command`, choose **Open**, and confirm. You can also run it from Terminal inside the extracted folder:

```bash
chmod +x *.command *.sh
./hidpi.command
```

### Restore

Run `uninstall-hidpi.command`, enter the administrator password, and restart the Mac. The restore script uses its local installation record to restore a pre-existing configuration or remove only the configuration written by this tool.

### Why use 1888 instead of 1920?

#### Core reason

The glasses have a physical native resolution of `1920 × 1080`, which macOS normally recognizes as a standard LoDPI mode. Even if a script adds a `1920 × 1080` logical mode with a `3840 × 2160` HiDPI backing render, the logical size exactly matches the native mode. macOS can merge or filter the two modes, or prefer the native LoDPI mode, so the intended HiDPI configuration may not become selectable.

Using the slightly smaller `1888 × 1062` logical resolution avoids that collision. macOS can recognize it as a separate scaled HiDPI mode.

#### Display pipeline

```text
Logical desktop: 1888 × 1062
        ↓
macOS HiDPI rendering: 3776 × 2124
        ↓
macOS scaled output: 1920 × 1080
        ↓
Glasses receive: 1920 × 1080
```

`1888 × 1062` is only the macOS logical resolution. The glasses still receive standard `1920 × 1080` timing.

#### Why specifically 1888 × 1062?

- It differs from the native `1920 × 1080` by only about **1.67%**, so the desktop-space change is small.
- It strictly preserves **16:9**, avoiding stretching or letterboxing.
- Both dimensions are even, which is friendlier to screen recording, video encoding, and some image pipelines.
- It avoids macOS merging or filtering a native-sized HiDPI mode.
- It has been verified in real-device testing to become effective.

#### Conclusion

`1888 × 1062` gives up about **1.67%** of logical desktop space in exchange for a separately recognizable and selectable HiDPI mode, while preserving the glasses' standard physical `1920 × 1080` input.

### Privacy and security

The scripts do not collect, upload, download, or execute remote code.

This is information minimization and obfuscation, not a security boundary. A local administrator can inspect generated system configuration. When filing an issue, remove personal information and unredacted logs. See [SECURITY.md](SECURITY.md) and the issue templates for safe reporting guidance.

### References and attribution

This repository ships its own scripts and has no runtime dependency on, vendored code from, or bundled binaries from the projects below.

- [One Key HiDPI](https://github.com/xzhih/one-key-hidpi): referenced for its public discussion of macOS display overrides and the general HiDPI workflow. Its source code is not copied or bundled here. Because that repository does not declare a license, contributors must not copy from it without the copyright holder's written permission.
- [displayplacer](https://github.com/jakehilborn/displayplacer): referenced while researching macOS display enumeration and mode-selection directions. It is not used by this tool at runtime and no code from it is bundled.
- [BetterDisplay](https://github.com/waydabber/BetterDisplay): referenced for user-facing HiDPI behavior and test expectations. It is not a dependency or an endorsed integration.
- [Apple Quartz Display Services](https://developer.apple.com/documentation/coregraphics/quartz-display-services): referenced for the underlying macOS display-services model and future native implementation work.

### Verify a release

Each release contains `CHECKSUMS.txt`. From the extracted folder, run:

```bash
shasum -a 256 -c CHECKSUMS.txt
```

### Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for local validation and contribution guidance. The first public release is an experimental preview.

### License

This project is licensed under the [MIT License](LICENSE).

## 中文

这是一个实验性的 macOS 辅助工具，用于为搭载 X1 芯片的兼容 XREAL Glasses 注册预设 HiDPI 模式。它会自动识别兼容设备；用户不需要手动配置设备专属参数。

> **实验性工具：** 本工具会修改 macOS 显示 Override 文件，并依赖可能随 macOS 版本变化的实现细节。请自行评估风险；安装前请保存重要工作，并保留恢复脚本。

### 使用前须知

- **支持范围：** 当前版本仅支持搭载 **X1 芯片** 的 XREAL Glasses，不支持搭载其他芯片的 XREAL 眼镜。
- 请连接并点亮兼容的 XREAL Glasses 设备。
- 请使用 macOS 管理员账户。脚本仅在写入或恢复相关系统配置时请求提权。
- 兼容性取决于 macOS 版本、Mac 硬件、线材、扩展坞和显示链路。注册模式不保证 macOS 会自动选中它。

### 安装

1. 下载并解压 Release 压缩包。
2. 双击运行 `hidpi.command`。
3. 根据提示输入 macOS 管理员密码。
4. 安装完成后重启 Mac。
5. 打开“系统设置 → 显示器 → 显示所有分辨率”，选择新增的 HiDPI 选项。

若 macOS 阻止运行脚本，请右键点击 `hidpi.command`，选择“打开”并确认。也可以在终端进入解压目录后执行：

```bash
chmod +x *.command *.sh
./hidpi.command
```

### 为什么选择 1888，而不是 1920？

#### 核心原因

眼镜的物理原生分辨率已经是 `1920 × 1080`，macOS 默认将其识别为普通 LoDPI 模式。即使脚本额外写入逻辑分辨率为 `1920 × 1080`、HiDPI 渲染为 `3840 × 2160` 的模式，由于逻辑尺寸与原生模式完全相同，macOS 也可能将两者合并、过滤，或优先保留原生 LoDPI 模式，导致 HiDPI 配置写入后仍不生效。

将逻辑分辨率略微降低到 `1888 × 1062` 后，它不再与原生模式冲突，macOS 可以将其识别为独立的缩放 HiDPI 模式。

#### 实际显示链路

```text
逻辑桌面：1888 × 1062
        ↓
macOS HiDPI 渲染：3776 × 2124
        ↓
macOS 缩放输出：1920 × 1080
        ↓
眼镜接收：1920 × 1080
```

`1888 × 1062` 只是 macOS 的逻辑分辨率，眼镜实际接收的仍然是标准 `1920 × 1080` Timing。

#### 为什么具体选择 1888 × 1062？

- 与原生 `1920 × 1080` 仅相差约 **1.67%**，桌面空间变化很小。
- 严格保持 **16:9**，不会产生画面拉伸或黑边。
- 宽高均为偶数，对录屏、视频编码和部分图像管线更加友好。
- 能够避开 macOS 对原生分辨率 HiDPI 模式的合并或过滤。
- 已经通过实际测试，确认可以正常生效。

#### 最终结论

选择 `1888 × 1062`，本质上是用约 **1.67% 的桌面空间损失**，换取一个能够被 macOS 正常识别和启用的独立 HiDPI 模式，同时保持眼镜物理输入仍为标准 `1920 × 1080`。

### 恢复

运行 `uninstall-hidpi.command`，输入管理员密码后重启 Mac。恢复脚本会读取本机安装记录：若安装前已有配置则还原它，否则仅移除本工具写入的配置。

### 隐私与安全

脚本不收集、不上传、不下载，也不会执行远程代码。

这属于信息最小化和混淆，不是安全边界。本机管理员仍可检查生成后的系统配置。提交 Issue 时，请移除个人信息和未脱敏日志。安全问题与脱敏要求见 [SECURITY.md](SECURITY.md) 和 Issue 模板。

### 参考项目与致谢

本仓库仅发布自身脚本；不包含、未 vendoring、也不在运行时依赖以下项目的代码或二进制文件。

- [One Key HiDPI](https://github.com/xzhih/one-key-hidpi)：参考其公开的 macOS 显示 Override 与通用 HiDPI 流程说明。本项目不复制或打包其源码。该仓库未声明许可证；未经版权持有人书面许可，贡献者不得复制其代码。
- [displayplacer](https://github.com/jakehilborn/displayplacer)：用于调研 macOS 显示器枚举和模式选择方向。本工具运行时不使用它，也不包含其代码。
- [BetterDisplay](https://github.com/waydabber/BetterDisplay)：用于参考面向用户的 HiDPI 行为与测试预期。它不是本工具的依赖，也不表示获得其官方背书或集成认证。
- [Apple Quartz Display Services](https://developer.apple.com/documentation/coregraphics/quartz-display-services)：用于参考底层 macOS 显示服务模型及未来原生实现方向。

### 校验 Release 文件

每个 Release 都会附带 `CHECKSUMS.txt`。在解压目录中运行：

```bash
shasum -a 256 -c CHECKSUMS.txt
```

### 参与开发

本地校验与贡献说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。首个公开版本为实验性预览版。

### 许可证

本项目采用 [MIT License](LICENSE) 开源许可证。
