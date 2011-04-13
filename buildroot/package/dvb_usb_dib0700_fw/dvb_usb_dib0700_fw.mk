#############################################################
#
# dvb_usb_dib0700_fw
#
#############################################################
DVB_USB_DIB0700_FW_VERSION:=1.20
DVB_USB_DIB0700_FW_BINARY:=dvb-usb-dib0700-$(DVB_USB_DIB0700_FW_VERSION).fw
DVB_USB_DIB0700_FW_DIR:=package/dvb_usb_dib0700_fw/$(DVB_USB_DIB0700_FW_BINARY)

$(TARGET_DIR)/lib/firmware/$(DVB_USB_DIB0700_FW_BINARY):
	mkdir -p $(TARGET_DIR)/lib/firmware
	cp -dpf $(DVB_USB_DIB0700_FW_DIR) $(TARGET_DIR)/lib/firmware/

dvb_usb_dib0700_fw: $(TARGET_DIR)/lib/firmware/$(DVB_USB_DIB0700_FW_BINARY)

dvb_usb_dib0700_fw-clean:
	rm -f $(TARGET_DIR)/lib/firmware/$(DVB_USB_DIB0700_FW_BINARY)

dvb_usb_dib0700_fw-dirclean:
	rm -f $(TARGET_DIR)/lib/firmware/$(DVB_USB_DIB0700_FW_BINARY)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_DVB_USB_DIB0700_FW)),y)
TARGETS+=dvb_usb_dib0700_fw
endif
