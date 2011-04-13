/*
 * FLV Reader/Parser
 *
 * Copyright (c) 2006 vixy project
 *
 * Copyright (c) 2006 ARCHOS SA
 *       make it independent of the FLV parser.
 *       ------------------------------------- 2007-01-01 nz@archos
 *
 * This file is part of VIXY FLV Converter.
 *
 * 'VIXY FLV Converter' is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * 'VIXY FLV Converter' is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with FFmpeg; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#ifndef FETCH_H
#define FETCH_H

#include <stdio.h>
#include "type.h"

#define	PACKETBUFFER_SIZE	(256*1024)

typedef struct _FETCH FETCH;

typedef int (*recv_flv_packet)(void* ptr, uint8 picture_type, const uint8* buf, uint32 size, uint32 time);

FETCH* FETCH_createInstance(recv_flv_packet cb, void* cb_ptr);
void FETCH_release(FETCH* p);
//void FETCH_start(FETCH* p);
//void FETCH_stop(FETCH* p);
int FETCH_read(FETCH* p, FILE* fp);

#endif // FETCH_H
