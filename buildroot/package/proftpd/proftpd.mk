#############################################################
#
# proftpd
#
#############################################################
PROFTPD_VERSION:=1.3.2a
PROFTPD_SOURCE:=proftpd-$(PROFTPD_VERSION).tar.bz2
PROFTPD_SITE:=ftp://ftp.proftpd.org/distrib/source/
PROFTPD_DIR:=$(BUILD_DIR)/proftpd-$(PROFTPD_VERSION)
PROFTPD_CAT:=$(BZCAT)
PROFTPD_BINARY:=proftpd
PROFTPD_TARGET_BINARY:=usr/sbin/proftpd
PROFTPD_FSMON_LIBRARY=proftpdfsmon.so.1.1.0
PROFTPD_TARGET_FSMON_LIBRARY:=usr/lib/$(PROFTPD_FSMON_LIBRARY)

ifneq ($(BR2_INET_IPV6),y)
DISABLE_IPV6:=--disable-ipv6
endif

$(DL_DIR)/$(PROFTPD_SOURCE):
	 $(WGET) -P $(DL_DIR) $(PROFTPD_SITE)/$(PROFTPD_SOURCE)

proftpd-source: $(DL_DIR)/$(PROFTPD_SOURCE)

$(PROFTPD_DIR)/.unpacked: $(DL_DIR)/$(PROFTPD_SOURCE)
	$(PROFTPD_CAT) $(DL_DIR)/$(PROFTPD_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	cp package/proftpd/wrapper.c $(PROFTPD_DIR)/
	$(CONFIG_UPDATE) $(PROFTPD_DIR)
	touch $@

$(PROFTPD_DIR)/.configured: $(PROFTPD_DIR)/.unpacked
	(cd $(PROFTPD_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		$(TARGET_CONFIGURE_ARGS) \
		ac_cv_func_setpgrp_void=yes \
		ac_cv_func_setgrent_void=yes \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=/usr \
		--sysconfdir=/etc \
		--localstatedir=/var/run \
		--disable-static \
		--disable-curses \
		--disable-ncurses \
		--disable-facl \
		--disable-dso \
		--enable-shadow \
		$(DISABLE_LARGEFILE) \
		$(DISABLE_IPV6) \
		--with-gnu-ld \
	)
	touch $@

$(PROFTPD_DIR)/$(PROFTPD_BINARY): $(PROFTPD_DIR)/.configured
	$(MAKE) CC="$(HOSTCC)" CFLAGS="" LDFLAGS="" \
		-C $(PROFTPD_DIR)/lib/libcap _makenames
	$(MAKE) -C $(PROFTPD_DIR)

$(PROFTPD_DIR)/$(PROFTPD_FSMON_LIBRARY): $(PROFTPD_DIR)/.unpacked
	$(TARGET_CC) -DLOG_FILE=\"/tmp/proftpd_write.log\" -fPIC -rdynamic -g -c -Wall $(PROFTPD_DIR)/wrapper.c -o $(PROFTPD_DIR)/wrapper.o
	$(TARGET_CC) -shared -Wl,-soname,proftpdfsmon.so.1 -o $(PROFTPD_DIR)/$(PROFTPD_FSMON_LIBRARY) $(PROFTPD_DIR)/wrapper.o -lc -ldl

$(TARGET_DIR)/$(PROFTPD_TARGET_FSMON_LIBRARY): $(PROFTPD_DIR)/$(PROFTPD_FSMON_LIBRARY)
	cp -dpf $(PROFTPD_DIR)/$(PROFTPD_FSMON_LIBRARY) \
		$(TARGET_DIR)/$(PROFTPD_TARGET_FSMON_LIBRARY)

$(TARGET_DIR)/$(PROFTPD_TARGET_BINARY): $(PROFTPD_DIR)/$(PROFTPD_BINARY)
	cp -dpf $(PROFTPD_DIR)/$(PROFTPD_BINARY) \
		$(TARGET_DIR)/$(PROFTPD_TARGET_BINARY)
	if [ ! -f $(TARGET_DIR)/etc/proftpd.conf ]; then \
		if [ -f package/proftpd/proftpd.conf ]; then \
			$(INSTALL) -m 0644 -D package/proftpd/proftpd.conf $(TARGET_DIR)/etc/proftpd.conf; \
		else \
			$(INSTALL) -m 0644 -D $(PROFTPD_DIR)/sample-configurations/basic.conf $(TARGET_DIR)/etc/proftpd.conf; \
		fi \
	fi
	$(INSTALL) -m 0755 package/proftpd/proftpd_helper.sh $(TARGET_DIR)/usr/sbin

proftpd: uclibc $(TARGET_DIR)/$(PROFTPD_TARGET_FSMON_LIBRARY) $(TARGET_DIR)/$(PROFTPD_TARGET_BINARY)

proftpd-clean:
	rm -f $(TARGET_DIR)/$(PROFTPD_TARGET_FSMON_LIBRARY)
	rm -f $(TARGET_DIR)/$(PROFTPD_TARGET_BINARY)
	rm -f $(TARGET_DIR)/usr/sbin/proftpd_helper.sh
	rm -f $(TARGET_DIR)/etc/proftpd.conf
	rm -f $(PROFTPD_DIR)/$(PROFTPD_FSMON_LIBRARY)
	-$(MAKE) -C $(PROFTPD_DIR) clean

proftpd-dirclean:
	rm -rf $(PROFTPD_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_PROFTPD)),y)
TARGETS+=proftpd
endif
