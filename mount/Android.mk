LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := mount_system_root
LOCAL_MODULE_STEM := mount_system_root
LOCAL_MODULE_TAGS := eng
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(TARGET_RECOVERY_ROOT_OUT)/sbin

LOCAL_SRC_FILES := mount_system_root.c

LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_MULTILIB := 64

LOCAL_STATIC_LIBRARIES := \
    libc

LOCAL_CFLAGS := \
    -Os \
    -ffunction-sections \
    -fdata-sections \
    -fno-stack-protector \
    -fno-unwind-tables \
    -fno-asynchronous-unwind-tables

LOCAL_LDFLAGS := \
    -Wl,--gc-sections

LOCAL_STRIP_MODULE := true

include $(BUILD_EXECUTABLE)
