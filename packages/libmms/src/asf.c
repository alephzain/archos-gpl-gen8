/*
 * Copyright (C) 2002-2004 the xine project
 * 
 * This file is part of LibMMS, an MMS protocol handling library.
 * 
 * xine is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the ree Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * xine is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA
 *
 * MMS over TCP protocol
 *   based on work from major mms
 *   utility functions to handle communication with an mms server
 *
 * TODO:
 *   error messages
 *   enable seeking !
 */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "mms.h"
#include "asfheader.h"

#define CHUNK_SIZE              65536  /* max chunk size */

static int get_guid( const unsigned char *buffer, int offset )
{
	int i;
	GUID g;

	g.Data1 = LE_32( buffer + offset );
	g.Data2 = LE_16( buffer + offset + 4 );
	g.Data3 = LE_16( buffer + offset + 6 );
	for ( i = 0; i < 8; i++ ) {
		g.Data4[i] = buffer[offset + 8 + i];
	}

	for ( i = 1; i < sizeof(guids) / sizeof( GUID ); i++ ) {
		if ( !memcmp( &g, &guids[i].guid, sizeof( GUID ) ) ) {
lprintf( 1, "GUID: %s\n", guids[i].name );
			return guids[i].type;
		}
	}

lprintf( 0, "unknown GUID: 0x%x, 0x%x, 0x%x, "
		 "{ 0x%hx, 0x%hx, 0x%hx, 0x%hx, 0x%hx, 0x%hx, 0x%hx, 0x%hx }\n",
		 g.Data1, g.Data2, g.Data3, g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3], g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7] );

	return GUID_ERROR;
}

int mms_asf_check_header( const unsigned char *asf_header, const int asf_header_len )
{
	// We need at least 30 bytes to tell if it is a header or not!	
	if( asf_header_len >= 30 && GUID_ASF_HEADER == get_guid( asf_header, 0 ) ) {
		return LE_32( asf_header + 16 );
	} 
	return 0;
}

int mms_default_asf_handler( const unsigned char *asf_header, const int asf_header_len, mms_asf_header_t *asf, int is_mmsh )
{
	/*
	 * parse header
	 */

	int i, offs = 0;

	asf->packet_len = 0;
	asf->num_streams = 0;

	if (is_mmsh)
		offs = 24;
		
	i = 30;
	while ( i + offs < asf_header_len ) {

		int guid;
		uint64_t length;

		guid = get_guid( asf_header, i );
		i += 16;

		length = LE_64( asf_header + i );
		i += 8;

		if ((i + length) >= asf_header_len) 
			return 1;
		 
lprintf( 1, "\tlength    : %lld\n", length );
		switch ( guid ) {

			case GUID_ASF_FILE_PROPERTIES:

				asf->packet_len = LE_32( asf_header + i + 92 - 24 );
        			if (is_mmsh && asf->packet_len > CHUNK_SIZE) {
          				asf->file_len = 0;
					break;
        			}
				asf->file_len = LE_64( asf_header + i + 40 - 24 );
lprintf( 1, "\tfile object, packet length = %d (%d)\n", asf->packet_len, LE_32( asf_header + i + 96 - 24 ) );
				break;

			case GUID_ASF_STREAM_PROPERTIES:
				{
					uint16_t flags;
					uint16_t stream_id;
					int type;
					int encrypted;

					guid = get_guid( asf_header, i );
					switch ( guid ) {
						case GUID_ASF_AUDIO_MEDIA:
							type = ASF_STREAM_TYPE_AUDIO;
							asf->has_audio = 1;
							break;

						case GUID_ASF_VIDEO_MEDIA:
						case GUID_ASF_JFIF_MEDIA:
						case GUID_ASF_DEGRADABLE_JPEG_MEDIA:
							type = ASF_STREAM_TYPE_VIDEO;
							asf->has_video = 1;
							break;

						case GUID_ASF_COMMAND_MEDIA:
							type = ASF_STREAM_TYPE_CONTROL;
							break;

						default:
							type = ASF_STREAM_TYPE_UNKNOWN;
					}

					flags = LE_16( asf_header + i + 48 );
					stream_id = flags & 0x7F;
					encrypted = flags >> 15;

lprintf( 1, "\tstream object, stream id: %d, type: %d, encrypted: %d\n", stream_id, type, encrypted );

					if ( asf->num_streams < MMS_ASF_MAX_NUM_STREAMS && stream_id < MMS_ASF_MAX_NUM_STREAMS ) {
						asf->streams[stream_id].type = type;
						asf->stream_ids[asf->num_streams] = stream_id;
						asf->num_streams++;
					} else {
lprintf( 1, "\ttoo many streams, skipping\n" );
					}
				}
				break;

			case GUID_ASF_STREAM_BITRATE_PROPERTIES:
				{
					uint16_t streams = LE_16( asf_header + i );
					uint16_t stream_id;
					int j;

lprintf( 1, "\tstream bitrate properties\n" );
lprintf( 1, "\tstreams %d\n", streams );

					for ( j = 0; j < streams; j++ ) {
						stream_id = LE_16( asf_header + i + 2 + j * 6 );
lprintf( 1, "\t\tstream id %d\n", stream_id );
						asf->streams[stream_id].bitrate = LE_32( asf_header + i + 4 + j * 6 );
						asf->streams[stream_id].bitrate_pos = i + 4 + j * 6;
lprintf( 1, "\t\tstream id %d, bitrate %d  pos %d\n", stream_id, asf->streams[stream_id].bitrate, asf->streams[stream_id].bitrate_pos );
					}
				}
				break;

			default:
lprintf( 1, "\tunknown object\n" );
				break;
		}

		if ( length > 24 ) {
			i += length - 24;
		}
	}
	return 0;
}

void mms_default_choose_best_streams( mms_asf_header_t *asf, int bandwidth )
{
	int i;
	int video_stream = -1;
	int audio_stream = -1;
	int max_arate = -1;
	int min_vrate = -1;
	int min_bw_left = 0;
	int stream_id;
	int bandwidth_left;

lprintf( 1, "\r\nmms_choose_best_streams:\r\n");
	/* choose the best quality for the audio stream */
	/* i've never seen more than one audio stream */
lprintf( 1, "num_streams=%d\n", asf->num_streams );
	for ( i = 0; i < asf->num_streams; i++ ) {
		stream_id = asf->stream_ids[i];
		switch ( asf->streams[stream_id].type ) {
			case ASF_STREAM_TYPE_AUDIO:
lprintf( 1, "\t%d audio(%d) rate %d\n", i, stream_id, asf->streams[stream_id].bitrate );
				if ( (audio_stream == -1) || asf->streams[stream_id].bitrate > max_arate ) {
					audio_stream = stream_id;
					max_arate = asf->streams[stream_id].bitrate;
				}
				break;
			default:
				break;
		}
	}

	/* choose a video stream adapted to the user bandwidth */
	bandwidth_left = bandwidth - max_arate;
	if ( bandwidth_left < 0 ) {
		bandwidth_left = 0;
	}
lprintf( 1, "bandwidth %d, left %d\n", bandwidth, bandwidth_left );

	min_bw_left = bandwidth_left;
	for ( i = 0; i < asf->num_streams; i++ ) {
		stream_id = asf->stream_ids[i];
		switch ( asf->streams[stream_id].type ) {
			case ASF_STREAM_TYPE_VIDEO:
lprintf( 1, "\t%d video(%d) rate %d\n", i, stream_id, asf->streams[stream_id].bitrate );
				if ( ( ( bandwidth_left  - asf->streams[stream_id].bitrate ) < min_bw_left ) &&
				       ( bandwidth_left >= asf->streams[stream_id].bitrate ) ) {
					video_stream = stream_id;
					min_bw_left = bandwidth_left - asf->streams[stream_id].bitrate;
				}
				break;
			default:
				break;
		}
	}

	/* choose the lower bitrate of */
	if ( (video_stream == -1) && asf->has_video ) {
		for ( i = 0; i < asf->num_streams; i++ ) {
			stream_id = asf->stream_ids[i];
			switch ( asf->streams[stream_id].type ) {
				case ASF_STREAM_TYPE_VIDEO:
					if ((video_stream == -1) || 
					    (asf->streams[stream_id].bitrate < min_vrate ) || 
					    ( !min_vrate ) ) {
						video_stream = stream_id;
						min_vrate = asf->streams[stream_id].bitrate;
					}
					break;
				default:
					break;
			}
		}
	}
lprintf( 1, "selected streams: audio %d, video %d\n", audio_stream, video_stream );
	
	asf->streams[audio_stream].active = 1;
	asf->streams[video_stream].active = 1;

	return;
}
