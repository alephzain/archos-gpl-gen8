/*
 * FLV to MPEG4 converter
 *
 * Copyright (c) 2006 vixy project
 *
 * Copyright (c) 2006 ARCHOS SA
 *       make it independent of the FLV parser.
 *       ------------------------------------- 2007-01-01 nz@archos
 *
 * Copyright (c) 2007 Neuros Technology
 *       Heavily rewritten to convert flv stream to mpeg4 at run time.
 *       ------------------------------------- 2007-06-02 mgao@neuros
 *
 * This file contains the code that based on FFmpeg (http://ffmpeg.mplayerhq.hu/)
 * See original copyright notice in /FFMPEG_CREDITS and /FFMPEG_IMPORTS
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

#include "m4v.h"
#include "bitwriter.h"
#include "flv.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define PACKETBUFFER_SIZE       (256*1024)

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
typedef struct _CONVCTX
{
	int width;
	int height;
	
	int frame;
	int icounter;
	
	int header_written;

	int first_m4v_header;

	M4V_VOL vol;

} CONVCTX;

typedef struct 
{
	M4V_VOL vol;

	CONVCTX	conv;
} CTX;

#define VOL_TIME_BITS 5

////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
static const uint8 ff_mpeg4_y_dc_scale_table[32]={
//  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
    0, 8, 8, 8, 8,10,12,14,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,34,36,38,40,42,44,46
};

static const uint8 ff_mpeg4_c_dc_scale_table[32]={
//  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31
    0, 8, 8, 8, 8, 9, 9,10,10,11,11,12,12,13,13,14,14,15,15,16,16,17,17,18,18,19,20,21,22,23,24,25
};

static void copy_vol(PICTURE* flv_pic, M4V_VOL* vol)
{
	vol->width     = flv_pic->width;
	vol->height    = flv_pic->height;
	vol->time_bits = VOL_TIME_BITS; // 0-31
}

static void copy_vop(PICTURE* flv_pic, M4V_VOP* vop, CONVCTX* c)
{
	vop->qscale = flv_pic->qscale;
	vop->time   = c->frame % 30;
	vop->icount = (c->icounter + 29) / 30;
	vop->intra_dc_threshold = 99;
	
	if (flv_pic->picture_type == FLV_I_TYPE) {
		vop->picture_type = M4V_I_TYPE;
	} else {
		vop->picture_type = M4V_P_TYPE;
		vop->f_code = 1;
	}
}

// not really copying any more.
//static void copy_microblock(MICROBLOCK* flv_mb, M4V_MICROBLOCK* m4v_mb)
static void copy_microblock(M4V_MICROBLOCK* m4v_mb)
{
#if 0	
	int i;
	m4v_mb->dquant = flv_mb->dquant;
	memcpy(m4v_mb->block, flv_mb->block, sizeof(m4v_mb->block)); // !!!!!!!
	m4v_mb->intra = flv_mb->intra;
	m4v_mb->skip = flv_mb->skip;
	m4v_mb->mv_type = flv_mb->mv_type;
	
	memcpy(m4v_mb->mv_x, flv_mb->mv_x, sizeof(m4v_mb->mv_x)); // !!!!!!
	memcpy(m4v_mb->mv_y, flv_mb->mv_y, sizeof(m4v_mb->mv_y)); // !!!!!!
#endif

	// dc rescale
	if (m4v_mb->intra)
	{
#ifndef KEEP_LOOP
		uint8 scale = ff_mpeg4_y_dc_scale_table[m4v_mb->qscale];
		M4V_BLOCK * blk = &m4v_mb->block[0];
		blk->block[0] = (blk->block[0]*8)/scale;
		blk++;
		blk->block[0] = (blk->block[0]*8)/scale;
		blk++;
		blk->block[0] = (blk->block[0]*8)/scale;
		blk++;
		blk->block[0] = (blk->block[0]*8)/scale;
		blk++;

		scale = ff_mpeg4_c_dc_scale_table[m4v_mb->qscale];
		blk->block[0] = (blk->block[0]*8)/scale;
		blk++;
		blk->block[0] = (blk->block[0]*8)/scale;
#else
		for (i = 0; i < 4; i++)
		{
			m4v_mb->block[i].block[0] *= 8;
			m4v_mb->block[i].block[0] /= ff_mpeg4_y_dc_scale_table[m4v_mb->qscale];
		}

		for (i = 4; i < 6; i++)
		{
			m4v_mb->block[i].block[0] *= 8;
			m4v_mb->block[i].block[0] /= ff_mpeg4_c_dc_scale_table[m4v_mb->qscale];
		}
#endif
	}
}

static int init_m4v_header(void *p, CONVCTX *c, BR *br, BW *bw)
{
	PICTURE picture;
	M4V_VOP vop;

	memset(&picture, 0, sizeof(picture));
	memset(&vop, 0, sizeof(vop));
	
	if (decode_picture_header(br, &picture) < 0) 
		return -1;
	copy_vol(&picture, &c->vol);

	m4v_encode_m4v_header(bw, &c->vol, 0);

	m4v_stuffing(bw);
	flash_bw(bw);
	
	c->width  = picture.width;
	c->height = picture.height;
		
	alloc_dcpred(&c->vol.dcpred, (c->width + 15) / 16, (c->height + 15) / 16);
//printf("init_m4v_header: %d\r\n", bw->pos );

	return 0;
}

static int write_m4v_picture_frame(void* p, CONVCTX* c, BR* br, BW* bw, PICTURE* flvpic, uint32 time)
{
	MICROBLOCK mb;
	M4V_VOP vop;
	//M4V_MICROBLOCK m4v_mb;
	int x, y;
	int mb_width  = (flvpic->width  + 15) / 16;
	int mb_height = (flvpic->height + 15) / 16;

	memset(&vop, 0, sizeof(vop));

	copy_vop(flvpic, &vop, c);
	m4v_encode_vop_header(bw, &vop, VOL_TIME_BITS, 0);
		
	// transcode flv to mpeg4
	for (y = 0; y < mb_height; y++) {
		for (x = 0; x < mb_width; x++) {
			memset(&mb, 0, sizeof(mb));
			//memset(&m4v_mb, 0, sizeof(m4v_mb));
			
			if (vop.picture_type == M4V_I_TYPE) {
				mb.intra = 1;
				if (decode_I_mb(br, &mb, flvpic->escape_type, flvpic->qscale) < 0) return -1;
#if 0
				m4v_mb.qscale = vop.qscale;
				copy_microblock(&mb, &m4v_mb);
				m4v_encode_I_dcpred(&m4v_mb, &c->vol.dcpred, x, y);
				m4v_encode_I_mb(bw, &m4v_mb);
#else
				mb.qscale = vop.qscale;
				mb.ac_pred = 0;
				copy_microblock((M4V_MICROBLOCK*)&mb);
				m4v_encode_I_dcpred(&mb, &c->vol.dcpred, x, y);
				m4v_encode_I_mb(bw, &mb);
#endif
			} else {
				if (decode_P_mb(br, &mb, flvpic->escape_type, flvpic->qscale) < 0) return -1;
#if 0
				m4v_mb.qscale = vop.qscale;
				copy_microblock(&mb, &m4v_mb);
				m4v_encode_I_dcpred(&m4v_mb, &c->vol.dcpred, x, y);
				m4v_encode_P_mb(bw, &m4v_mb);
#else
				mb.qscale = vop.qscale;
				mb.ac_pred = 0;
				copy_microblock((M4V_MICROBLOCK*)&mb);
				m4v_encode_I_dcpred(&mb, &c->vol.dcpred, x, y);
				m4v_encode_P_mb(bw, &mb);
#endif
			}
		}
	}

	m4v_stuffing(bw);
	flash_bw(bw);
	
	// write frame
//printf("OUT frame: %3d  %5d\r\n", c->frame, bw->pos );
	c->frame++;
	c->icounter++;

	return 0;
}

static int write_m4v_frame(void* p, CONVCTX* c, BR* br, BW* bw, uint32 time)
{
	PICTURE picture;

	memset(&picture, 0, sizeof(picture));
	init_dcpred(&c->vol.dcpred);
	
	if (decode_picture_header(br, &picture) < 0) 
		return -1;
	if (c->width != picture.width || c->height != picture.height) 
		return -1; //size changed..
	
	copy_vol(&picture, &c->vol);

	if (picture.picture_type == FLV_I_TYPE) {
		c->icounter = 0;
		if (c->first_m4v_header) {
			m4v_encode_m4v_header(bw, &c->vol, time);
			c->first_m4v_header = 0;
		}
	}

	if (write_m4v_picture_frame(p, c, br, bw, &picture, time) < 0) {
		return -1;
	}
	
	return 0;
}

CTX *f2m_create( void )
{
	CTX *ctx = malloc( sizeof( CTX ) );
	memset( ctx, 0, sizeof( CTX ) );

	memset(&ctx->vol, 0, sizeof(ctx->vol));
	
	ctx->conv.first_m4v_header = 1;
	return ctx;
}

int f2m_destroy( CTX *ctx )
{
	if( ctx ) {
//printf("wrote %d frames\r\n", ctx->conv.frame	);	
		free_dcpred(&ctx->conv.vol.dcpred);
		free( ctx );
	}
}

int f2m_process( CTX *ctx, unsigned char *dst, int *dst_size, 
			const unsigned char *src, int src_size, 
			int time, int key )
{
	if (key) {
		// I-frame
		if( !ctx->conv.header_written ) {
			BR br;
			BW bw;
			init_br(&br, src, src_size );
			init_bw(&bw, dst, PACKETBUFFER_SIZE);
			init_m4v_header(ctx, &ctx->conv, &br, &bw);
			ctx->conv.header_written = 1;
		}
	}
	if (!ctx->conv.header_written) {
		*dst_size = 0;
		return 1;
	}
	
	BR br;
	BW bw;
	init_br(&br, src, src_size );
	init_bw(&bw, dst, PACKETBUFFER_SIZE);
	write_m4v_frame(ctx, &ctx->conv, &br, &bw, time);
	*dst_size = bw.pos; 
//printf("process: key %d  siz %5d/%5d time %8d\r\n", key, src_size, bw.pos, time );
	return 0;
}

