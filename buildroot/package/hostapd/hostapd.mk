HOSTAPD_SOURCE_DIR:=../packages/hostapd
HOSTAPD_DIR:=$(BUILD_DIR)/hostapd

$(HOSTAPD_DIR)/.prepared:
	cp -a $(HOSTAPD_SOURCE_DIR) $(BUILD_DIR)
	cd $(HOSTAPD_DIR) ; \
	echo "CONFIG_RSN_PREAUTH=y" > .config ; \
	echo "CONFIG_DRIVER_TEST=y" >> .config
	touch  $(HOSTAPD_DIR)/.prepared

$(HOSTAPD_DIR)/.compiled :  $(HOSTAPD_DIR)/.prepared
	make -C $(HOSTAPD_DIR) CROSS=$(TARGET_CROSS)
	touch  $(HOSTAPD_DIR)/.compiled

hostapd-install : $(HOSTAPD_DIR)/.compiled
	install -m 755 $(HOSTAPD_DIR)/hostapd $(TARGET_DIR)/usr/bin
	install -m 755 $(HOSTAPD_DIR)/hostapd_cli $(TARGET_DIR)/usr/bin

hostapd : hostapd-install

hostapd-clean:
	make -C $(HOSTAPD_DIR) clean
	rm -f $(HOSTAPD_DIR)/.prepared
	rm -f $(HOSTAPD_DIR)/.compiled

hostapd-dirclean:
	-rm -rf $(HOSTAPD_DIR)
	
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_HOSTAPD)),y)
TARGETS+=hostapd
endif
