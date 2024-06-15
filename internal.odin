//+private
package flac

import "core:crypto/legacy/md5"

FLAC_MAGIC :: 'f' << 24 | 'L' << 16 | 'a' << 8 | 'C'

//odinfmt: disable
crc8_lookup := [256]u8 {
    0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
    0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
    0x70, 0x77, 0x7E, 0x79, 0x6C, 0x6B, 0x62, 0x65,
    0x48, 0x4F, 0x46, 0x41, 0x54, 0x53, 0x5A, 0x5D,
    0xE0, 0xE7, 0xEE, 0xE9, 0xFC, 0xFB, 0xF2, 0xF5,
    0xD8, 0xDF, 0xD6, 0xD1, 0xC4, 0xC3, 0xCA, 0xCD,
    0x90, 0x97, 0x9E, 0x99, 0x8C, 0x8B, 0x82, 0x85,
    0xA8, 0xAF, 0xA6, 0xA1, 0xB4, 0xB3, 0xBA, 0xBD,
    0xC7, 0xC0, 0xC9, 0xCE, 0xDB, 0xDC, 0xD5, 0xD2,
    0xFF, 0xF8, 0xF1, 0xF6, 0xE3, 0xE4, 0xED, 0xEA,
    0xB7, 0xB0, 0xB9, 0xBE, 0xAB, 0xAC, 0xA5, 0xA2,
    0x8F, 0x88, 0x81, 0x86, 0x93, 0x94, 0x9D, 0x9A,
    0x27, 0x20, 0x29, 0x2E, 0x3B, 0x3C, 0x35, 0x32,
    0x1F, 0x18, 0x11, 0x16, 0x03, 0x04, 0x0D, 0x0A,
    0x57, 0x50, 0x59, 0x5E, 0x4B, 0x4C, 0x45, 0x42,
    0x6F, 0x68, 0x61, 0x66, 0x73, 0x74, 0x7D, 0x7A,
    0x89, 0x8E, 0x87, 0x80, 0x95, 0x92, 0x9B, 0x9C,
    0xB1, 0xB6, 0xBF, 0xB8, 0xAD, 0xAA, 0xA3, 0xA4,
    0xF9, 0xFE, 0xF7, 0xF0, 0xE5, 0xE2, 0xEB, 0xEC,
    0xC1, 0xC6, 0xCF, 0xC8, 0xDD, 0xDA, 0xD3, 0xD4,
    0x69, 0x6E, 0x67, 0x60, 0x75, 0x72, 0x7B, 0x7C,
    0x51, 0x56, 0x5F, 0x58, 0x4D, 0x4A, 0x43, 0x44,
    0x19, 0x1E, 0x17, 0x10, 0x05, 0x02, 0x0B, 0x0C,
    0x21, 0x26, 0x2F, 0x28, 0x3D, 0x3A, 0x33, 0x34,
    0x4E, 0x49, 0x40, 0x47, 0x52, 0x55, 0x5C, 0x5B,
    0x76, 0x71, 0x78, 0x7F, 0x6A, 0x6D, 0x64, 0x63,
    0x3E, 0x39, 0x30, 0x37, 0x22, 0x25, 0x2C, 0x2B,
    0x06, 0x01, 0x08, 0x0F, 0x1A, 0x1D, 0x14, 0x13,
    0xAE, 0xA9, 0xA0, 0xA7, 0xB2, 0xB5, 0xBC, 0xBB,
    0x96, 0x91, 0x98, 0x9F, 0x8A, 0x8D, 0x84, 0x83,
    0xDE, 0xD9, 0xD0, 0xD7, 0xC2, 0xC5, 0xCC, 0xCB,
    0xE6, 0xE1, 0xE8, 0xEF, 0xFA, 0xFD, 0xF4, 0xF3,
}

crc16_lookup := [256]u16 {
    0x0000, 0x8005, 0x800F, 0x000A, 0x801B, 0x001E, 0x0014, 0x8011,
    0x8033, 0x0036, 0x003C, 0x8039, 0x0028, 0x802D, 0x8027, 0x0022,
    0x8063, 0x0066, 0x006C, 0x8069, 0x0078, 0x807D, 0x8077, 0x0072,
    0x0050, 0x8055, 0x805F, 0x005A, 0x804B, 0x004E, 0x0044, 0x8041,
    0x80C3, 0x00C6, 0x00CC, 0x80C9, 0x00D8, 0x80DD, 0x80D7, 0x00D2,
    0x00F0, 0x80F5, 0x80FF, 0x00FA, 0x80EB, 0x00EE, 0x00E4, 0x80E1,
    0x00A0, 0x80A5, 0x80AF, 0x00AA, 0x80BB, 0x00BE, 0x00B4, 0x80B1,
    0x8093, 0x0096, 0x009C, 0x8099, 0x0088, 0x808D, 0x8087, 0x0082,
    0x8183, 0x0186, 0x018C, 0x8189, 0x0198, 0x819D, 0x8197, 0x0192,
    0x01B0, 0x81B5, 0x81BF, 0x01BA, 0x81AB, 0x01AE, 0x01A4, 0x81A1,
    0x01E0, 0x81E5, 0x81EF, 0x01EA, 0x81FB, 0x01FE, 0x01F4, 0x81F1,
    0x81D3, 0x01D6, 0x01DC, 0x81D9, 0x01C8, 0x81CD, 0x81C7, 0x01C2,
    0x0140, 0x8145, 0x814F, 0x014A, 0x815B, 0x015E, 0x0154, 0x8151,
    0x8173, 0x0176, 0x017C, 0x8179, 0x0168, 0x816D, 0x8167, 0x0162,
    0x8123, 0x0126, 0x012C, 0x8129, 0x0138, 0x813D, 0x8137, 0x0132,
    0x0110, 0x8115, 0x811F, 0x011A, 0x810B, 0x010E, 0x0104, 0x8101,
    0x8303, 0x0306, 0x030C, 0x8309, 0x0318, 0x831D, 0x8317, 0x0312,
    0x0330, 0x8335, 0x833F, 0x033A, 0x832B, 0x032E, 0x0324, 0x8321,
    0x0360, 0x8365, 0x836F, 0x036A, 0x837B, 0x037E, 0x0374, 0x8371,
    0x8353, 0x0356, 0x035C, 0x8359, 0x0348, 0x834D, 0x8347, 0x0342,
    0x03C0, 0x83C5, 0x83CF, 0x03CA, 0x83DB, 0x03DE, 0x03D4, 0x83D1,
    0x83F3, 0x03F6, 0x03FC, 0x83F9, 0x03E8, 0x83ED, 0x83E7, 0x03E2,
    0x83A3, 0x03A6, 0x03AC, 0x83A9, 0x03B8, 0x83BD, 0x83B7, 0x03B2,
    0x0390, 0x8395, 0x839F, 0x039A, 0x838B, 0x038E, 0x0384, 0x8381,
    0x0280, 0x8285, 0x828F, 0x028A, 0x829B, 0x029E, 0x0294, 0x8291,
    0x82B3, 0x02B6, 0x02BC, 0x82B9, 0x02A8, 0x82AD, 0x82A7, 0x02A2,
    0x82E3, 0x02E6, 0x02EC, 0x82E9, 0x02F8, 0x82FD, 0x82F7, 0x02F2,
    0x02D0, 0x82D5, 0x82DF, 0x02DA, 0x82CB, 0x02CE, 0x02C4, 0x82C1,
    0x8243, 0x0246, 0x024C, 0x8249, 0x0258, 0x825D, 0x8257, 0x0252,
    0x0270, 0x8275, 0x827F, 0x027A, 0x826B, 0x026E, 0x0264, 0x8261,
    0x0220, 0x8225, 0x822F, 0x022A, 0x823B, 0x023E, 0x0234, 0x8231,
    0x8213, 0x0216, 0x021C, 0x8219, 0x0208, 0x820D, 0x8207, 0x0202, 
}
//odinfmt: enable

fixed_coefficients := [4][]i32{{1}, {2, -1}, {3, -3, 1}, {4, -6, 4, -1}}

// TODO: no idea if I want to keep this global and a thread_local
// or if I should just init it in load_from_bytes
@(thread_local)
md5_ctx: md5.Context

BlockType :: enum u16be {
    STREAMINFO,
    PADDING,
    APPLICATION,
    SEEKTABLE,
    VORBIS_COMMENT,
    CUESHEET,
    PICTURE,
    INVALID = 127,
}

TrackType :: enum u8 {
    AUDIO,
    NONAUDIO,
}

BlockingStrategy :: enum {
    FIXED,
    VARIABLE,
}

SampleRate :: enum {
    USE_STREAMINFO,
    _88_2kHz,
    _176_4kHz,
    _192kHz,
    _8kHz,
    _16kHz,
    _22_05kHz,
    _24kHz,
    _32kHz,
    _44_1kHz,
    _48kHz,
    _96kHz,
    USE_8_BITS_IN_kHz_FROM_HEADER_END,
    USE_16_BITS_IN_Hz_FROM_HEADER_END,
    USE_16_BITS_IN_TENS_OF_Hz_FROM_HEADER_END,
    INVALID,
}

SampleSize :: enum {
    USE_STREAMINFO,
    _8BPS,
    _12BPS,
    // 011 is Reserved
    _16BPS = 4,
    _20BPS,
    _24BPS,
    _32BPS,
}

ChannelAssignment :: enum {
    MONO,
    _2CHANNELS,
    _3CHANNELS,
    _4CHANNELS,
    _5CHANNELS,
    _6CHANNELS,
    _7CHANNELS,
    _8CHANNELS,
    STEREO_LEFT_SIDE,
    STEREO_SIDE_RIGHT,
    STEREO_MID_SIDE,
}

ResidualCodingMethod :: enum {
    RICE,
    RICE2,
}

/*
bit_field u32be {
    last_block: bool | 1,
    type: BlockType | 7,
    length: u32be | 24,
}
*/
MetadataBlockHeader :: struct {
    type:       BlockType,
    last_block: bool,
    length:     u32,
}

#assert(size_of(FlacHeader) == 0x2A)
FlacHeader :: struct #packed {
    magic:             u32be,
    streaminfo_header: u32be,
    streaminfo:        StreamInfoBlock,
}

#assert(size_of(Seekpoint) == 18)
Seekpoint :: struct #packed {
    sample_num:  u64be,
    offset:      u64be,
    num_samples: u16be,
}

#assert(size_of(StreamInfoBlock) == 0x22)
StreamInfoBlock :: struct #packed {
    min_block_size: u16be,
    using _:        bit_field u64be {
        max_block_size: u16be | 16,
        min_frame_size: u32be | 24,
        max_frame_size: u32be | 24,
    },
    /*
	bit_field u64be {
        sample_rate: u32be | 20,
        num_channel_minus_one: u8 | 3,
        bits_per_sample_minus_one: u8 | 5,
        total_samples: u64be | 36,
    }
	*/
    sr_chan_bps_ts: u64be,
    md5:            [16]byte,
}

#assert(size_of(PictureMetadata) == 20)
PictureMetadata :: struct {
    width:      u32be,
    height:     u32be,
    depth:      u32be,
    num_colors: u32be,
    data_len:   u32be,
}

#assert(size_of(CueSheet) == 396)
CueSheet :: struct #packed {
    media_catalog_num:   [128]byte,
    num_lead_in_samples: u64be,
    using _:             bit_field u8 {
        reserved:     u8   | 7,
        compact_disc: bool | 1,
    },
    reserved:            [258]byte,
    num_tracks:          u8,
}

#assert(size_of(CueSheetTrack) == 36)
CueSheetTrack :: struct #packed {
    track_offset:           u64be,
    track_num:              u8,
    ISRC:                   [12]byte,
    using _:                bit_field u8 {
        reserved:     u8        | 6,
        pre_emphasis: bool      | 1,
        track_type:   TrackType | 1,
    },
    reserved:               [13]byte,
    num_track_index_points: u8,
}

#assert(size_of(CueSheetTrackIndex) == 12)
CueSheetTrackIndex :: struct #packed {
    offset:             u64be,
    index_point_number: u8,
    reserved:           [3]byte,
}

decode_extended_utf8 :: proc(r: ^Reader) -> (decoded_num: u64, err: Error) {
    MASKX :: 0b0011_1111
    MASK2 :: 0b0001_1111
    MASK3 :: 0b0000_1111
    MASK4 :: 0b0000_0111
    MASK5 :: 0b0000_0011
    MASK6 :: 0b0000_0001

    decoded_num = u64(0)

    first_byte := read_byte(r) or_return
    utf8_sequence_len := 0

    for i: uint = 7; i > 0; i -= 1 {
        bit := (first_byte >> i) & 1
        if bit == 1 {
            utf8_sequence_len += 1
        } else {
            break
        }
    }

    if utf8_sequence_len > 0 {
        octets := make([dynamic]byte, 0, 8)
        defer delete(octets)
        for i := utf8_sequence_len - 1; i > 0; i -= 1 {
            append(&octets, read_byte(r) or_return)
        }

        switch utf8_sequence_len {
            case 2:
                decoded_num = (u64(first_byte) & MASK2) << 6 | (u64(octets[0]) & MASKX)
            case 3:
                decoded_num =
                    (u64(first_byte) & MASK3) << 12 | (u64(octets[0]) & MASKX) << 6 | (u64(octets[1]) & MASKX)
            case 4:
                decoded_num =
                    (u64(first_byte) & MASK4) << 18 |
                    (u64(octets[0]) & MASKX) << 12 |
                    (u64(octets[1]) & MASKX) << 6 |
                    (u64(octets[2]) & MASKX)
            case 5:
                decoded_num =
                    (u64(first_byte) & MASK5) << 24 |
                    (u64(octets[0]) & MASKX) << 18 |
                    (u64(octets[1]) & MASKX) << 12 |
                    (u64(octets[2]) & MASKX) << 6 |
                    (u64(octets[3]) & MASKX)
            case 6:
                decoded_num =
                    (u64(first_byte) & MASK6) << 30 |
                    (u64(octets[0]) & MASKX) << 24 |
                    (u64(octets[1]) & MASKX) << 18 |
                    (u64(octets[2]) & MASKX) << 12 |
                    (u64(octets[3]) & MASKX) << 6 |
                    (u64(octets[4]) & MASKX)
            case 7:
                decoded_num =
                    (u64(octets[0]) & MASKX) << 30 |
                    (u64(octets[1]) & MASKX) << 24 |
                    (u64(octets[2]) & MASKX) << 18 |
                    (u64(octets[3]) & MASKX) << 12 |
                    (u64(octets[4]) & MASKX) << 6 |
                    (u64(octets[5]) & MASKX)
        }
    } else {
        decoded_num = u64(first_byte & 0x7F)
    }

    return decoded_num, nil
}

@(optimization_mode = "speed")
calculate_crc8 :: proc(data: []byte) -> u8 #no_bounds_check {
    crc: u8 = 0

    for i in 0..<len(data) {
        crc = crc8_lookup[crc ~ data[i]]
    }

    return crc
}

@(optimization_mode = "speed")
calculate_crc16 :: proc(data: []byte) -> u16 #no_bounds_check {
    crc: u16 = 0

    for i in 0..<len(data) {
        byte := u16(data[i])
        pos := (crc >> 8) ~ byte
        crc = (crc << 8) ~ crc16_lookup[pos]
    }

    return crc
}

pow2 :: #force_inline proc(#any_int exp: uint) -> int {
    return 1 << exp
}
