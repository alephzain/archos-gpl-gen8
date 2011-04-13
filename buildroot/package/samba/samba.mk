#############################################################
#
# samba
#
#############################################################
SAMBA_VERSION:=3.0.34
SAMBA_SOURCE:=samba-$(SAMBA_VERSION).tar.gz
SAMBA_SITE:=http://us1.samba.org/samba/ftp/stable/
SAMBA_CAT:=zcat
SAMBA_DIR:=$(BUILD_DIR)/samba-$(SAMBA_VERSION)
SAMBA_FSMON_LIBRARY=sambafsmon.so.1.1.0
SAMBA_TARGET_FSMON_LIBRARY:=usr/lib/$(SAMBA_FSMON_LIBRARY)

#FIXME: OPT_TARGET_DIR needs to be set in buildroot!
OPT_TARGET_DIR:=$(TARGET_DIR)/opt
# samba will be installed on opt-fs
#SAMBA_TARGET_DIR:=$(OPT_TARGET_DIR)
SAMBA_TARGET_DIR:=$(TARGET_DIR)

ifeq ($(ARCH),i586)
SAMBA_ARCH:=SAMBA_X86
else
SAMBA_ARCH:=SAMBA_ARM
endif

# samba_fs_monitor
.PHONY: samba_fs_monitor-install

SFM_SOURCE_DIR:=../packages/samba_fs_monitor
SFM_DIR:=$(BUILD_DIR)/samba_fs_monitor

SFM_TARGET_DIR:=$(SAMBA_TARGET_DIR)

$(SFM_DIR)/.unpacked:
	@-rm -rf $(SFM_DIR) || true
	cp -a $(SFM_SOURCE_DIR) $(SFM_DIR)
	touch $(SFM_DIR)/.unpacked

$(SFM_DIR)/.compiled: $(SFM_DIR)/.unpacked
	(cd $(SFM_DIR); \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include" \
	LDFLAGS="-L$(STAGING_DIR)/lib -L$(STAGING_DIR)/usr/lib \
	  -Wl,-rpath-link,$(STAGING_DIR)/usr/lib \
	  -Wl,-rpath,$(SAMBA_TARGET_DIR)/usr/lib" \
	  $(MAKE) CC=$(TARGET_CC) );
	touch $(SFM_DIR)/.compiled

samba_fs_monitor-install: $(SFM_DIR)/.compiled
	install -D $(SFM_DIR)/sambafsmon.so.1.0.1 $(SFM_TARGET_DIR)/usr/lib/sambafsmon.so.1.0.1
	install -D $(SFM_DIR)/smbdhelper $(SFM_TARGET_DIR)/usr/sbin/smbdhelper

samba_fs_monitor: samba_fs_monitor-install

samba_fs_monitor-clean:
	-$(MAKE) -C $(SFM_DIR) clean
	-rm $(SFM_DIR)/.compiled

samba_fs_monitor-dirclean: samba_fs_monitor-clean
	-rm -rf $(SFM_DIR)


$(DL_DIR)/$(SAMBA_SOURCE):
	$(WGET) -P $(DL_DIR) $(SAMBA_SITE)/$(SAMBA_SOURCE)

samba-source: $(DL_DIR)/$(SAMBA_SOURCE)

$(SAMBA_DIR)/.unpacked: $(DL_DIR)/$(SAMBA_SOURCE)
	$(SAMBA_CAT) $(DL_DIR)/$(SAMBA_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	cp package/samba/wrapper.c $(SAMBA_DIR)/
	toolchain/patch-kernel.sh $(SAMBA_DIR) package/samba/ \*.patch
	touch $@

$(SAMBA_DIR)/.configured: $(SAMBA_DIR)/.unpacked
	(cd $(SAMBA_DIR)/source; \
	$(TARGET_CONFIGURE_OPTS) \
	CPPFLAGS="-D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -D_GNU_SOURCE -D$(SAMBA_ARCH)" \
	CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include -Os" \
	LDFLAGS="-L$(STAGING_DIR)/lib -L$(STAGING_DIR)/usr/lib \
	  -Wl,-rpath-link,$(STAGING_DIR)/usr/lib \
	  -Wl,-rpath,$(SAMBA_TARGET_DIR)/usr/lib" \
	samba_cv_USE_SETRESUID=yes \
	samba_cv_USE_SETRESGID=yes \
	samba_cv_HAVE_IFACE_IFCONF=yes \
	samba_cv_have_longlong=yes \
	samba_cv_HAVE_UNSIGNED_CHAR=yes \
	samba_cv_HAVE_MMAP=yes \
	samba_cv_HAVE_MAKEDEV=yes \
	samba_cv_HAVE_KERNEL_SHARE_MODES=yes \
	samba_cv_HAVE_BROKEN_GETGROUPS=no \
	samba_cv_HAVE_BROKEN_READDIR=no \
	samba_cv_SYSCONF_SC_NGROUPS_MAX=yes \
	samba_cv_SYSCONF_SC_NPROC_ONLN=no \
	samba_cv_HAVE_GETTIMEOFDAY_TZ=yes \
	samba_cv_HAVE_FTRUNCATE_EXTEND=yes \
	samba_cv_HAVE_C99_VSNPRINTF=yes \
	samba_cv_REALPATH_TAKES_NULL=no \
	samba_cv_HAVE_w2=no \
	samba_cv_HAVE_Werror=yes \
	samba_cv_HAVE_KERNEL_CHANGE_NOTIFY=no \
	samba_cv_HAVE_KERNEL_OPLOCKS_LINUX=yes \
	samba_cv_REPLACE_INET_NTOA=no \
	samba_cv_HAVE_WORKING_AF_LOCAL=yes \
	samba_cv_HAVE_DEVICE_MAJOR_FN=yes \
	samba_cv_HAVE_DEVICE_MINOR_FN=yes \
	samba_cv_HAVE_SECURE_MKSTEMP=yes \
	fu_cv_sys_stat_statvfs64=no \
	samba_cv_HAVE_FCNTL_LOCK=yes \
	samba_cv_HAVE_DEV64_T=no \
	samba_cv_HAVE_BROKEN_FCNTL64_LOCKS=no \
	samba_cv_HAVE_INO64_T=no \
	samba_cv_HAVE_OFF64_T=no \
	samba_cv_HAVE_STRUCT_FLOCK64=no \
	samba_cv_HAVE_BROKEN_FCNTL64_LOCKS=yes \
	samba_cv_HAVE_TRUNCATED_SALT=no \
	samba_cv_SIZEOF_OFF_T=no \
	samba_cv_SIZEOF_DEV_T=no \
	samba_cv_SIZEOF_INO_T=no \
	SMB_BUILD_CC_NEGATIVE_ENUM_VALUES=yes \
	./configure \
	--target=$(GNU_TARGET_NAME) \
	--host=$(GNU_TARGET_NAME) \
	--build=$(GNU_HOST_NAME) \
	--sysconfdir=/var/etc/ \
	--localstatedir=/var \
	--prefix=/usr \
	--without-sendfile-support \
	--disable-pie \
	--with-fhs \
	--without-ldap \
	--without-libaddns \
	--without-sys-quotas \
	--without-libmsrpc \
	--without-libsmbsharemodes \
	--disable-cups \
	--disable-iprint \
	--disable-xmltest \
	--without-readline \
	--with-syslog \
	--without-ads ); 
	echo "#define _LARGEFILE64_SOURCE 1" >> $(SAMBA_DIR)/source/include/config.h
	echo "#define _FILE_OFFSET_BITS 64" >> $(SAMBA_DIR)/source/include/config.h
	echo "#define _GNU_SOURCE 1" >> $(SAMBA_DIR)/source/include/config.h
	touch $@

$(SAMBA_DIR)/$(SAMBA_FSMON_LIBRARY): $(SAMBA_DIR)/.unpacked
	$(TARGET_CC) -DLOG_FILE=\"/tmp/samba_write.log\" -fPIC -rdynamic -g -c -Wall $(SAMBA_DIR)/wrapper.c -o $(SAMBA_DIR)/wrapper.o
	$(TARGET_CC) -shared -Wl,-soname,sambafsmon.so.1 -o $(SAMBA_DIR)/$(SAMBA_FSMON_LIBRARY) $(SAMBA_DIR)/wrapper.o -lc -ldl

$(TARGET_DIR)/$(SAMBA_TARGET_FSMON_LIBRARY): $(SAMBA_DIR)/$(SAMBA_FSMON_LIBRARY)
	cp -dpf $(SAMBA_DIR)/$(SAMBA_FSMON_LIBRARY) \
		$(TARGET_DIR)/$(SAMBA_TARGET_FSMON_LIBRARY)

# there were problems with the dynamic libraries on arm
# they went away after disabling PIE.

$(SAMBA_DIR)/.compiled: $(SAMBA_DIR)/.configured
	$(MAKE) -C $(SAMBA_DIR)/source proto # works around a bug in the samba makefile. suggested on smb-dev ml
	$(MAKE) -C $(SAMBA_DIR)/source
	touch $@

$(SAMBA_DIR)/.install/usr/sbin/smbd: $(SAMBA_DIR)/.compiled
	install -d $(SAMBA_DIR)/.install/
	$(MAKE) -C $(SAMBA_DIR)/source DESTDIR=$(SAMBA_DIR)/.install/ install
	touch -c $@

# TODO: i'm not sure if more stuff from /usr/lib/samba/ is needed. will have to be tested.
$(SAMBA_TARGET_DIR)/usr/sbin/smbd: $(SAMBA_DIR)/.install/usr/sbin/smbd
	install -d $(SAMBA_TARGET_DIR)/usr/sbin/ $(SAMBA_TARGET_DIR)/usr/bin/ $(SAMBA_TARGET_DIR)/usr/lib/
	cp -dpf $(SAMBA_DIR)/.install/usr/sbin/smbd $(SAMBA_TARGET_DIR)/usr/sbin/
	cp -dpf $(SAMBA_DIR)/.install/usr/sbin/nmbd $(SAMBA_TARGET_DIR)/usr/sbin/
	cp -dpf $(SAMBA_DIR)/.install/usr/bin/smbpasswd $(SAMBA_TARGET_DIR)/usr/bin/
	cp -dpf $(SAMBA_DIR)/.install/usr/bin/nmblookup $(SAMBA_TARGET_DIR)/usr/bin/
	cp -dpf package/samba/smbpasswdhelper $(SAMBA_TARGET_DIR)/usr/bin/
	cp -dpf $(SAMBA_DIR)/.install/usr/lib/samba/libsmbclient.so $(SAMBA_TARGET_DIR)/usr/lib/
	cp -dpf $(SAMBA_DIR)/.install/usr/lib/samba/libsmbclient.so $(STAGING_DIR)/usr/lib/
	cp -dpf $(SAMBA_DIR)/.install/usr/include/libsmbclient.h $(STAGING_DIR)/usr/include/
	(cd $(SAMBA_TARGET_DIR)/usr/lib/; ln -sf libsmbclient.so libsmbclient.so.0 )
ifeq ($(strip $(BR2_TARGET_ARCHOS_OPT_FS)),y)
	(cd $(TARGET_DIR)/usr/lib/; ln -sf $(SAMBA_TARGET_DIR)/usr/lib/samba samba )
else
	# in case it is a symbolic link, delete it
	-rm $(SAMBA_TARGET_DIR)/usr/lib/samba
endif
	install -d $(SAMBA_TARGET_DIR)/usr/lib/samba/
	cp -dpf $(SAMBA_DIR)/.install/usr/lib/samba/*.dat $(SAMBA_TARGET_DIR)/usr/lib/samba/
	-$(STRIPCMD) --strip-unneeded $(SAMBA_TARGET_DIR)/usr/bin/smbpasswd
	-$(STRIPCMD) --strip-unneeded $(SAMBA_TARGET_DIR)/usr/bin/nmblookup
	-$(STRIPCMD) --strip-unneeded $(SAMBA_TARGET_DIR)/usr/lib/libsmbclient.so
	-$(STRIPCMD) --strip-unneeded $(SAMBA_TARGET_DIR)/usr/sbin/nmbd
	-$(STRIPCMD) --strip-unneeded $(SAMBA_TARGET_DIR)/usr/sbin/smbd
	$(INSTALL) -m 0755 package/samba/smbd_helper.sh $(TARGET_DIR)/usr/sbin

# TODO: add the necessary directories on the target fs.
# TODO: figure out to compile/install only the nedded subset of samba
# TODO: find out how to strip more features from samba

samba: uclibc $(TARGET_DIR)/$(SAMBA_TARGET_FSMON_LIBRARY) $(SAMBA_TARGET_DIR)/usr/sbin/smbd

samba-clean:
	-rm -r $(SAMBA_DIR)/.install/
	-rm $(SAMBA_DIR)/.compiled
	-rm $(SAMBA_DIR)/.configured
	-rm -f $(TARGET_DIR)/$(SAMBA_TARGET_FSMON_LIBRARY)
	-rm -f $(SAMBA_TARGET_DIR)/usr/sbin/{smbd,nmbd}
	-rm -f $(SAMBA_TARGET_DIR)/usr/lib/libsmbclient.so
	rm -f $(SAMBA_DIR)/$(SAMBA_FSMON_LIBRARY)
	-$(MAKE) -C $(SAMBA_DIR)/source clean

samba-dirclean:
	rm -rf $(SAMBA_DIR)
	

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_SAMBA)),y)
TARGETS+=samba
endif
