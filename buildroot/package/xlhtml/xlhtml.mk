#############################################################
#
# xlhtml
#
#############################################################
XLHTML_VERSION:=0.5.1
XLHTML_SOURCE:=xlhtml-$(XLHTML_VERSION)-vd2.tgz
XLHTML_SITE:=http://nebuchadnezzar.zion.cz/download
XLHTML_DIR:=$(BUILD_DIR)/xlhtml-$(XLHTML_VERSION)
XLHTML_CAT:=$(ZCAT)

XLHTML_PREFIX=/opt/usr
XLHTML_BIN:=xlhtml
XLHTML_TARGET_BIN:=$(XLHTML_PREFIX)/bin/xlhtml
PPTHTML_TARGET_BIN:=$(XLHTML_PREFIX)/bin/ppthtml

$(DL_DIR)/$(XLHTML_SOURCE):
	$(WGET) -P $(DL_DIR) $(XLHTML_SITE)/$(XLHTML_SOURCE)

xlhtml-source: $(DL_DIR)/$(XLHTML_SOURCE)

$(XLHTML_DIR)/.unpacked: $(DL_DIR)/$(XLHTML_SOURCE)
	$(XLHTML_CAT) $(DL_DIR)/$(XLHTML_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(XLHTML_DIR)/.unpacked

$(XLHTML_DIR)/.configured: $(XLHTML_DIR)/.unpacked
	(cd $(XLHTML_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(XLHTML_PREFIX) \
	)
	touch $(XLHTML_DIR)/.configured

$(XLHTML_DIR)/$(XLHTML_BIN): $(XLHTML_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(XLHTML_DIR)

$(STAGING_DIR)$(XLHTML_TARGET_BIN): $(XLHTML_DIR)/$(XLHTML_BIN)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)$(XLHTML_PREFIX) -C $(XLHTML_DIR) install

$(TARGET_DIR)$(XLHTML_TARGET_BIN): $(STAGING_DIR)$(XLHTML_TARGET_BIN)
	cp -a $(STAGING_DIR)$(XLHTML_TARGET_BIN) $@
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

$(TARGET_DIR)$(PPTHTML_TARGET_BIN): $(STAGING_DIR)$(XLHTML_TARGET_BIN)
	cp -a $(STAGING_DIR)$(XLHTML_TARGET_BIN) $@
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

xlhtml: uclibc $(TARGET_DIR)$(XLHTML_TARGET_BIN) $(TARGET_DIR)$(PPTHTML_TARGET_BIN)

xlhtml-clean:
	$(MAKE) prefix=$(STAGING_DIR)$(XLHTML_PREFIX) -C $(XLHTML_DIR) uninstall
	$(MAKE) -C $(XLHTML_DIR) clean

xlhtml-dirclean:
	rm -rf $(XLHTML_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_XLHTML)),y)
TARGETS+=xlhtml
endif
