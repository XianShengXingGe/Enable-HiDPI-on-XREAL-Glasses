#!/bin/bash

# Public distribution build.
# Device allow-list entries are stored as one-way fingerprints and display
# profiles are stored as opaque payloads. This is obfuscation, not a security
# boundary: a determined analyst can still inspect runtime behavior.

set -euo pipefail

OVERRIDES_ROOT="/Library/Displays/Contents/Resources/Overrides"
STATE_ROOT="${HOME}/Library/Application Support/Enable HiDPI on XREAL Glasses"
TMP_DIR=""
DETECTED_FILE=""

cleanup() {
    if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
        rm -rf "${TMP_DIR}"
    fi
}
trap cleanup EXIT

log() {
    printf '[Enable HiDPI on XREAL Glasses] %s\n' "$*"
}

warn() {
    printf '[Enable HiDPI on XREAL Glasses] Warning / 警告: %s\n' "$*" >&2
}

fail() {
    printf '[Enable HiDPI on XREAL Glasses] Error / 错误: %s\n' "$*" >&2
    exit 1
}

sha256_text() {
    printf '%s' "$1" | /usr/bin/shasum -a 256 | /usr/bin/awk '{print $1}'
}

normalize_name() {
    printf '%s' "$1" \
        | /usr/bin/sed 's/[[:space:]]*$//' \
        | /usr/bin/tr '[:upper:]' '[:lower:]'
}

# id fingerprint | name fingerprint | profile token
fingerprint_records() {
    cat <<'RECORDS'
89f3eabe271ac5eef00002adcb34d454a2758abcfa1d8dd32f4eb6612a158998|d87e8a66c9ca79d07b82e5bc24708a18aa5489cd06705385051c48d48c3eb66b|P1
69cb59c1f46e7a2812c2ebb088ca7b4068587e638818097772089467526db924|6fd307d9831b0d993fd6b1115436fea42ddfd1eea548a9bd29c4d5b9bdc1cf25|P1
a3a9fdd3c2be3e45d51f9675db2e6f1ead2700e9432ae55c86e26af930782d4e|6db28e767c3fcb6d583a49c46dfda5937c8b345d37149e52105c3863004e3e68|P1
59052703d4c7d6e17b361b7fd5a507ce232fc9cc540cd6ac48629272b01ed212|72266126bd27bb2b8a8e6d23fc723994e67d3995891671407c73fbf57ac5f6a2|P2
3395b4625fc1ad2c09165d2406f547eb8896f6b8a898552a0a0b260fbd40bfe1|82f3e9c695dc6b8d1b11818d5701919e286de8d47f7c3eb3100c485f79e57828|P1
d06e467eb465004834e580a0ed6294b63f79ab033b84895b66a92136a6c8eb66|bed6de8d888b4cd684f06543a5d9cfc912f91526e3e00908a7bbd405bdd4bfc3|P1
RECORDS
}

require_macos() {
    [[ "$(uname -s)" == "Darwin" ]] || fail "This script runs only on macOS. / 此脚本只能在 macOS 上运行。"
    [[ "${EUID}" -ne 0 ]] || fail "Run this script as a standard user; it requests administrator access only when needed. / 请以普通用户运行脚本；仅在需要时请求管理员权限。"
}

request_admin_permission() {
    log "Administrator permission is required to write the display configuration. / 需要管理员权限写入显示配置。"
    sudo -v || fail "Administrator permission was not granted. / 未获得管理员权限。"
}

override_id_hex() {
    printf '%x' "$((16#$1))"
}

lookup_profile() {
    local vendor_hex product_hex monitor_name id_hash actual_name_hash
    local record_id_hash expected_name_hash profile

    vendor_hex="$(printf '%04x' "$((16#$1))")"
    product_hex="$(printf '%04x' "$((16#$2))")"
    monitor_name="$3"
    id_hash="$(sha256_text "${vendor_hex}:${product_hex}")"

    while IFS='|' read -r record_id_hash expected_name_hash profile; do
        [[ "${record_id_hash}" == "${id_hash}" ]] || continue

        if [[ -n "${monitor_name}" ]]; then
            actual_name_hash="$(sha256_text "$(normalize_name "${monitor_name}")")"
            if [[ "${actual_name_hash}" != "${expected_name_hash}" ]]; then
                return 2
            fi
        fi

        printf '%s|%s' "${profile}" "${id_hash}"
        return 0
    done < <(fingerprint_records)

    return 1
}

append_detected_record() {
    local record="$1"
    if ! /usr/bin/grep -Fqx "${record}" "${DETECTED_FILE}" 2>/dev/null; then
        printf '%s\n' "${record}" >> "${DETECTED_FILE}"
    fi
}

decode_edid_monitor_name() {
    local edid_hex="$1"
    local byte_offset char_offset descriptor name_hex name byte octal char i

    for byte_offset in 54 72 90 108; do
        char_offset=$((byte_offset * 2))
        descriptor="${edid_hex:${char_offset}:36}"

        if [[ "${descriptor:0:10}" == "000000fc00" ]]; then
            name_hex="${descriptor:10:26}"
            name=""
            i=0
            while [[ ${i} -lt ${#name_hex} ]]; do
                byte="${name_hex:${i}:2}"
                case "${byte}" in
                    00|0a|0d) break ;;
                esac
                octal="$(printf '%03o' "$((16#${byte}))")"
                printf -v char "\\${octal}"
                name="${name}${char}"
                i=$((i + 2))
            done
            printf '%s' "${name}" | /usr/bin/sed 's/[[:space:]]*$//'
            return 0
        fi
    done

    return 0
}

detect_supported_intel() {
    local edid vendor_hex product_hex monitor_name lookup profile token rc

    while IFS= read -r edid; do
        [[ -n "${edid}" ]] || continue
        edid="$(printf '%s' "${edid}" | /usr/bin/tr '[:upper:]' '[:lower:]')"
        [[ ${#edid} -ge 256 ]] || continue

        vendor_hex="${edid:16:4}"
        product_hex="${edid:22:2}${edid:20:2}"
        monitor_name="$(decode_edid_monitor_name "${edid}")"

        set +e
        lookup="$(lookup_profile "${vendor_hex}" "${product_hex}" "${monitor_name}")"
        rc=$?
        set -e

        if [[ ${rc} -eq 2 ]]; then
            warn "A similar device was found but identity verification failed; it was skipped. / 检测到相似设备，但身份校验未通过，已跳过。"
            continue
        fi
        [[ ${rc} -eq 0 ]] || continue

        IFS='|' read -r profile token <<< "${lookup}"
        append_detected_record "${vendor_hex}|$((16#${vendor_hex}))|${product_hex}|$((16#${product_hex}))|${profile}|${token}"
    done < <(
        ioreg -lw0 \
            | /usr/bin/grep -i '"IODisplayEDID"' \
            | /usr/bin/sed -E 's/.*<([0-9A-Fa-f]+)>.*/\1/' \
            || true
    )
}

extract_ioreg_number() {
    local key="$1"
    local line="$2"
    printf '%s' "${line}" \
        | /usr/bin/sed -nE "s/.*\"${key}\"[[:space:]]*=[[:space:]]*(0[xX][0-9A-Fa-f]+|[0-9]+).*/\1/p"
}

detect_supported_apple_silicon() {
    local attrs vendor_raw product_raw vendor_dec product_dec
    local vendor_hex product_hex monitor_name lookup profile token rc

    while IFS= read -r attrs; do
        [[ -n "${attrs}" ]] || continue

        vendor_raw="$(extract_ioreg_number 'LegacyManufacturerID' "${attrs}")"
        product_raw="$(extract_ioreg_number 'ProductID' "${attrs}")"
        [[ -n "${vendor_raw}" && -n "${product_raw}" ]] || continue

        vendor_dec=$((vendor_raw))
        product_dec=$((product_raw))
        vendor_hex="$(printf '%04x' "${vendor_dec}")"
        product_hex="$(printf '%04x' "${product_dec}")"
        monitor_name="$(printf '%s' "${attrs}" \
            | /usr/bin/sed -n 's/.*"ProductName"[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' \
            | /usr/bin/sed 's/[[:space:]]*$//')"

        set +e
        lookup="$(lookup_profile "${vendor_hex}" "${product_hex}" "${monitor_name}")"
        rc=$?
        set -e

        if [[ ${rc} -eq 2 ]]; then
            warn "A similar device was found but identity verification failed; it was skipped. / 检测到相似设备，但身份校验未通过，已跳过。"
            continue
        fi
        [[ ${rc} -eq 0 ]] || continue

        IFS='|' read -r profile token <<< "${lookup}"
        append_detected_record "${vendor_hex}|${vendor_dec}|${product_hex}|${product_dec}|${profile}|${token}"
    done < <(ioreg -l -w0 | /usr/bin/grep '"DisplayAttributes"' || true)
}

detect_supported_displays() {
    local count

    TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/hidpi-helper.XXXXXX")"
    DETECTED_FILE="${TMP_DIR}/detected"
    : > "${DETECTED_FILE}"

    if [[ "$(uname -m)" == "arm64" ]]; then
        detect_supported_apple_silicon
    else
        detect_supported_intel
    fi

    count="$(/usr/bin/grep -c '.' "${DETECTED_FILE}" 2>/dev/null || true)"
    [[ "${count}" -gt 0 ]] || fail "No compatible device was detected. Confirm it is connected, powered on, and recognized by macOS. / 未检测到兼容设备。请确认设备已连接、点亮并被 macOS 识别。"
    log "Detected ${count} compatible display device(s). / 已检测到 ${count} 个兼容显示设备。"
}

b64_decode() {
    local input="$1" output
    if output="$(printf '%s' "${input}" | /usr/bin/base64 -D 2>/dev/null)"; then
        printf '%s' "${output}"
    else
        printf '%s' "${input}" | /usr/bin/base64 -d
    fi
}

profile_payload() {
    local blob first
    case "$1" in
        P1) blob='UVVGQlQzZEJRVUZEUlhkQg==' ;;
        P2) blob='UVVGQlQzZEJRVUZEUlhkQkNrRkJRVTkzUVVGQlExUm5RUT09' ;;
        *) fail "The bundled configuration is invalid. / 内置配置无效。" ;;
    esac
    first="$(b64_decode "${blob}")"
    printf '%s\n' "$(b64_decode "${first}")"
}

profile_default_ppmm() {
    local blob first
    case "$1" in
        P1|P2) blob='TVRBdU1EWTVPVE13TVE9PQ==' ;;
        *) fail "The bundled configuration is invalid. / 内置配置无效。" ;;
    esac
    first="$(b64_decode "${blob}")"
    b64_decode "${first}"
}

state_paths() {
    local token="$1"
    DEVICE_STATE_DIR="${STATE_ROOT}/devices/${token}"
    STATE_TARGET_PATH="${DEVICE_STATE_DIR}/target-path"
    STATE_ORIGINAL="${DEVICE_STATE_DIR}/original"
    STATE_NO_ORIGINAL="${DEVICE_STATE_DIR}/no-original"
}

prepare_state() {
    local target_file="$1" token="$2"

    state_paths "${token}"
    mkdir -p "${DEVICE_STATE_DIR}"
    chmod 700 "${STATE_ROOT}" "${STATE_ROOT}/devices" "${DEVICE_STATE_DIR}" 2>/dev/null || true
    printf '%s\n' "${target_file}" > "${STATE_TARGET_PATH}"
    chmod 600 "${STATE_TARGET_PATH}"

    [[ -e "${STATE_ORIGINAL}" || -e "${STATE_NO_ORIGINAL}" ]] && return 0

    if sudo test -f "${target_file}"; then
        sudo cat "${target_file}" > "${STATE_ORIGINAL}"
        chmod 600 "${STATE_ORIGINAL}"
    else
        : > "${STATE_NO_ORIGINAL}"
        chmod 600 "${STATE_NO_ORIGINAL}"
    fi
}

generate_override() {
    local vendor_dec="$1" product_dec="$2" profile="$3" token="$4"
    local generated_file data default_ppmm

    generated_file="${TMP_DIR}/${token}.plist"

    cat > "${generated_file}" <<PLIST_HEAD
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>DisplayProductID</key>
    <integer>${product_dec}</integer>
    <key>DisplayVendorID</key>
    <integer>${vendor_dec}</integer>
    <key>scale-resolutions</key>
    <array>
PLIST_HEAD

    while IFS= read -r data; do
        [[ -n "${data}" ]] || continue
        printf '        <data>%s</data>\n' "${data}" >> "${generated_file}"
    done < <(profile_payload "${profile}")

    default_ppmm="$(profile_default_ppmm "${profile}")"

    cat >> "${generated_file}" <<PLIST_END
    </array>
    <key>target-default-ppmm</key>
    <real>${default_ppmm}</real>
</dict>
</plist>
PLIST_END

    if command -v plutil >/dev/null 2>&1; then
        plutil -lint "${generated_file}" >/dev/null || fail "The generated system configuration failed validation. / 生成的系统配置校验失败。"
    fi
    printf '%s' "${generated_file}"
}

install_detected_displays() {
    local vendor_hex vendor_dec product_hex product_dec profile token
    local path_vendor_hex target_dir target_file generated_file index

    index=0
    while IFS='|' read -r vendor_hex vendor_dec product_hex product_dec profile token; do
        index=$((index + 1))
        path_vendor_hex="$(override_id_hex "${vendor_hex}")"
        target_dir="${OVERRIDES_ROOT}/DisplayVendorID-${path_vendor_hex}"
        target_file="${target_dir}/DisplayProductID-${product_hex}"

        prepare_state "${target_file}" "${token}"
        generated_file="$(generate_override "${vendor_dec}" "${product_dec}" "${profile}" "${token}")"

        if sudo test -f "${target_file}" && sudo cmp -s "${generated_file}" "${target_file}"; then
            log "The optimized configuration for device ${index} already exists. / 设备 ${index} 的优化配置已存在。"
        else
            sudo mkdir -p "${target_dir}"
            sudo chown root:wheel "${target_dir}"
            sudo chmod 0755 "${target_dir}"
            sudo install -o root -g wheel -m 0644 "${generated_file}" "${target_file}"
            log "The optimized configuration for device ${index} was written. / 设备 ${index} 的优化配置已写入。"
        fi
    done < "${DETECTED_FILE}"

    sudo defaults write /Library/Preferences/com.apple.windowserver DisplayResolutionEnabled -bool YES
}

main() {
    require_macos
    printf '\nEnable HiDPI on XREAL Glasses / XREAL Glasses HiDPI 配置工具\n\n'
    request_admin_permission
    detect_supported_displays
    install_detected_displays
    printf '\n'
    log "Installation is complete. Restart your Mac. / 安装完成，请重启 Mac。"
    log "After restarting, select the new HiDPI option in System Settings > Displays. / 重启后在“系统设置 > 显示器”中选择新增的 HiDPI 选项。"
    log "To restore, run uninstall-hidpi.command in this folder. / 需要恢复时运行同目录下的 uninstall-hidpi.command。"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
