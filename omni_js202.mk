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

DEVICE_MATRIX_FILE   := $(DEVICE_PATH)/compatibility_matrix.xml
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRIVATE_BUILD_DESC="TAB-A05-BA1-user 9 01.00.000 01.00.000 release-keys"

BUILD_FINGERPRINT := benesse/TAB-A05-BA1/TAB-A05-BD:9/01.00.000/01.00.000:user/release-keys
