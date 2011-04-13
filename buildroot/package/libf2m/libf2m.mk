#############################################################
#
# libf2m
#
#############################################################

LIBF2M_SOURCE_DIR:=../packages/libf2m
LIBF2M_DIR:=$(BUILD_DIR)/libf2m

LIBF2M_TARGET_DIR:=$(TARGET_DIR)

$(LIBF2M_DIR)/.unpacked:
	cp -a $(LIBF2M_SOURCE_DIR) $(BUILD_DIR)
	-$(MAKE) -C $(LIBF2M_DIR) clean
	touch $(LIBF2M_DIR)/.unpacked

$(LIBF2M_DIR)/.compiled: $(LIBF2M_DIR)/.unpacked
	$(MAKE) -C $(LIBF2M_DIR) ARCH=arm CROSS=$(TARGET_CROSS) REL=$(ARCHOS_CONFIG_FLAG) arm/libf2m.so
	touch $(LIBF2M_DIR)/.compiled

$(LIBF2M_TARGET_DIR)/usr/lib/libf2m.so: $(LIBF2M_DIR)/.compiled
	cp -dpf $(LIBF2M_DIR)/arm/libf2m.so $(STAGING_DIR)/usr/lib/
	cp -dpf $(LIBF2M_DIR)/arm/libf2m.so $(LIBF2M_TARGET_DIR)/usr/lib/

libf2m: uclibc $(LIBF2M_TARGET_DIR)/usr/lib/libf2m.so

libf2m-clean:
	-$(MAKE) -C $(LIBF2M_DIR) clean
	-rm $(LIBF2M_DIR)/.unpacked
	-rm $(LIBF2M_TARGET_DIR)/usr/lib/libf2m.so
	-rm $(STAGING_DIR)/usr/lib/libf2m.so

libf2m-dirclean:
	rm -rf $(LIBF2M_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBF2M)),y)
TARGETS+=libf2m
endif
