#############################################################
#
# libtfm
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

LIBTOMFASTMATH_VER:=0.10
LIBTOMFASTMATH_DIR:=$(BUILD_DIR)/tomsfastmath-$(LIBTOMFASTMATH_VER)
LIBTOMFASTMATH_SITE:=http://www.libtom.org/files
LIBTOMFASTMATH_SOURCE:=tfm-$(LIBTOMFASTMATH_VER).tar.bz2

USER=$(shell id -u) 
GROUP=$(shell id -g)

ifeq ($(ARCH),arm)
DEFINES = -DTFM_ARM
else
DEFINES =
endif

$(DL_DIR)/$(LIBTOMFASTMATH_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBTOMFASTMATH_SITE)/$(LIBTOMFASTMATH_SOURCE)

libtfm-source: $(DL_DIR)/$(LIBTOMFASTMATH_SOURCE)

$(LIBTOMFASTMATH_DIR)/.unpacked: $(DL_DIR)/$(LIBTOMFASTMATH_SOURCE)
	tar -C $(BUILD_DIR) -j $(TAR_OPTIONS) $(DL_DIR)/$(LIBTOMFASTMATH_SOURCE)
	touch $(LIBTOMFASTMATH_DIR)/.unpacked

$(LIBTOMFASTMATH_DIR)/libtfm.a: $(LIBTOMFASTMATH_DIR)/.unpacked
		CFLAGS="-DENDIAN_LITTLE -DENDIAN_32BITWORD $(DEFINES) -DTFM_DESC" \
	$(MAKE) \
		CC="$(TARGET_CROSS)gcc" \
		AR="$(TARGET_CROSS)ar" \
		-C $(LIBTOMFASTMATH_DIR)

#$(eval $(call MD5_DIGEST_template,libtfm,$(DL_DIR)/$(LIBTOMFASTMATH_SOURCE),package/libtfm))

#ifeq ($(libtfm_md5),$(libtfm_new_md5))
# already there, nothing to do
#$(STAGING_DIR)/usr/lib/libtfm.a:
#	@echo " * not recompiling libtfm in staging_dir"
#else
# compile it, and let us know for next time
$(STAGING_DIR)/usr/lib/libtfm.a: $(LIBTOMFASTMATH_DIR)/libtfm.a
	$(MAKE) \
		-C $(LIBTOMFASTMATH_DIR) \
		DESTDIR="$(STAGING_DIR)" \
		GROUP="$(GROUP)" \
		USER="$(USER)" \
		install
	$(Refresh_libtfm_md5)
#endif

libtfm: uclibc $(STAGING_DIR)/usr/lib/libtfm.a

libtfm-clean:
	$(Clean_libtfm_md5)
	rm -f $(STAGING_DIR)/usr/include/tfm.h $(STAGING_DIR)/usr/lib/libtfm.a
	-$(MAKE) -C $(LIBTOMFASTMATH_DIR) clean

libtfm-dirclean:
	$(Clean_libtfm_md5)
	rm -rf $(LIBTOMFASTMATH_DIR)
#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBTOMFASTMATH)),y)
TARGETS+=libtfm
endif
