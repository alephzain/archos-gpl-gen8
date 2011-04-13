#! /bin/sh

set -e

PKG_DIR=$(dirname $0)
SRC_DIR=$PKG_DIR/libtinymail
BUILDROOT_DIR=$PKG_DIR/../..
DL_DIR=$BUILDROOT_DIR/dl

REVISION=${REVISION:-$(sed -n 's:^[ 	]*TINYMAIL_VER.*=[ 	]*r*\([0-9]*\).*:\1:p' $PKG_DIR/tinymail.mk)}

if [ -n "$REVISION" ] ; then
	# checkout a specified revision
	svn co https://svn.tinymail.org/svn/tinymail/trunk@$REVISION $SRC_DIR
else
	# checkout the head
	svn co https://svn.tinymail.org/svn/tinymail/trunk $SRC_DIR
	# get the head revision
	REVISION=$(svn info $SRC_DIR | sed -n 5p | sed -n 's:[^0-9]*\([0-9]*\).*:\1:p')
fi

# remove SVN files
find $SRC_DIR -name ".svn*" -exec rm -rf '{}' \; 2>/dev/null || true

# run the autotools
(cd $SRC_DIR ; NOCONFIGURE=1 ./autogen.sh)

# compress in an archive
tar cj -f $DL_DIR/libtinymail-r$REVISION.tar.bz2 -C $PKG_DIR libtinymail

# remove the directory
rm -rf $SRC_DIR
