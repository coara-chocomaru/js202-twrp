$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_p.mk)
PRODUCT_FIRST_API_LEVEL := 28
PRODUCT_CHARACTERISTICS := tablet
TARGET_IS_TABLET := true
LOCAL_PATH := device/kyocera/js202


PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp,adb
