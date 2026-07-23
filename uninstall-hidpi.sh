#!/bin/bash

set -euo pipefail

STATE_ROOT="${HOME}/Library/Application Support/Enable HiDPI on XREAL Glasses"

log() {
    printf '[Enable HiDPI on XREAL Glasses] %s\n' "$*"
}

fail() {
    printf '[Enable HiDPI on XREAL Glasses] Error / 错误: %s\n' "$*" >&2
    exit 1
}

[[ "$(uname -s)" == "Darwin" ]] || fail "This script runs only on macOS. / 此脚本只能在 macOS 上运行。"
[[ "${EUID}" -ne 0 ]] || fail "Run this script as a standard user. / 请以普通用户运行脚本。"

log "Administrator permission is required to restore the display configuration. / 需要管理员权限恢复显示配置。"
sudo -v || fail "Administrator permission was not granted. / 未获得管理员权限。"

changed=0
index=0
if [[ -d "${STATE_ROOT}/devices" ]]; then
    for device_dir in "${STATE_ROOT}"/devices/*; do
        [[ -d "${device_dir}" ]] || continue
        [[ -f "${device_dir}/target-path" ]] || continue

        index=$((index + 1))
        target_file="$(cat "${device_dir}/target-path")"
        target_dir="$(dirname "${target_file}")"

        case "${target_file}" in
            /Library/Displays/Contents/Resources/Overrides/DisplayVendorID-*/DisplayProductID-*) ;;
            *) fail "An invalid restore path was found; no further changes were made. / 检测到无效的恢复路径，操作已停止。" ;;
        esac

        if [[ -f "${device_dir}/original" ]]; then
            sudo mkdir -p "${target_dir}"
            sudo chown root:wheel "${target_dir}"
            sudo chmod 0755 "${target_dir}"
            sudo install -o root -g wheel -m 0644 "${device_dir}/original" "${target_file}"
            log "The pre-installation configuration for device ${index} was restored. / 设备 ${index} 已恢复安装前配置。"
            changed=1
        elif [[ -f "${device_dir}/no-original" ]]; then
            sudo rm -f "${target_file}"
            log "The tool configuration for device ${index} was removed. / 设备 ${index} 的工具配置已移除。"
            changed=1
        fi

        if sudo test -d "${target_dir}"; then
            sudo rmdir "${target_dir}" 2>/dev/null || true
        fi
        rm -rf "${device_dir}"
    done
fi

rmdir "${STATE_ROOT}/devices" 2>/dev/null || true
rmdir "${STATE_ROOT}" 2>/dev/null || true

if [[ "${changed}" -eq 1 ]]; then
    log "Restore is complete. Restart your Mac. / 恢复完成，请重启 Mac。"
else
    log "No installation record created by this tool was found; no configuration was changed. / 未找到本工具创建的安装记录，没有修改任何配置。"
fi
