#############################################################
#
# oprofile
#
#############################################################

OPROFILE_VERSION=0.9.4
OPROFILE_SOURCE=oprofile-$(OPROFILE_VERSION).tar.gz
OPROFILE_SITE=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/oprofile
OPROFILE_DIR=$(BUILD_DIR)/oprofile-$(OPROFILE_VERSION)
OPROFILE_CAT:=zcat

OPT_TARGET_DIR:=$(TARGET_DIR)/opt
OPROFILE_TARGET_DIR:=$(OPT_TARGET_DIR)/usr

$(DL_DIR)/$(OPROFILE_SOURCE):
	$(WGET) -P $(DL_DIR) $(OPROFILE_SITE)/$(OPROFILE_SOURCE)

$(OPROFILE_DIR)/.unpacked: $(DL_DIR)/$(OPROFILE_SOURCE)
	$(OPROFILE_CAT) $(DL_DIR)/$(OPROFILE_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(OPROFILE_DIR)/.unpacked

	# Allow oprofile patches.
	toolchain/patch-kernel.sh $(OPROFILE_DIR) package/oprofile oprofile\*.patch
	touch $(OPROFILE_DIR)/.unpacked

$(OPROFILE_DIR)/.configured: $(OPROFILE_DIR)/.unpacked
	(cd $(OPROFILE_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(OPROFILE_TARGET_DIR) \
		--sysconfdir=/etc \
		$(DISABLE_NLS) \
		--with-kernel-support \
		--with-extra-includes=$(TARGET_DIR)/usr/include:$(GDB_DIR)/include/:$(GDB_TARGET_DIR)/bfd/ \
		--with-extra-libs=$(TARGET_DIR)/usr/lib:$(GDB_TARGET_DIR)/bfd/ \
		--disable-shared \
		--enable-abi \
	);
	touch $(OPROFILE_DIR)/.configured

$(OPROFILE_DIR)/daemon/oprofiled: $(OPROFILE_DIR)/.configured
	rm -f $@
	$(MAKE) CC=$(TARGET_CC) -C $(OPROFILE_DIR)

$(OPROFILE_DIR)/.installed: $(OPROFILE_DIR)/daemon/oprofiled
	$(MAKE) prefix=$(OPROFILE_TARGET_DIR) -C $(OPROFILE_DIR) install
	install -d $(TARGET_DIR)/dev/oprofile
	touch $(OPROFILE_DIR)/.installed

#oprofile:	uclibc binutils_target libpopt $(OPROFILE_DIR)/.installed
oprofile:	gdb_target popt $(OPROFILE_DIR)/.installed

oprofile-source: $(DL_DIR)/$(OPROFILE_SOURCE)

oprofile-clean:
	@if [ -f $(OPROFILE_DIR)/Makefile ] ; then \
		$(MAKE) -C $(OPROFILE_DIR) prefix=$(OPROFILE_TARGET_DIR) uninstall clean; \
	fi;

oprofile-dirclean:
	rm -rf $(OPROFILE_DIR) $(OPROFILE_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_OPROFILE)),y)
TARGETS+=oprofile
endif
