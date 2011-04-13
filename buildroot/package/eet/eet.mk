#############################################################
#
# eet
#
#############################################################
EET_VERSION:=1.1.0svn
EET_SOURCE:=eet-$(EET_VERSION).tar.bz2
EET_SITE:=http://www.enlightenment.org
EET_REPO:=http://svn.enlightenment.org/svn/e/trunk/eet
EET_DIR:=$(BUILD_DIR)/eet-$(EET_VERSION)
EET_BINARY:=eet.a

$(EET_DIR)/repo:
	[ `svn co $(EET_REPO) $(EET_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(EET_DIR)/.unpacked
	[ -f $(EET_DIR)/.unpacked ] || touch $(EET_DIR)/.unpacked

$(EET_DIR)/Makefile: $(EET_DIR)/.unpacked
	toolchain/patch-kernel.sh $(EET_DIR) package/eet/ eet-\*.patch
	(cd $(EET_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--includedir=$(STAGING_DIR)/usr/include \
		--enable-shared \
		--disable-static \
	)

$(EET_DIR)/.compiled: $(EET_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(EET_DIR)
	touch $@

$(EET_DIR)/.installed: $(EET_DIR)/.compiled
	$(MAKE) prefix=$(STAGING_DIR) -C $(EET_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libeet.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/eet $(TARGET_DIR)/usr/bin/
	touch $@

eet: uclibc eina $(EET_DIR)/repo $(EET_DIR)/.installed

eet-source: $(DL_DIR)/$(EET_SOURCE)

eet-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(EET_DIR) uninstall
	-$(MAKE) -C $(EET_DIR) clean

eet-dirclean:
	rm -rf $(EET_DIR)

.PHONY:	$(EINA_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_EET)),y)
TARGETS+=eet
endif
