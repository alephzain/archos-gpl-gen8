#############################################################
#
# libvformat
#
#############################################################

LIBVFORMAT_VER:=1.13
LIBVFORMAT_DIR:=$(BUILD_DIR)/libvformat-$(LIBVFORMAT_VER)
LIBVFORMAT_SOURCE:=libvformat-$(LIBVFORMAT_VER).tar.bz2
LIBVFORMAT_SITE:=http://mesh.dl.sourceforge.net/sourceforge/vformat
LIBVFORMAT_UNZIP=bzcat
LIBVFORMAT_CAT:=$(BZCAT)
LIBVFORMAT_BINARY:=libvformat

$(DL_DIR)/$(LIBVFORMAT_SOURCE):
	svn update $@

libvformat-source: $(DL_DIR)/$(LIBVFORMAT_SOURCE)

$(LIBVFORMAT_DIR)/.unpacked: $(DL_DIR)/$(LIBVFORMAT_SOURCE)
	$(LIBVFORMAT_UNZIP) $(DL_DIR)/$(LIBVFORMAT_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	# Allow libpng patches.
	toolchain/patch-kernel.sh $(LIBVFORMAT_DIR) package/libvformat \*.patch
	touch $(LIBVFORMAT_DIR)/.unpacked

$(LIBVFORMAT_DIR)/.configured: $(LIBVFORMAT_DIR)/.unpacked
	( \
		cd $(LIBVFORMAT_DIR) ; \
		$(TARGET_CONFIGURE_OPTS) \
		 CFLAGS="${TARGET_CFLAGS}" \
		./configure --prefix=$(STAGING_DIR) --host=$(GNU_TARGET_NAME);\
	)
	touch $(LIBVFORMAT_DIR)/.configured

$(LIBVFORMAT_DIR)/.compiled: $(LIBVFORMAT_DIR)/.configured
	$(MAKE) -C $(LIBVFORMAT_DIR)
	touch $(LIBVFORMAT_DIR)/.compiled

$(eval $(call MD5_DIGEST_template,libvformat,$(DL_DIR)/$(LIBVFORMAT_SOURCE),package/libvformat))

#ifeq ($(libvformat_md5),$(libvformat_new_md5))
# already there, nothing to do
#$(STAGING_DIR)/lib/libvformat.so:
#	@echo " * not recompiling libvformat in staging_dir"
#else
# compile it, and let us know for next time
$(STAGING_DIR)/lib/libvformat.so: $(LIBVFORMAT_DIR)/.compiled
	-$(MAKE) -C $(LIBVFORMAT_DIR) install
	touch -c $(STAGING_DIR)/lib/libvformat.so
	$(Refresh_libvformat_md5)
#endif

$(TARGET_DIR)/usr/lib/libvformat.so: $(STAGING_DIR)/lib/libvformat.so
	cp -af $(STAGING_DIR)/lib/libvformat.so* $(TARGET_DIR)/usr/lib/
	-$(STRIP) --strip-unneeded $(TARGET_DIR)/usr/lib/libvformat.so

libvformat: uclibc $(TARGET_DIR)/usr/lib/libvformat.so

libvformat-clean:
	$(Clean_libvformat_md5)
	-$(MAKE) -C $(LIBVFORMAT_DIR) clean

libvformat-dirclean:
	$(Clean_libvformat_md5)
	rm -rf $(LIBVFORMAT_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBVFORMAT)),y)
TARGETS+=libvformat
endif
