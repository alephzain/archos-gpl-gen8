#############################################################
#
# libtomcrypt
#
#############################################################
# Copyright (C) 2001-2003 by Erik Andersen <andersen@codepoet.org>
# Copyright (C) 2002 by Tim Riker <Tim@Rikers.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU Library General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

LIBTOMCRYPT_VER:=1.16
LIBTOMCRYPT_DIR:=$(BUILD_DIR)/libtomcrypt-$(LIBTOMCRYPT_VER)
LIBTOMCRYPT_SITE:=http://www.libtom.org/files
LIBTOMCRYPT_SOURCE:=crypt-$(LIBTOMCRYPT_VER).tar.bz2

USER=$(shell id -u) 
GROUP=$(shell id -g)

$(DL_DIR)/$(LIBTOMCRYPT_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBTOMCRYPT_SITE)/$(LIBTOMCRYPT_SOURCE)

libtomcrypt-source: $(DL_DIR)/$(LIBTOMCRYPT_SOURCE)

$(LIBTOMCRYPT_DIR)/.unpacked: $(DL_DIR)/$(LIBTOMCRYPT_SOURCE) package/libtomcrypt/libtomcrypt-dh.patch
	rm -rf $(LIBTOMCRYPT_DIR)
	tar -C $(BUILD_DIR) -j $(TAR_OPTIONS) $(DL_DIR)/$(LIBTOMCRYPT_SOURCE)
	toolchain/patch-kernel.sh $(LIBTOMCRYPT_DIR) package/libtomcrypt \*.patch
	touch $(LIBTOMCRYPT_DIR)/.unpacked

$(LIBTOMCRYPT_DIR)/libtomcrypt.a: $(LIBTOMCRYPT_DIR)/.unpacked
		# include system headers for <tfm.h>, but make sure, we find our headers first and not the installed ones
		CFLAGS="-I./src/headers -I$(STAGING_DIR)/usr/include -DENDIAN_LITTLE -DENDIAN_32BITWORD -DUSE_TFM -DTFM_DESC" EXTRALIBS=-ltfm \
	$(MAKE) \
		CC="$(TARGET_CROSS)gcc" \
		AR="$(TARGET_CROSS)ar" \
		-C $(LIBTOMCRYPT_DIR)

$(STAGING_DIR)/usr/lib/libtomcrypt.a: $(LIBTOMCRYPT_DIR)/libtomcrypt.a
	$(MAKE) \
		NODOCS=1 \
		-C $(LIBTOMCRYPT_DIR) \
		DESTDIR="$(STAGING_DIR)" \
		GROUP="$(GROUP)" \
		USER="$(USER)" \
		install

libtomcrypt: uclibc libtfm $(STAGING_DIR)/usr/lib/libtomcrypt.a

libtomcrypt-clean:
	rm -f $(STAGING_DIR)/usr/include/tomcrypt*.h $(STAGING_DIR)/usr/lib/libtomcrypt.a
	-$(MAKE) -C $(LIBTOMCRYPT_DIR) clean

libtomcrypt-dirclean:
	rm -rf $(LIBTOMCRYPT_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBTOMCRYPT)),y)
TARGETS+=libtomcrypt
endif
