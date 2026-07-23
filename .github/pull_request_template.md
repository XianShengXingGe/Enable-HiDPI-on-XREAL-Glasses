## Summary / 摘要

Describe the user-facing change and the validation performed.

说明面向用户的变更和已完成的验证。

## Validation / 验证

- [ ] `bash -n` passes for all four scripts.
- [ ] `shasum -a 256 -c CHECKSUMS.txt` passes.
- [ ] I regenerated `CHECKSUMS.txt` if a checksummed file changed.
- [ ] I tested installation and restore on appropriate hardware, or explained why that was not possible.
- [ ] 我已对所有四个脚本执行 `bash -n` 校验。
- [ ] `shasum -a 256 -c CHECKSUMS.txt` 已通过。
- [ ] 如已纳入校验的文件发生变更，我已重新生成 `CHECKSUMS.txt`。
- [ ] 我已在合适硬件上测试安装和恢复，或已说明无法测试的原因。

## Sensitive-information check / 敏感信息检查

- [ ] This change contains no device identifiers, display parameters, internal names, EDID data, private paths, or test logs.
- [ ] I did not add a release archive or generated system configuration to Git.
- [ ] 此变更不包含设备识别参数、显示参数、内部名称、EDID 数据、私有路径或测试日志。
- [ ] 我没有向 Git 添加发布压缩包或生成的系统配置。
