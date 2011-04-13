#############################################################
#
# libmms
#
#############################################################

LIBMMS_SOURCE_DIR:=../packages/libmms
LIBMMS_DIR:=$(BUILD_DIR)/libmms

LIBMMS_TARGET_DIR:=$(TARGET_DIR)

$(LIBMMS_DIR)/.unpacked:
	cp -a $(LIBMMS_SOURCE_DIR) $(BUILD_DIR)
	-$(MAKE) -C $(LIBMMS_DIR) clean
	touch $(LIBMMS_DIR)/.unpacked

$(LIBMMS_DIR)/.compiled: $(LIBMMS_DIR)/.unpacked
	$(MAKE) -C $(LIBMMS_DIR) ARCH=arm CROSS=$(TARGET_CROSS) REL=$(ARCHOS_CONFIG_FLAG) arm/libmms.so
	touch $(LIBMMS_DIR)/.compiled

$(LIBMMS_TARGET_DIR)/usr/lib/libmms.so: $(LIBMMS_DIR)/.compiled
	cp -dpf $(LIBMMS_DIR)/arm/libmms.so $(STAGING_DIR)/usr/lib/
	cp -dpf $(LIBMMS_DIR)/arm/libmms.so $(LIBMMS_TARGET_DIR)/usr/lib/

libmms: uclibc $(LIBMMS_TARGET_DIR)/usr/lib/libmms.so

libmms-clean:
	-$(MAKE) -C $(LIBMMS_DIR) clean
	-rm $(LIBMMS_DIR)/.unpacked
	-rm $(LIBMMS_TARGET_DIR)/usr/lib/libmms.so
	-rm $(STAGING_DIR)/usr/lib/libmms.so

libmms-dirclean:
	rm -rf $(LIBMMS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBMMS)),y)
TARGETS+=libmms
endif
