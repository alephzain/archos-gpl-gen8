#!/bin/sh

#chdir to buildroot
cd `dirname $0`
touch build_i586/libtinymail/.configured
BUILD=DEBUG make BOARD=g6_i586 tinymail

DEST="../arcbuild/build/G6SH_DEBUG_i586"

echo $DEST

cp build_i586/libtinymail/libtinymail-camel/camel-lite/camel/providers/smtp/.libs/libcamelsmtp.so $DEST/root/usr/lib/camel-lite-1.2/camel-providers/

cp build_i586/libtinymail/libtinymail/.libs/libtinymail-1.0.so.0.0.0 $DEST/root/usr/lib

cp build_i586/libtinymail/libtinymail-camel/.libs/libtinymail-camel-1.0.so.0.0.0 $DEST/root/usr/lib

cp build_i586/libtinymail/libtinymail-camel/camel-lite/camel/.libs/libcamel-lite-1.2.so.0.0.0 $DEST/root/usr/lib

cp build_i586/libtinymail/libtinymail-camel/camel-lite/camel/providers/imap/.libs/libcamelimap.so $DEST/root/usr/lib/camel-lite-1.2/camel-providers/

cp build_i586/libtinymail/libtinymail-camel/camel-lite/camel/providers/pop3/.libs/libcamelpop3.so $DEST/root/usr/lib/camel-lite-1.2/camel-providers/
