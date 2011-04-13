#!/bin/sh

export LD_PRELOAD=/usr/lib/sambafsmon.so.1.1.0
/usr/sbin/smbd $*
