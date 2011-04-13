#############################################################
#
# libarchos_support 
#
#############################################################
LAS_SOURCE_DIR:=../packages/libarchos_support
LAS_DIR:=$(BUILD_DIR)/libarchos_support

# This file is used to configure the way we build libarchos_support
LAS_CONF_MK:=conf.mk

LAS_FINAL_CONF_MK:=$(LAS_DIR)/conf.mk

LAS_TARGET_DIR:=$(TARGET_DIR)
LAS_PREFIX=/opt/usr

$(LAS_DIR)/.unpacked:
	rm -rf $(LAS_DIR)
	cp -a $(LAS_SOURCE_DIR) $(BUILD_DIR)
	-$(MAKE) -C $(LAS_DIR) clean
	-rm $(LAS_FINAL_CONF_MK)
	touch $(LAS_DIR)/.unpacked

libarchos_support-source: $(LAS_DIR)/.unpacked

$(LAS_DIR)/.configured: $(LAS_DIR)/.unpacked
	echo "PREFIX=$(LAS_PREFIX)"                           >> $(LAS_FINAL_CONF_MK)
	echo "ARCH=$(ARCH)"                                   >> $(LAS_FINAL_CONF_MK)
	echo "BUILD_DIR=$(BUILD_DIR)"                         >> $(LAS_FINAL_CONF_MK)
	echo "STAGING_DIR=$(STAGING_DIR)"                     >> $(LAS_FINAL_CONF_MK)
	echo "BR2_QTE_VERSION=$(BR2_QTE_VERSION)"             >> $(LAS_FINAL_CONF_MK)
	echo "BR2_QTE_TMAKE_VERSION=$(BR2_QTE_TMAKE_VERSION)" >> $(LAS_FINAL_CONF_MK)
	cat package/libarchos_support/$(LAS_CONF_MK)          >> $(LAS_FINAL_CONF_MK)
	touch  $(LAS_DIR)/.configured

$(LAS_DIR)/.compiled: $(LAS_DIR)/.configured
	$(MAKE) -C $(LAS_DIR)
	touch $(LAS_DIR)/.compiled

$(STAGING_DIR)$(LAS_PREFIX)/lib/libarchos_support.so: $(LAS_DIR)/.compiled
	$(MAKE) -C $(LAS_DIR) install DESTDIR=$(STAGING_DIR)
	touch -c $(STAGING_DIR)$(LAS_PREFIX)/lib/libarchos_support.so

$(LAS_TARGET_DIR)$(LAS_PREFIX)/lib/libarchos_support.so: $(STAGING_DIR)$(LAS_PREFIX)/lib/libarchos_support.so
	mkdir -p $(LAS_TARGET_DIR)$(LAS_PREFIX)/lib
	cp -dpf $(STAGING_DIR)$(LAS_PREFIX)/lib/libarchos_support*so* $(LAS_TARGET_DIR)$(LAS_PREFIX)/lib/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(LAS_TARGET_DIR)$(LAS_PREFIX)/lib/libarchos_support.so

libarchos_support: qte $(LAS_TARGET_DIR)$(LAS_PREFIX)/lib/libarchos_support.so

libarchos_support-clean:
	-$(MAKE) DESTDIR=$(STAGING_DIR) -C $(LAS_DIR) uninstall
	-rm $(LAS_TARGET_DIR)$(LAS_PREFIX)/lib/libarchos_support*
	-$(MAKE) -C $(LAS_DIR) clean

libarchos_support-dirclean:
	rm -rf $(LAS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBARCHOS_SUPPORT)),y)
TARGETS+=libarchos_support
endif
