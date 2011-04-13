#############################################################
#
# fuse
#
#############################################################
FUSE_VERSION=2.6.0
FUSE_SOURCE:=fuse-$(FUSE_VERSION).tar.gz
FUSE_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/fuse/
FUSE_DIR:=$(BUILD_DIR)/fuse-$(FUSE_VERSION)
FUSE_CAT:=zcat

FUSE_TARGET_DIR:=$(TARGET_DIR)

$(DL_DIR)/$(FUSE_SOURCE):
	 $(WGET) -P $(DL_DIR) $(FUSE_SITE)/$(FUSE_SOURCE)

fuse-source: $(DL_DIR)/$(FUSE_SOURCE)

$(FUSE_DIR)/.unpacked: $(DL_DIR)/$(FUSE_SOURCE)
	$(FUSE_CAT) $(DL_DIR)/$(FUSE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	# removed mknods this is now done via buildroot/fakeroot
	#cp package/fuse/Makefile.in.util $(FUSE_DIR)/util/Makefile.in
	toolchain/patch-kernel.sh $(FUSE_DIR) package/fuse/ \*.patch
	touch $(FUSE_DIR)/.unpacked

$(FUSE_DIR)/.configured: $(FUSE_DIR)/.unpacked
	(cd $(FUSE_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		MOUNT_FUSE_PATH=$(STAGING_DIR)/sbin \
		UDEV_RULES_PATH=$(STAGING_DIR)/etc \
		INIT_D_PATH=$(STAGING_DIR)/etc/init.d \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--disable-mtab \
		--disable-example \
		--disable-shared \
		--disable-kernel-module \
		--program-prefix="" \
		--prefix=/usr \
		--bindir=$(STAGING_DIR)/usr/bin \
		--sbindir=$(STAGING_DIR)/sbin \
		--libdir=$(STAGING_DIR)/usr/lib \
		--sysconfdir=$(STAGING_DIR)/etc \
	);
	touch  $(FUSE_DIR)/.configured

$(FUSE_DIR)/.compiled: $(FUSE_DIR)/.configured
	( export PATH=$(STAGING_DIR)/bin:$(PATH) ; $(MAKE) -C $(FUSE_DIR) )
	touch $(FUSE_DIR)/.compiled

$(FUSE_DIR)/.installed: $(FUSE_DIR)/.compiled
	( export PATH=$(STAGING_DIR)/bin:$(PATH) ;\
	$(MAKE) prefix=$(STAGING_DIR) -C $(FUSE_DIR) install )
	touch $(FUSE_DIR)/.installed

$(FUSE_DIR)/.deployed : $(FUSE_DIR)/.installed
	#cp -dpf $(STAGING_DIR)/usr/lib/libfuse.so* $(FUSE_TARGET_DIR)/usr/lib/
	install -D $(STAGING_DIR)/sbin/mount.fuse $(FUSE_TARGET_DIR)/usr/sbin/mount.fuse
	install -D $(STAGING_DIR)/usr/bin/fusermount $(FUSE_TARGET_DIR)/usr/bin/fusermount
	install -d $(FUSE_DIR)
	touch $(FUSE_DIR)/.deployed

fuse: uclibc $(FUSE_DIR)/.deployed

fuse-clean:
	$(Clean_fuse_md5)
	-$(MAKE) DESTDIR=$(FUSE_TARGET_DIR) -C $(FUSE_DIR) uninstall
	-rm $(TARGET_DIR)/usr/lib/libfuse.so.$(FUSE_VERSION)
	-rm $(STAGING_DIR)/usr/lib/libfuse.*
	-$(MAKE) -C $(FUSE_DIR) clean
	-rm $(FUSE_DIR)/.deployed $(FUSE_DIR)/.installed $(FUSE_DIR)/.compiled $(FUSE_DIR)/.configured

fuse-dirclean: fuse-clean
	$(Clean_fuse_md5)
	rm -rf $(FUSE_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_FUSE)),y)
TARGETS+=fuse
endif
