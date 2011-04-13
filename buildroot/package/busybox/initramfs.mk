#############################################################
#
# busybox image for initramfs
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BUSYBOX_INITRAMFS)),y)

BUSYBOX_INITRAMFS_DIR:=$(BUSYBOX_DIR)-initramfs
BR2_INITRAMFS_DIR:=$(PROJECT_BUILD_DIR)/initramfs
BB_INITRAMFS_TARGET:=$(IMAGE).initramfs_lst

ifndef BUSYBOX_STATIC_CONFIG_FILE
BUSYBOX_STATIC_CONFIG_FILE=$(subst ",, $(strip $(BR2_PACKAGE_BUSYBOX_STATIC_CONFIG)))
endif

$(BUSYBOX_INITRAMFS_DIR)/.unpacked: $(DL_DIR)/$(BUSYBOX_SOURCE)
	rm -rf $(BUILD_DIR)/tmp $(BUSYBOX_INITRAMFS_DIR)
	mkdir -p $(BUILD_DIR)/tmp
	$(BUSYBOX_UNZIP) $(DL_DIR)/$(BUSYBOX_SOURCE) | tar -C $(BUILD_DIR)/tmp $(TAR_OPTIONS) -
ifeq ($(strip $(BR2_PACKAGE_BUSYBOX_SNAPSHOT)),y)
	mv $(BUILD_DIR)/tmp/busybox $(BUSYBOX_INITRAMFS_DIR)
else
	mv $(BUILD_DIR)/tmp/busybox-$(BUSYBOX_VERSION) $(BUSYBOX_INITRAMFS_DIR)
endif
	touch $@

$(BUSYBOX_INITRAMFS_DIR)/.config $(BUSYBOX_INITRAMFS_DIR)/.configured: $(BUSYBOX_INITRAMFS_DIR)/.unpacked
	$(MAKE) CC=$(TARGET_CC) CROSS_COMPILE="$(TARGET_CROSS)" \
		CROSS="$(TARGET_CROSS)" -C $(BUSYBOX_INITRAMFS_DIR) \
		allnoconfig
	mv $(BUSYBOX_INITRAMFS_DIR)/.config $(BUSYBOX_INITRAMFS_DIR)/.config.no
	cp -f $(BUSYBOX_STATIC_CONFIG_FILE) $(BUSYBOX_INITRAMFS_DIR)/.config
	cp -f $(BUSYBOX_INITRAMFS_DIR)/.config \
		$(BUSYBOX_INITRAMFS_DIR)/.config.prune
	$(SED) 's|\([^=]*\)=.*|/\1[^_]*/d|g' \
		$(BUSYBOX_INITRAMFS_DIR)/.config.prune
	$(SED) '' -f $(BUSYBOX_INITRAMFS_DIR)/.config.prune \
		$(BUSYBOX_INITRAMFS_DIR)/.config.no
	cat $(BUSYBOX_INITRAMFS_DIR)/.config.no >> \
		$(BUSYBOX_INITRAMFS_DIR)/.config
	$(MAKE) CC=$(TARGET_CC) CROSS_COMPILE="$(TARGET_CROSS)" \
		CROSS="$(TARGET_CROSS)" -C $(BUSYBOX_INITRAMFS_DIR) \
		oldconfig
	touch $@


$(BUSYBOX_INITRAMFS_DIR)/busybox: $(BUSYBOX_INITRAMFS_DIR)/.configured
	$(MAKE) CC=$(TARGET_CC) CROSS_COMPILE="$(TARGET_CROSS)" \
		CROSS="$(TARGET_CROSS)" PREFIX="$(TARGET_DIR)" \
		ARCH=$(KERNEL_ARCH) \
		EXTRA_CFLAGS="$(TARGET_CFLAGS)" -C $(BUSYBOX_INITRAMFS_DIR) \
		busybox.links busybox
ifeq ($(BR2_PREFER_IMA)$(BR2_PACKAGE_BUSYBOX_SNAPSHOT),yy)
	rm -f $@
	$(MAKE) CC=$(TARGET_CC) CROSS_COMPILE="$(TARGET_CROSS)" \
		CROSS="$(TARGET_CROSS)" PREFIX="$(TARGET_DIR)" \
		ARCH=$(KERNEL_ARCH) STRIP="$(STRIPCMD)" \
		EXTRA_CFLAGS="$(TARGET_CFLAGS)" -C $(BUSYBOX_INITRAMFS_DIR) \
		-f scripts/Makefile.IMA
endif

$(BR2_INITRAMFS_DIR)/bin/busybox: $(BUSYBOX_INITRAMFS_DIR)/busybox
	install -D -m 755 $< $@

$(PROJECT_BUILD_DIR)/.initramfs_done: $(BR2_INITRAMFS_DIR)/bin/busybox
	touch $@

busybox-initramfs-source:
busybox-initramfs: uclibc $(PROJECT_BUILD_DIR)/.initramfs_done

busybox-initramfs-menuconfig: host-sed $(BUILD_DIR) busybox-source $(BUSYBOX_INITRAMFS_DIR)/.configured
	$(MAKE) __TARGET_ARCH=$(ARCH) -C $(BUSYBOX_INITRAMFS_DIR) menuconfig

busybox-initramfs-clean:
	rm -f $(BUSYBOX_INITRAMFS_DIR)/busybox $(PROJECT_BUILD_DIR)/.initramfs_*
	rm -rf $(BR2_INITRAMFS_DIR) $(BB_INITRAMFS_TARGET)
	-$(MAKE) -C $(BUSYBOX_INITRAMFS_DIR) clean

busybox-initramfs-dirclean:
	rm -rf $(BUSYBOX_INITRAMFS_DIR) $(BR2_INITRAMFS_DIR) \
		$(PROJECT_BUILD_DIR)/.initramfs_*
endif
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_BUSYBOX_INITRAMFS)),y)
TARGETS+=busybox-initramfs
endif
