#############################################################
#
# dvbsnoop
#
#############################################################
DVBSNOOP_VERSION:=cvs-03042008
DVBSNOOP_SOURCE:=dvbsnoop-$(DVBSNOOP_VERSION).tar.gz
DVBSNOOP_CAT:=$(ZCAT)
DVBSNOOP_DIR:=$(BUILD_DIR)/dvbsnoop-$(DVBSNOOP_VERSION)
DVBSNOOP_BINARY:=dvbsnoop

dvbsnoop-source: $(DL_DIR)/$(DVBSNOOP_SOURCE)

dvbsnoop-unpacked: $(DVBSNOOP_DIR)/.unpacked

$(DVBSNOOP_DIR)/.unpacked: $(DL_DIR)/$(DVBSNOOP_SOURCE)
	$(DVBSNOOP_CAT) $(DL_DIR)/$(DVBSNOOP_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(DVBSNOOP_DIR) package/dvbsnoop/ \*.patch
	touch $(DVBSNOOP_DIR)/.unpacked

$(DVBSNOOP_DIR)/.configured: $(DVBSNOOP_DIR)/.unpacked
	(cd $(DVBSNOOP_DIR); \
		rm -rf config.cache; \
		./autogen.sh; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
	)
	touch $(DVBSNOOP_DIR)/.configured

$(DVBSNOOP_DIR)/src/$(DVBSNOOP_BINARY): $(DVBSNOOP_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(DVBSNOOP_DIR)

$(STAGING_DIR)/usr/bin/$(DVBSNOOP_BINARY): $(DVBSNOOP_DIR)/src/$(DVBSNOOP_BINARY)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(DVBSNOOP_DIR) install

$(TARGET_DIR)/usr/bin/$(DVBSNOOP_BINARY): $(STAGING_DIR)/usr/bin/$(DVBSNOOP_BINARY)
	install -m 755 $(STAGING_DIR)/usr/bin/$(DVBSNOOP_BINARY) $(TARGET_DIR)/usr/bin/$(DVBSNOOP_BINARY)
	$(STRIPCMD) $@

dvbsnoop: uclibc $(TARGET_DIR)/usr/bin/$(DVBSNOOP_BINARY)

dvbsnoop-clean:
	rm -f $(TARGET_DIR)/usr/bin/$(DVBSNOOP_BINARY)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(DVBSNOOP_DIR) uninstall
	$(MAKE) -C $(DVBSNOOP_DIR) clean

dvbsnoop-dirclean:
	rm -rf $(DVBSNOOP_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_DVBSNOOP)),y)
TARGETS+=dvbsnoop
endif
