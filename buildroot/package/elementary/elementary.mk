#############################################################
#
# elementary
#
#############################################################
ELEMENTARY_VERSION:=0.0.0svn
ELEMENTARY_SOURCE:=elementary-$(ELEMENTARY_VERSION).tar.bz2
ELEMENTARY_SITE:=http://www.enlightenment.org
ELEMENTARY_REPO:=http://svn.enlightenment.org/svn/e/trunk/TMP/st/elementary
ELEMENTARY_DIR:=$(BUILD_DIR)/elementary-$(ELEMENTARY_VERSION)
ELEMENTARY_BINARY:=elementary.a

$(ELEMENTARY_DIR)/repo:
	[ `svn co $(ELEMENTARY_REPO) $(ELEMENTARY_DIR) | tee /dev/stderr | wc -l` -eq 1 ] || touch $(ELEMENTARY_DIR)/.unpacked
	[ -f $(ELEMENTARY_DIR)/.unpacked ] || touch $(ELEMENTARY_DIR)/.unpacked


$(ELEMENTARY_DIR)/Makefile: $(ELEMENTARY_DIR)/.unpacked
	toolchain/patch-kernel.sh $(ELEMENTARY_DIR) package/elementary/ elementary-\*.patch
	(cd $(ELEMENTARY_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		./autogen.sh \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--enable-shared \
		--disable-static \
	)

$(ELEMENTARY_DIR)/.compiled: $(ELEMENTARY_DIR)/Makefile
	$(MAKE) CC=$(TARGET_CC) -C $(ELEMENTARY_DIR) CFLAGS="-ggdb" PATH="/usr/local/bin/:${PATH}"
	touch $@

$(ELEMENTARY_DIR)/.installed: $(ELEMENTARY_DIR)/.compiled
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(ELEMENTARY_DIR) install
	cp -av $(STAGING_DIR)/usr/lib/libelementary.so* $(TARGET_DIR)/usr/lib/
	cp -av $(STAGING_DIR)/usr/bin/elementary* $(TARGET_DIR)/usr/bin/
	cp -av $(STAGING_DIR)/usr/share/elementary $(TARGET_DIR)/usr/share/
	touch $@

elementary: uclibc eina eet evas ecore embryo edje e_dbus $(ELEMENTARY_DIR)/repo $(ELEMENTARY_DIR)/.installed

elementary-source: $(DL_DIR)/$(ELEMENTARY_SOURCE)

elementary-clean:
	$(MAKE) DESTDIR=$(TARGET_DIR) CC=$(TARGET_CC) -C $(ELEMENTARY_DIR) uninstall
	-$(MAKE) -C $(ELEMENTARY_DIR) clean

elementary-dirclean:
	rm -rf $(ELEMENTARY_DIR)

.PHONY:	$(ELEMENTARY_DIR)/repo

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_ELEMENTARY)),y)
TARGETS+=elementary
endif
