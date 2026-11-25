$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_p.mk)
PRODUCT_FIRST_API_LEVEL := 28
PRODUCT_CHARACTERISTICS := tablet
TARGET_IS_TABLET := true

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mtp,adb \
    ro.vendor.build.security_patch=2021-10-01

PRODUCT_PACKAGES += \
    qcom_decrypt \
    qcom_decrypt_fbe \
    mount_system_root
