#############################################################
#
# Fuse SSH filesystem
#
#############################################################
SSHFS_VERSION:=2.0
SSHFS_SOURCE:=sshfs-fuse-$(SSHFS_VERSION).tar.gz
SSHFS_SITE:=http://downloads.sourceforge.net/fuse
SSHFS_DIR:=$(BUILD_DIR)/sshfs-fuse-$(SSHFS_VERSION)
SSHFS_CAT:=zcat
SSHFS_BINARY:=sshfs
SSHFS_LIBRARY:=sshnodelay

$(DL_DIR)/$(SSHFS_SOURCE):
	$(WGET) -P $(DL_DIR) $(SSHFS_SITE)/$(SSHFS_SOURCE)

$(SSHFS_DIR)/.source: $(DL_DIR)/$(SSHFS_SOURCE)
	zcat $(DL_DIR)/$(SSHFS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(SSHFS_DIR)/.source

$(SSHFS_DIR)/.configured: $(SSHFS_DIR)/.source
	(cd $(SSHFS_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		PKG_CONFIG_PATH="$(STAGING_DIR)/lib/pkgconfig" \
		./configure \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/opt/usr \
		--exec-prefix=/opt/usr \
		--bindir=/opt/usr/bin \
		--sbindir=/opt/usr/sbin \
		--libexecdir=/opt/usr/lib \
		--sysconfdir=/opt/etc \
		--datadir=/opt/usr/share \
		--localstatedir=/opt/var \
		--mandir=/opt/usr/man \
		--infodir=/opt/usr/info \
		--enable-debug \
		$(DISABLE_NLS) \
	);
	touch $(SSHFS_DIR)/.configured;

$(SSHFS_DIR)/$(SSHFS_BINARY): $(SSHFS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) -C $(SSHFS_DIR)

$(STAGING_DIR)/opt/usr/bin/$(SSHFS_BINARY): $(SSHFS_DIR)/$(SSHFS_BINARY)
	$(MAKE) DESTDIR=$(STAGING_DIR) -C $(SSHFS_DIR) install

$(TARGET_DIR)/opt/usr/bin/$(SSHFS_BINARY): $(STAGING_DIR)/opt/usr/bin/$(SSHFS_BINARY)
	#
	# Install SSHFS library
	#
	mkdir -p $(TARGET_DIR)/opt/usr/lib
	cp -a  $(STAGING_DIR)/opt/usr/lib/$(SSHFS_LIBRARY).so* $(TARGET_DIR)/opt/usr/lib/
	$(STRIPCMD) $(TARGET_DIR)/usr/bin/$(SSHFS_LIBRARY).so*
	#
	# Install SSHFS binary
	#
	mkdir -p $(TARGET_DIR)/opt/usr/sbin
	cp -a $(STAGING_DIR)/opt/usr/bin/$(SSHFS_BINARY) $(TARGET_DIR)/opt/usr/bin/
	$(STRIPCMD) $(TARGET_DIR)/opt/usr/bin/$(SSHFS_BINARY)

sshfs: uclibc fuse openssh $(TARGET_DIR)/opt/usr/bin/$(SSHFS_BINARY)

sshfs-source: $(DL_DIR)/$(SSHFS_SOURCE)

sshfs-uninstall:
	#
	# Remove SSHFS binary
	#
	rm -f $(TARGET_DIR)/opt/usr/bin/$(SSHFS_BINARY)
	#
	# Remove SSHFS library
	#
	rm -f $(TARGET_DIR)/opt/usr/lib/$(SSHFS_LIBRARY).so*

sshfs-clean: sshfs-uninstall
	-$(MAKE) -C $(SSHFS_DIR) clean

sshfs-dirclean:
	rm -rf $(SSHFS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_SSHFS)),y)
TARGETS+=sshfs
endif

