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

ENABLE_VIRTUAL_AB := true
AB_OTA_POSTINSTALL_CONFIG += \
    RUN_POSTINSTALL_system=true \
    POSTINSTALL_PATH_system=system/bin/ \
    FILESYSTEM_TYPE_system=ext4 \
    POSTINSTALL_OPTIONAL_system=true

PRODUCT_PACKAGES += \
    otapreopt_script \
    cppreopts.sh \
    update_engine \
    update_verifier \
    update_engine_sideload
