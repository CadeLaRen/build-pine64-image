#!/bin/sh
#
# Simple script to create a U-Boot with all the additional parts which are
# required to be accepted by th A64 boot0.
#
# This script requires build variants and tools from several other sources.
# See the variable definitions below. When all files can be found, a U-Boot
# file is created which can be loaded by A64 boot0 just fine.

set -e

# http://wiki.pine64.org/index.php/Pine_A64_Software_Release
BSP="../lichee"
# https://github.com/longsleep/u-boot-pine64/tree/pine64-hacks
UBOOT="../u-boot-pine64"
# https://github.com/longsleep/arm-trusted-firmware-pine64
TRUSTED_FIRMWARE="../arm-trusted-firmware-pine64"
# https://github.com/longsleep/sunxi-pack-tools
SUNXI_PACK_TOOLS="../sunxi-pack-tools/bin"

BUILD="./out"
mkdir -p $BUILD

cp -v $TRUSTED_FIRMWARE/build/sun50iw1p1/debug/bl31.bin $BUILD
cp -v $UBOOT/u-boot-sun50iw1p1.bin $BUILD/u-boot.bin
cp -v $BSP/tools/pack/chips/sun50iw1p1/bin/scp.bin $BUILD
cp -v $BSP/out/sun50iw1p1/linux/common/sunxi.dtb $BUILD
cp -v $BSP/tools/pack/chips/sun50iw1p1/configs/t1/sys_config.fex $BUILD

unix2dos $BUILD/sys_config.fex
$SUNXI_PACK_TOOLS/script $BUILD/sys_config.fex

# merge_uboot.exe u-boot.bin infile outfile mode[secmonitor|secos|scp]
$SUNXI_PACK_TOOLS/merge_uboot $BUILD/u-boot.bin $BUILD/bl31.bin $BUILD/u-boot-merged.bin secmonitor
$SUNXI_PACK_TOOLS/merge_uboot $BUILD/u-boot-merged.bin $BUILD/scp.bin $BUILD/u-boot-merged2.bin scp

# update_fdt.exe u-boot.bin xxx.dtb output_file.bin
$SUNXI_PACK_TOOLS/update_uboot_fdt $BUILD/u-boot-merged2.bin $BUILD/sunxi.dtb $BUILD/u-boot-with-dtb.bin

# Add fex file to u-boot so it actually is accepted by boot0.
$SUNXI_PACK_TOOLS/update_uboot $BUILD/u-boot-with-dtb.bin $BUILD/sys_config.bin

echo "Done - created $BUILD/u-boot-with-dtb.bin"
