#############################################################
#
# proftpd
#
#############################################################
PROFTPD_STATIC_VERSION:=1.3.2a
PROFTPD_STATIC_SOURCE:=proftpd-$(PROFTPD_STATIC_VERSION).tar.bz2
PROFTPD_STATIC_SITE:=ftp://ftp.proftpd.org/distrib/source/
PROFTPD_STATIC_DIR:=$(BUILD_DIR)/proftpd-$(PROFTPD_STATIC_VERSION)
PROFTPD_STATIC_CAT:=$(BZCAT)
PROFTPD_STATIC_BINARY:=proftpd
PROFTPD_STATIC_TARGET_BINARY:=usr/sbin/proftpd-static
PROFTPD_STATIC_TARGET_LINK:=usr/sbin/proftpd

$(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_BINARY):
	cp -dpf package/proftpd-static/$(PROFTPD_STATIC_BINARY) \
		$(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_BINARY)
	ln -sf proftpd-static $(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_LINK)
	if [ ! -f $(TARGET_DIR)/etc/proftpd.conf ]; then \
		if [ -f package/proftpd-static/proftpd.conf ]; then \
			$(INSTALL) -m 0644 -D package/proftpd-static/proftpd.conf $(TARGET_DIR)/etc/proftpd.conf; \
		else \
			$(INSTALL) -m 0644 -D $(PROFTPD_DIR)/sample-configurations/basic.conf $(TARGET_DIR)/etc/proftpd.conf; \
		fi \
	fi

proftpd-static: uclibc $(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_BINARY)

proftpd-static-clean:
	rm -f $(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_LINK)
	rm -f $(TARGET_DIR)/$(PROFTPD_STATIC_TARGET_BINARY)
	rm -f $(TARGET_DIR)/etc/proftpd.conf

proftpd-static-dirclean:
	@echo Nothing to do...

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_PROFTPD_STATIC)),y)
TARGETS+=proftpd-static
endif
