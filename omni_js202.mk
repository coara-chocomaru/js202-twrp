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
$(call inherit-product, device/kyocera/js202/device.mk)

PRODUCT_DEVICE := js202
PRODUCT_NAME := omni_js202
PRODUCT_BRAND := JUSTSYSTEMS
PRODUCT_MODEL := js202
PRODUCT_MANUFACTURER := kyocera
PRODUCT_DEFAULT_LANGUAGE := ja
PRODUCT_DEFAULT_REGION   := JP
PRODUCT_GMS_CLIENTID_BASE := android-kyocera

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="SZJ202-user 9 1.110JS.0151.a 1.110JS.0151.a release-keys"

BUILD_FINGERPRINT := JUSTSYSTEMS/SZJ202/SZJ202:9/1.110JS.0151.a/1.110JS.0151.a:user/release-keys
