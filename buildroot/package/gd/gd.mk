#############################################################
#
# gd
#
#############################################################
GD_VERSION:=2.0.35
GD_SOURCE:=gd-$(GD_VERSION).tar.gz
GD_SITE:=http://www.libgd.org/releases
GD_DIR:=$(BUILD_DIR)/gd-$(GD_VERSION)
GD_CAT:=$(ZCAT)

GD_PREFIX=/opt/usr
GD_LIB:=.libs/libgd.so.2.0.0
GD_TARGET_LIB:=$(GD_PREFIX)/lib/libgd.so.2.0.0

$(DL_DIR)/$(GD_SOURCE):
	$(WGET) -P $(DL_DIR) $(GD_SITE)/$(GD_SOURCE)

gd-source: $(DL_DIR)/$(GD_SOURCE)

$(GD_DIR)/.unpacked: $(DL_DIR)/$(GD_SOURCE)
	$(GD_CAT) $(DL_DIR)/$(GD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(GD_DIR)/.unpacked

$(GD_DIR)/.configured: $(GD_DIR)/.unpacked
	(cd $(GD_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(GD_PREFIX) \
		--libdir=$(STAGING_DIR)$(GD_PREFIX)/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--without-xpm \
		--without-test \
		--without-x \
	)
	touch $(GD_DIR)/.configured

$(GD_DIR)/$(GD_LIB): $(GD_DIR)/.configured
	$(MAKE) $(TARGET_CONFIGURE_OPTS) -C $(GD_DIR)

$(STAGING_DIR)$(GD_TARGET_LIB): $(GD_DIR)/$(GD_LIB)
	$(MAKE) $(TARGET_CONFIGURE_OPTS) prefix=$(STAGING_DIR)$(GD_PREFIX) -C $(GD_DIR) install
	rm -f $(STAGING_DIR)$(GD_PREFIX)/lib/libgd.la 

$(TARGET_DIR)$(GD_TARGET_LIB): $(STAGING_DIR)$(GD_TARGET_LIB)
	cp -av $(STAGING_DIR)$(GD_PREFIX)/lib/libgd.so* $(TARGET_DIR)$(GD_PREFIX)/lib/
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $@

gd: uclibc jpeg libpng fontconfig $(TARGET_DIR)$(GD_TARGET_LIB)

gd-clean:
	$(MAKE) prefix=$(STAGING_DIR)$(GD_PREFIX) -C $(GD_DIR) uninstall
	rm -f $(TARGET_DIR)$(GD_PREFIX)/lib/libgd.so*
	$(MAKE) -C $(GD_DIR) clean

gd-dirclean:
	rm -rf $(GD_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_GD)),y)
TARGETS+=gd
endif
