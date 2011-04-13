#############################################################
#
# djmount
#
#############################################################
DJMOUNT_VERSION:=0.71
DJMOUNT_SOURCE:=djmount-$(DJMOUNT_VERSION).tar.gz
DJMOUNT_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/djmount
DJMOUNT_DIR:=$(BUILD_DIR)/djmount-$(DJMOUNT_VERSION)
DJMOUNT_CAT:=$(ZCAT)
DJMOUNT_BINARY:=djmount/djmount
DJMOUNT_TARGET_BINARY:=usr/bin/djmount

$(DL_DIR)/$(DJMOUNT_SOURCE):
	$(WGET) -P $(DL_DIR) $(DJMOUNT_SITE)/$(DJMOUNT_SOURCE)

$(DJMOUNT_DIR)/.unpacked: $(DL_DIR)/$(DJMOUNT_SOURCE)
	$(DJMOUNT_CAT) $(DL_DIR)/$(DJMOUNT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(DJMOUNT_DIR) package/djmount/ djmount-$(DJMOUNT_VERSION)\*.patch\*
	touch $@

$(DJMOUNT_DIR)/Makefile: $(DJMOUNT_DIR)/.unpacked
	(cd $(DJMOUNT_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_ARGS) \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS) -D_GNU_SOURCE" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--with-fuse-prefix=$(STAGING_DIR)/usr \
		--with-external-libupnp \
	)

$(DJMOUNT_DIR)/$(DJMOUNT_BINARY): $(DJMOUNT_DIR)/Makefile
	$(MAKE) -C $(DJMOUNT_DIR)

$(TARGET_DIR)/$(DJMOUNT_TARGET_BINARY): $(DJMOUNT_DIR)/$(DJMOUNT_BINARY)
	$(INSTALL) -m 755 $(DJMOUNT_DIR)/$(DJMOUNT_BINARY) $(TARGET_DIR)/$(DJMOUNT_TARGET_BINARY)
	-$(STRIPCMD) $(STRIP_STRIP_UNNEEDED) $(TARGET_DIR)/$(DJMOUNT_TARGET_BINARY)
	touch -c $@

djmount: uclibc fuse libupnp $(TARGET_DIR)/$(DJMOUNT_TARGET_BINARY)

djmount-clean:
	rm -f $(TARGET_DIR)/$(DJMOUNT_TARGET_BINARY)
	-$(MAKE) -C $(DJMOUNT_DIR) clean

djmount-dirclean:
	rm -rf $(DJMOUNT_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_DJMOUNT)),y)
TARGETS+=djmount
endif
