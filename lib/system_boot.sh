#!/bin/bash
#################################################################################################
# 引导与虚拟化信息（新拆分）
#################################################################################################

source "$(dirname "$0")/config.sh" 2>/dev/null || source "./lib/config.sh"
source "$(dirname "$0")/logger.sh" 2>/dev/null || source "./lib/logger.sh"

which_bootfirmware() {
    [ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
}

list_grub_entries() {
    sudo grep -P "^menuentry" /boot/grub2/grub.cfg | cut -d "'" -f2
}

list_support_vmtech() {
    grep -E '^flags.*(vmx|svm)' /proc/cpuinfo
}
