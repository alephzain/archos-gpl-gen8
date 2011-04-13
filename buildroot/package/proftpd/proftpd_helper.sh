#!/bin/sh

export LD_PRELOAD=/usr/lib/proftpdfsmon.so.1.1.0
/usr/sbin/proftpd $*
