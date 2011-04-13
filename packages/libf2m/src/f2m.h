/*
 * F2M.H
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
#ifndef _F2M_H
#define _F2M_H

typedef void *F2M_CTX;

F2M_CTX *f2m_create( void );
int f2m_destroy( F2M_CTX *ctx );
int f2m_process( F2M_CTX *ctx, unsigned char *dst, int *dst_size, 
			const unsigned char *src, int src_size, 
			int time, int key );


#endif
