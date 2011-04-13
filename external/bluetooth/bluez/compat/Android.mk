LOCAL_PATH:= $(call my-dir)

BUILD_DUND := true
ifeq ($(BUILD_DUND),true)
#
# dund
#

include $(CLEAR_VARS)

LOCAL_SRC_FILES:= \
        dund.c \
        sdp.c \
        dun.c \
        msdun.c

LOCAL_CFLAGS:= \
        -DVERSION=\"4.47\" \
        -DSTORAGEDIR=\"/data/misc/bluetoothd\" \
        -DCONFIGDIR=\"/etc/bluez\"

LOCAL_C_INCLUDES:= \
        $(LOCAL_PATH)/../common \
        $(LOCAL_PATH)/../include

LOCAL_SHARED_LIBRARIES := \
        libbluetooth

LOCAL_STATIC_LIBRARIES := \
        libbluez-common-static

LOCAL_MODULE_PATH := $(TARGET_OUT_OPTIONAL_EXECUTABLES)
LOCAL_MODULE_TAGS := user
LOCAL_MODULE:=dund

include $(BUILD_EXECUTABLE)
endif

BUILD_PAND := true
ifeq ($(BUILD_PAND),true)


#
# pand
#

include $(CLEAR_VARS)

LOCAL_SRC_FILES:= \
	pand.c bnep.c sdp.c

LOCAL_CFLAGS:= \
	-DVERSION=\"4.47\" -DSTORAGEDIR=\"/data/misc/bluetoothd\" -DNEED_PPOLL -D__ANDROID__

LOCAL_C_INCLUDES:=\
	$(LOCAL_PATH)/../include \
	$(LOCAL_PATH)/../common \

LOCAL_SHARED_LIBRARIES := \
	libbluetooth libcutils

LOCAL_STATIC_LIBRARIES := \
	libbluez-common-static

LOCAL_MODULE_TAGS := $(TARGET_OUT_OPTIONAL_EXECUTABLES)
LOCAL_MODULE_TAGS := user
LOCAL_MODULE:=pand

include $(BUILD_EXECUTABLE)
endif
