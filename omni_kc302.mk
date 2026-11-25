#
# Copyright (C) 2024 The Android Open Source Project
# Copyright (C) 2024 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Inherit some common Omni stuff.
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit from a05bd device
$(call inherit-product, device/kyocera/kc302/device.mk)

PRODUCT_DEVICE := kc302
PRODUCT_NAME := omni_kc302
PRODUCT_BRAND := KYOCERA
PRODUCT_MODEL := KC-T302DT
PRODUCT_MANUFACTURER := kyocera
PRODUCT_DEFAULT_LANGUAGE := ja
PRODUCT_DEFAULT_REGION   := JP
PRODUCT_GMS_CLIENTID_BASE := android-kyocera

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="KC-T302DT-user 9 1.090KC.0100.a 1.090KC.0100.a release-keys"
    
BUILD_FINGERPRINT := KYOCERA/KC-T302DT/KC-T302DT:9/1.090KC.0100.a/1.090KC.0100.a:user/release-keys
