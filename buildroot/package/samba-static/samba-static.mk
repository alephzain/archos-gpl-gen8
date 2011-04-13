#############################################################
#
# samba
#
#############################################################
SAMBA_STATIC_VERSION:=3.0.34
SAMBA_STATIC_SOURCE:=samba-$(SAMBA_STATIC_VERSION).tar.gz
SAMBA_STATIC_SITE:=http://us1.samba.org/samba/ftp/stable/
SAMBA_STATIC_DIR:=$(BUILD_DIR)/samba-$(SAMBA_VERSION)
SAMBA_STATIC_CAT:=$(ZCAT)
SAMBA_STATIC_SMBD_BINARY:=smbd
SAMBA_STATIC_SMBD_TARGET_BINARY:=usr/sbin/smbd-static
SAMBA_STATIC_SMBD_TARGET_LINK:=usr/sbin/smbd
SAMBA_STATIC_NMBD_BINARY:=nmbd
SAMBA_STATIC_NMBD_TARGET_BINARY:=usr/sbin/nmbd-static
SAMBA_STATIC_NMBD_TARGET_LINK:=usr/sbin/nmbd

$(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_BINARY):
	cp -dpf package/samba-static/$(SAMBA_STATIC_SMBD_BINARY) \
		$(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_BINARY)
	ln -sf `basename $(SAMBA_STATIC_SMBD_TARGET_BINARY)` \
		$(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_LINK)

$(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_BINARY):
	cp -dpf package/samba-static/$(SAMBA_STATIC_NMBD_BINARY) \
		$(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_BINARY)
	ln -sf `basename $(SAMBA_STATIC_NMBD_TARGET_BINARY)` \
		$(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_LINK)

samba-static: uclibc $(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_BINARY) $(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_BINARY)

samba-static-clean:
	rm -f $(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_LINK)
	rm -f $(TARGET_DIR)/$(SAMBA_STATIC_NMBD_TARGET_BINARY)
	rm -f $(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_LINK)
	rm -f $(TARGET_DIR)/$(SAMBA_STATIC_SMBD_TARGET_BINARY)

samba-static-dirclean:
	@echo Nothing to do...

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_SAMBA_STATIC)),y)
TARGETS+=samba-static
endif
