#############################################################
#
# dosfstools 
#
#############################################################
DOSFSTOOLS_VERSION:=2.11
DOSFSTOOLS_SOURCE:=dosfstools_$(DOSFSTOOLS_VERSION).tar.gz
#DOSFSTOOLS_SITE:=http://ftp.uni-erlangen.de/pub/Linux/LOCAL/dosfstools
DOSFSTOOLS_SITE:=https://stage.maemo.org/svn/maemo/projects/haf/tags/dosfstools/2.11-0osso9/
DOSFSTOOLS_DIR:=$(BUILD_DIR)/dosfstools-$(DOSFSTOOLS_VERSION)
DOSFSTOOLS_CAT:=$(ZCAT)

DOSFSTOOLS_CFLAGS=$(TARGET_CFLAGS)
ifeq ($(BR2_LARGEFILE),y)
DOSFSTOOLS_CFLAGS+= -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64
endif

$(DL_DIR)/$(DOSFSTOOLS_SOURCE):
	$(WGET) -P $(DL_DIR) $(DOSFSTOOLS_SITE)/$(DOSFSTOOLS_SOURCE)

$(DOSFSTOOLS_DIR)/.unpacked: $(DL_DIR)/$(DOSFSTOOLS_SOURCE)
	$(DOSFSTOOLS_CAT) $(DL_DIR)/$(DOSFSTOOLS_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	toolchain/patch-kernel.sh $(DOSFSTOOLS_DIR) package/mkdosfs/ \*.diff
	toolchain/patch-kernel.sh $(DOSFSTOOLS_DIR) package/mkdosfs/ \*.patch
	touch $@

ifeq ($(strip $(BR2_PACKAGE_DOSFSTOOLS_MKDOSFS)),y)
DOSFSTOOLS_BUILD_BINARIES+=$(DOSFSTOOLS_DIR)/mkdosfs/mkdosfs
DOSFSTOOLS_TARGET_BINARIES+=$(TARGET_DIR)/sbin/mkdosfs
endif

ifeq ($(strip $(BR2_PACKAGE_DOSFSTOOLS_MKDOSFS_STATIC)),y)
DOSFSTOOLS_BUILD_BINARIES+=$(DOSFSTOOLS_DIR)/mkdosfs/mkdosfs.static
DOSFSTOOLS_TARGET_BINARIES+=$(TARGET_DIR)/sbin/mkdosfs.static
endif

ifeq ($(strip $(BR2_PACKAGE_DOSFSTOOLS_DOSFSCK)),y)
DOSFSTOOLS_BUILD_BINARIES+=$(DOSFSTOOLS_DIR)/dosfsck/dosfsck
DOSFSTOOLS_TARGET_BINARIES+=$(TARGET_DIR)/sbin/dosfsck
endif

ifeq ($(strip $(BR2_PACKAGE_DOSFSTOOLS_DOSFSCK_STATIC)),y)
DOSFSTOOLS_BUILD_BINARIES+=$(DOSFSTOOLS_DIR)/dosfsck/dosfsck.static
DOSFSTOOLS_TARGET_BINARIES+=$(TARGET_DIR)/sbin/dosfsck.static
endif

$(DOSFSTOOLS_BUILD_BINARIES): $(DOSFSTOOLS_DIR)/.unpacked
	$(MAKE) CFLAGS="$(DOSFSTOOLS_CFLAGS)" CC="$(TARGET_CC)" -C $(DOSFSTOOLS_DIR)

$(DOSFSTOOLS_TARGET_BINARIES): $(TARGET_DIR)/sbin/% : $(DOSFSTOOLS_BUILD_BINARIES)
	cp -f $< $@
	$(STRIPCMD) $@

dosfstools: uclibc $(DOSFSTOOLS_TARGET_BINARIES) 

dosfstools-clean:
	-$(MAKE) -C $(DOSFSTOOLS_DIR) clean

dosfstools-dirclean:
	rm -rf $(DOSFSTOOLS_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_DOSFSTOOLS)),y)
TARGETS+=dosfstools
endif

