#############################################################
#
# libgif 
#
#############################################################
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

LIBGIF_VER:=4.1.4
LIBGIF_DIR:=$(BUILD_DIR)/giflib-$(LIBGIF_VER)
LIBGIF_SITE:=http://$(BR2_SOURCEFORGE_MIRROR).dl.sourceforge.net/sourceforge/libgif
LIBGIF_SOURCE:=giflib-$(LIBGIF_VER).tar.bz2
LIBGIF_CAT:=bzcat

$(DL_DIR)/$(LIBGIF_SOURCE):
	 $(WGET) -P $(DL_DIR) $(LIBGIF_SITE)/$(LIBGIF_SOURCE)

libgif-source: $(DL_DIR)/$(LIBGIF_SOURCE)

$(LIBGIF_DIR)/.unpacked: $(DL_DIR)/$(LIBGIF_SOURCE)
	$(LIBGIF_CAT) $(DL_DIR)/$(LIBGIF_SOURCE) | tar -C $(BUILD_DIR) $(TAR_OPTIONS) -
	touch $(LIBGIF_DIR)/.unpacked

$(LIBGIF_DIR)/.configured: $(LIBGIF_DIR)/.unpacked
	(cd $(LIBGIF_DIR); rm -rf config.cache; \
		$(TARGET_CONFIGURE_OPTS) \
		ac_cv_lib_X11_main=no \
		./configure \
		--target=$(GNU_TARGET_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--build=$(GNU_HOST_NAME) \
		--prefix=$(STAGING_DIR) \
		--enable-shared \
		--disable-static \
		--without-x \
	);
	touch $(LIBGIF_DIR)/.configured

$(LIBGIF_DIR)/.compiled: $(LIBGIF_DIR)/.configured
	$(MAKE) -C $(LIBGIF_DIR)/lib/
	touch $(LIBGIF_DIR)/.compiled

#$(eval $(call MD5_DIGEST_template,libgif,$(DL_DIR)/$(LIBGIF_SOURCE),package/libgif))

#ifeq ($(libgif_md5),$(libgif_new_md5))
# already there, nothing to do
#$(STAGING_DIR)/lib/libgif.so:
	@echo " * not recompiling libgif in staging_dir"
#else
# compile it, and let us know for next time
$(STAGING_DIR)/lib/libgif.so: $(LIBGIF_DIR)/.compiled
	$(MAKE) \
		-C $(LIBGIF_DIR)/lib/ \
		prefix=$(STAGING_DIR) \
		exec_prefix=$(STAGING_DIR) \
		bindir=$(STAGING_DIR)/bin \
		datadir=$(STAGING_DIR)/share \
		install
	touch -c $(STAGING_DIR)/lib/libgif.so
	$(Refresh_libgif_md5)
#endif

$(TARGET_DIR)/usr/lib/libgif.so: $(STAGING_DIR)/lib/libgif.so
	cp -dpf $(STAGING_DIR)/lib/libgif.so* $(TARGET_DIR)/usr/lib/
	-$(STRIPCMD) --strip-unneeded $(TARGET_DIR)/usr/lib/libgif.so

gif libgif: uclibc zlib $(TARGET_DIR)/usr/lib/libgif.so

libgif-clean:
	$(Clean_libgif_md5)
	-$(MAKE) -C $(LIBGIF_DIR) clean

libgif-dirclean:
	$(Clean_libgif_md5)
	rm -rf $(LIBGIF_DIR)

#############################################################
#
# Toplevel Makefile options
#
#############################################################
ifeq ($(strip $(BR2_PACKAGE_LIBGIF)),y)
TARGETS+=libgif
endif
