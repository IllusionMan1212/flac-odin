package flac

import "core:bytes"
import "core:crypto/legacy/md5"
import "core:fmt"
import "core:mem"
import "core:math"
import "core:slice"
import "core:io"
import "core:os"
import "core:time"

@(private)
FLAC_MAGIC :: 'f' << 24 | 'L' << 16 | 'a' << 8 | 'C'

@(private)
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

@(private)
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

md5_ctx: md5.Context
decoded_samples: [dynamic]byte
output_file: os.Handle

Error :: union {
    io.Error,
    FlacError,
}

FlacError :: enum {
    Unable_To_Read_File,
    Invalid_Signature,
    Invalid_Sample_Rate,
    Missing_StreamInfo,
    Missing_Lead_Out_Track,
    Invalid_Coefficient_Precision,
    Metadata_Block_Length_Mismatch,
    CRC_Mismatch,
    MD5_Mismatch,
    Unimplemented_Utf8, // Remove
    Unsupported_BPS, // Remove
    Unencoded_BPS_For_Fixed_Subframe_Is_Unsupported, // Remove
    Invalid_Residual_Coding_Method,
    Invalid_Block_Size,
    Bits_Per_Second_Mismatch,
}

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

PictureType :: enum u32be {
    OTHER,
    FILE_ICON_32x32_PNG,
    OTHER_FILE_ICON,
    COVER_FRONT,
    COVER_BACK,
    LEAFLET,
    MEDIA,
    LEAD_ARTIST,
    ARTIST,
    CONDUCTOR,
    BAND,
    COMPOSER,
    LYRICIST,
    RECORDING_LOCATION,
    DURING_RECORDING,
    DURING_PERFORMANCE,
    VIDEO_SCREEN_CAPTURE,
    BRIGHT_COLORED_FISH,
    ILLUSTRATION,
    ARTIST_LOGO,
    PUBLISHER_LOGO,
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
    _2CHANNEL,
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

#assert(size_of(FlacHeader) == 0x2A)
FlacHeader :: struct #packed {
    magic: u32be,
    streaminfo_header: u32be,
    streaminfo: StreamInfoBlock,
}

MetadataBlockHeader :: struct {
    type: BlockType,
    last_block: bool,
    length: u32,
}

#assert(size_of(Seekpoint) == 18)
Seekpoint :: struct #packed {
    sample_num: u64be,
    offset: u64be,
    num_samples: u16be,
}

#assert(size_of(StreamInfoBlock) == 0x22)
StreamInfoBlock :: struct #packed {
    min_block_size: u16be,
    using _: bit_field u64be {
        max_block_size: u16be | 16,
        min_frame_size: u32be | 24,
        max_frame_size: u32be | 24,
    },
    // This isn't a bit_field because odin's bitfields are LSB and it's hard (impossible?)
    // to read data into it if we're doing non-power-of-8 bits that don't form full bytes like 20bits, 3bits, 5 bits, 36bits
    // (although 3 and 5 is fine because they form a byte together, but 36 and 20 don't form full bytes)
    sr_chan_bps_ts: u64be,
    md5: [16]byte,
}

#assert(size_of(CueSheet) == 396)
CueSheet :: struct #packed {
    media_catalog_num: [128]byte,
    num_lead_in_samples: u64be,
    using _: bit_field u8 {
        reserved: u8 | 7,
        compact_disc: bool | 1,
    },
    reserved: [258]byte,
    num_tracks: u8,
}

#assert(size_of(CueSheetTrack) == 36)
CueSheetTrack :: struct #packed {
    track_offset: u64be,
    track_num: u8,
    ISRC: [12]byte,
    using _: bit_field u8 {
        reserved: u8 | 6,
        pre_emphasis: bool | 1,
        track_type: TrackType | 1,
    },
    reserved: [13]byte,
    num_track_index_points: u8,
}

#assert(size_of(CueSheetTrackIndex) == 12)
CueSheetTrackIndex :: struct #packed {
    offset: u64be,
    index_point_number: u8,
    reserved: [3]byte,
}

decode_subframe :: proc(r: ^Reader, bps: u8, block_size: u16) -> Error {
    subframe_type_str := ""
    // TODO: temp allocator?? so we copy the slice of data into the _actual_ sample buffer
    // Maybe even a static arena with a size of 32MB by default (and configurable using #config) or something
    // that we then use to allocate from (better perf is the reason because allocating on the heap for every subframe
    // is probably noticibly slower)
    subframe_samples := make([dynamic]i32, 0, block_size)

    fmt.println("cur offset", r.i)
    fmt.println("cur offset bits", r.bits_read_in_byte)

    data := read_byte(r) or_return

    fmt.println("First subframe byte:", data)
    fmt.printfln("First subframe byte: 0b%b", data)

    subframe_type := (data & 0x7E) >> 1
    low_3_bits := subframe_type & 7
    has_wasted_bits := data & 1 == 1
    wasted_bits := 0

    fmt.println("has wasted bits:", has_wasted_bits)

    if has_wasted_bits {
        for (read_bit(r) or_return) != 1 {
            wasted_bits += 1
        }
        wasted_bits += 1
        fmt.println("wasted bits", wasted_bits)
    }

    if subframe_type == 0 { // CONSTANT
        fmt.println("SUBFRAME: CONSTANT")
        subframe_type_str = "CONSTANT"
        bits_to_read := int(bps) - wasted_bits
        // TODO: should we shift to the left by the number of wasted bits??
        sample := i32(read_bits(r, bits_to_read) or_return)
        if (sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
            sample = -(((~sample) & i32(math.pow2_f32(bits_to_read) - 1)) + 1)
        }
        append(&subframe_samples, sample)
    } else if subframe_type == 1 { // VERBATIM
        fmt.println("SUBFRAME: VERBATIM")
        subframe_type_str = "VERBATIM"
        // We loop over the samples in the block here because each sample is BPS bits long.
        // Which I assume is always 16 but that's wrong because BPS can go as high as 32 bits
        // TODO: this will break if bits per sample is anything BUT 16
        if bps < 16 || bps > 17 {
            fmt.println("UNSUPPORTED BPS FOR VERBATIM SUBFRAME")
            return .Unsupported_BPS
        }
        for sample in 0..<block_size {
            bits_to_read := int(bps) - wasted_bits

            fmt.printfln("reading %d bits", bits_to_read)

            unencoded_subblock := u16((read_bits(r, bits_to_read) or_return)) << uint(wasted_bits)

            fmt.printfln("unencoded_subblock: %b", unencoded_subblock)
            fmt.println("unencoded_subblock:", unencoded_subblock)
            fmt.printfln("unencoded_subblock: 0x%X", unencoded_subblock)

            unencoded_subblock_arr := transmute([2]byte)unencoded_subblock
            fmt.printfln("arr: %X", unencoded_subblock_arr)
            fmt.printfln("arr as u16: %X", transmute(u16)unencoded_subblock_arr)
            // TODO: I think we'll want to append these samples to a local slice and return that (or a slice we pass in)
            append(&decoded_samples, ..unencoded_subblock_arr[:])
        }
    } else if (subframe_type >> 5) & 1 == 1 { // LPC
        fmt.println("SUBFRAME: LPC")
        subframe_type_str = "LPC"
        sample_i := 0
        predictor_order := (subframe_type & 0x1F) + 1
        fmt.println("predictor_order:", predictor_order)

        for sample in 0..<predictor_order {
            // NOTE: samples are signed so we do 2's complement
            bits_to_read := int(bps) - wasted_bits
            // TODO: should we shift to the left by the number of wasted bits??
            unencoded_warmup_sample := i32(read_bits(r, bits_to_read) or_return)
            if (unencoded_warmup_sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
                unencoded_warmup_sample = -(((~unencoded_warmup_sample) & i32(math.pow2_f32(bits_to_read) - 1)) + 1)
            }

            //fmt.printfln("unencoded warmup sample: 0b%b", unencoded_warmup_sample)
            //fmt.println("unencoded warmup sample:", unencoded_warmup_sample)
            //fmt.printfln("unencoded warmup sample: 0x%X", unencoded_warmup_sample)
            append(&subframe_samples, unencoded_warmup_sample)
        }

        coeff_precision_minus_one := u8(read_bits(r, 4) or_return)
        if coeff_precision_minus_one == 0xF {
            return .Invalid_Coefficient_Precision
        }
        coeff_precision := coeff_precision_minus_one + 1

        coeff_bits_to_shift := i8(read_bits(r, 5) or_return)
        // NOTE: This is signed 2's complement so we check the MSB
        // NOTE: This is apparently supposed to never be a negative number according to the spec.
        if (coeff_bits_to_shift >> (5 - 1)) & 1 == 1 {
            fmt.println("BITS TO SHIFT IS NEGATIVE")
            coeff_bits_to_shift = -(((~coeff_bits_to_shift) & i8(math.pow2_f32(5) - 1)) + 1)
        }

        fmt.println("coeff precision", coeff_precision)
        fmt.println("coeff bits to shift", coeff_bits_to_shift)

        coefficients := make([]i32, predictor_order)

        for i in 0..<predictor_order {
            unencoded_coefficient := i32(read_bits(r, int(coeff_precision)) or_return)
            // Ditto
            if (unencoded_coefficient >> (coeff_precision - 1)) & 1 == 1 {
                unencoded_coefficient = -(((~unencoded_coefficient) & i32(math.pow2_f32(coeff_precision) - 1)) + 1)
            }
            coefficients[i] = unencoded_coefficient
            //fmt.println("unencoded_coefficient", unencoded_coefficient)
        }

        residual_coding_method := ResidualCodingMethod(read_bits(r, 2) or_return)
        if residual_coding_method != .RICE && residual_coding_method != .RICE2 {
            return .Invalid_Residual_Coding_Method
        }
        fmt.println(residual_coding_method)

        partition_order := read_bits(r, 4) or_return
        //fmt.println("parition order", partition_order)
        partitions := int(math.pow2_f32(partition_order))
        //fmt.println("partitions:", partitions)
        //fmt.println("block_size:", block_size)

        lpc_partitions_loop: for i in 0..<partitions {
            rice_parameter := read_bits(r, residual_coding_method == .RICE ? 4 : 5) or_return
            if (residual_coding_method == .RICE && rice_parameter == 15) || (residual_coding_method == .RICE2 && rice_parameter == 31) {
                unencoded_bps := u8(read_bits(r, 5) or_return)
                //fmt.println("unencoded_bps:", unencoded_bps)

                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(math.pow2_f32(partition_order)))
                } else {
                    num_samples = int((block_size / u16(math.pow2_f32(partition_order))) - u16(predictor_order))
                }

                if unencoded_bps == 0 {
                    for sample in 0..<num_samples {
                        append(&subframe_samples, i32(0))
                    }
                    continue lpc_partitions_loop
                }

                //fmt.printfln("ESCAPE reading %d samples for residual", num_samples)

                for s in 0..<num_samples {
                    // NOTE: This is signed 2's complement so we check the MSB
                    residual_sample_value := i32(read_bits(r, int(unencoded_bps)) or_return)
                    if (residual_sample_value >> (unencoded_bps - 1)) & 1 == 1 {
                        residual_sample_value = -(((~residual_sample_value) & i32(math.pow2_f32(unencoded_bps) - 1)) + 1)
                    }

                    // Restore sample values using the predictor and the residual values
                    predictor_before_shift := 0
                    c := 0
                    #reverse for coefficient in coefficients {
                        //fmt.printfln("multiplying coefficient: %d with sample: %d", coefficient, subframe_samples[sample_i + c])
                        predictor_before_shift += int(coefficient) * int(subframe_samples[sample_i + c])
                        c += 1
                    }

                    if coeff_bits_to_shift < 0 {
                        fmt.println("TRYING TO SHIFT BY A NEGATIVE NUMBER. CHECK IF THE ARITHMETIC SHIFT IS CORRECT")
                    }

                    //fmt.println("predictor before shift", predictor_before_shift)
                    //fmt.println("shifting by", coeff_bits_to_shift)

                    // NOTE: Apply arithmetic right shift in case the bits to shift are negative
                    predictor := int(math.floor(f32(predictor_before_shift) / math.pow2_f32(coeff_bits_to_shift)))
                    //predictor := predictor_before_shift >> u8(coeff_bits_to_shift)
                    //fmt.println("predictor:", predictor)

                    sample := i32(predictor) + residual_sample_value
                    append(&subframe_samples, sample)
                    //fmt.println("residual sample value:", residual_sample_value)
                    //fmt.println("sample value:", sample)
                    sample_i += 1
                }
            } else {
                //fmt.println("rice parameter:", rice_parameter)

                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(math.pow2_f32(partition_order)))
                } else {
                    num_samples = int((block_size / u16(math.pow2_f32(partition_order))) - u16(predictor_order))
                }
                //fmt.printfln("reading %d samples for residual", num_samples)

                //
                // Undo the RICE coding
                //
                previous_sample_value := 0
                for j in 0..<num_samples {
                    quotient := 0
                    // Read bits until we encounter a 1 (also called unary encoding). That's our quotient.
                    for (read_bit(r) or_return) != 1 {
                        quotient += 1
                    }
                    remainder := int(read_bits(r, int(rice_parameter)) or_return)

                    //fmt.println("quotient:", quotient)
                    //fmt.println("remainder:", remainder)

                    zigzag_encoded_value := quotient * int(math.pow2_f32(rice_parameter)) + remainder

                    // Unzigzag the residual sample values
                    residual_sample_value := zigzag_encoded_value % 2 == 0 ? zigzag_encoded_value / 2 : (zigzag_encoded_value + 1) / -2

                    // Restore sample values using the predictor and the residual values
                    predictor_before_shift := 0
                    c := 0
                    #reverse for coefficient in coefficients {
                        //fmt.printfln("multiplying coefficient: %d with sample: %d", coefficient, subframe_samples[sample_i + c])
                        predictor_before_shift += int(coefficient) * int(subframe_samples[sample_i + c])
                        c += 1
                    }

                    if coeff_bits_to_shift < 0 {
                        fmt.println("TRYING TO SHIFT BY A NEGATIVE NUMBER. CHECK IF THE ARITHMETIC SHIFT IS CORRECT")
                    }

                    //fmt.println("predictor before shift", predictor_before_shift)
                    //fmt.println("shifting by", coeff_bits_to_shift)

                    // NOTE: Apply arithmetic right shift in case the bits to shift are negative
                    predictor := int(math.floor(f32(predictor_before_shift) / math.pow2_f32(coeff_bits_to_shift)))
                    //predictor := predictor_before_shift >> u8(coeff_bits_to_shift)
                    //fmt.println("predictor:", predictor)

                    sample := predictor + residual_sample_value
                    append(&subframe_samples, i32(sample))

                    sample_i += 1
                    //fmt.println("residual sample value:", residual_sample_value)
                    //fmt.println("sample value:", sample)
                }
            }
        }

        //fmt.printfln("%d", subframe_samples)
        fmt.printfln("len: %d", len(subframe_samples))
    } else if (subframe_type >> 3) & 1 == 1 && low_3_bits <= 4 { // FIXED
        fmt.println("SUBFRAME: FIXED")
        subframe_type_str = "FIXED"
        predictor_order := low_3_bits
        fmt.println("predictor_order:", predictor_order)

        // "As a predictor makes use of samples preceding the sample that is
        //  predicted, it can only be used when enough samples are known.  As
        //  each subframe in FLAC is coded completely independently, the first
        //  few samples in each subframe cannot be predicted.  Therefore, a
        //  number of so-called warm-up samples equal to the predictor order is
        //  stored"
        bits_to_read := bps - u8(wasted_bits)
        unencoded_samples_n := bits_to_read * predictor_order
        //fmt.println("unencoded warmup samples n:", unencoded_samples_n)

        // NOTE: samples can be negative
        // TODO: should we shift to the left by the number of wasted bits??
        unencoded_warmup_sample := i32(read_bits(r, int(unencoded_samples_n)) or_return)
        if (unencoded_warmup_sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
            unencoded_warmup_sample = -(((~unencoded_warmup_sample) & i32(math.pow2_f32(bits_to_read) - 1)) + 1)
        }
        fmt.println("unencoded warmup sample:", unencoded_warmup_sample)
        fmt.printfln("unencoded warmup sample: 0x%X", unencoded_warmup_sample)

        residual_coding_method := ResidualCodingMethod(read_bits(r, 2) or_return)
        if residual_coding_method != .RICE && residual_coding_method != .RICE2 {
            return .Invalid_Residual_Coding_Method
        }
        fmt.println(residual_coding_method)

        partition_order := read_bits(r, 4) or_return
        fmt.println("parition order", partition_order)
        partitions := int(math.pow2_f32(partition_order))
        fmt.println("partitions:", partitions)
        //fmt.println("block_size:", block_size)

        fixed_partitions_loop: for i in 0..<partitions {
            rice_parameter := read_bits(r, residual_coding_method == .RICE ? 4 : 5) or_return
            if (residual_coding_method == .RICE && rice_parameter == 15) || (residual_coding_method == .RICE2 && rice_parameter == 31) {
                unencoded_bps := u8(read_bits(r, 5) or_return)
                fmt.println("unencoded_bps:", unencoded_bps)

                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(math.pow2_f32(partition_order)))
                } else {
                    num_samples = int((block_size / u16(math.pow2_f32(partition_order))) - u16(predictor_order))
                }

                if unencoded_bps == 0 {
                    for sample in 0..<num_samples {
                        append(&subframe_samples, i32(0))
                    }
                    continue fixed_partitions_loop
                }

                fmt.printfln("reading %d samples for residual", num_samples)

                for sample in 0..<num_samples {
                    // NOTE: This is signed 2's complement so we check the MSB
                    residual_sample_value := i8(read_bits(r, int(unencoded_bps)) or_return)
                    if (residual_sample_value >> (unencoded_bps - 1)) & 1 == 1 {
                        residual_sample_value = -(((~residual_sample_value) & i8(math.pow2_f32(unencoded_bps) - 1)) + 1)
                    }

                    fmt.println("residual sample value:", residual_sample_value)
                }

                return .Unencoded_BPS_For_Fixed_Subframe_Is_Unsupported

                // TODO: calculate the actual sample value by using the residual AND the previous sample value
                // TODO: add the samples to something ??
            } else {
                fmt.println("rice parameter:", rice_parameter)

                samples := 0
                if partition_order == 0 {
                    samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    samples = int(block_size / u16(math.pow2_f32(partition_order)))
                } else {
                    samples = int((block_size / u16(math.pow2_f32(partition_order))) - u16(predictor_order))
                }
                fmt.printfln("reading %d samples for residual", samples)

                //
                // Undo the RICE coding
                //
                previous_sample_value := 0
                for j in 0..<samples {
                    quotient := 0
                    // Read bits until we encounter a 1 (also called unary encoding). That's our quotient.
                    for (read_bit(r) or_return) != 1 {
                        quotient += 1
                    }
                    remainder := int(read_bits(r, int(rice_parameter)) or_return)

                    fmt.println("quotient:", quotient)
                    fmt.println("remainder:", remainder)

                    zigzag_encoded_value := quotient * int(math.pow2_f32(rice_parameter)) + remainder

                    // Unzigzag the residual sample values
                    residual_sample_value := zigzag_encoded_value % 2 == 0 ? zigzag_encoded_value / 2 : (zigzag_encoded_value + 1) / -2

                    fmt.println("residual sample value:", residual_sample_value)

                    // Restore sample values using the predictor and the residual values
                    sample_value := j == 0 ? residual_sample_value + int(unencoded_warmup_sample) : residual_sample_value + previous_sample_value
                    previous_sample_value = sample_value

                    fmt.println("sample_value:", sample_value)
                }
            }
        }
    }

    // TODO: Maybe this is slow if we have a lot of samples??
    // The cases are ranges because streaminfo can define unusual bits per sample
    for sample in subframe_samples {
        switch bps {
            case 1..=8:
                data := []u8{u8(sample)}
                os.write(output_file, data)
                md5.update(&md5_ctx, data)
            case 9..=16:
                first_byte := i8(sample & 0xFF)
                second_byte := i8((sample >> 8) & 0xFF)
                data := slice.reinterpret([]u8, []i8{first_byte, second_byte})
                os.write(output_file, data)
                md5.update(&md5_ctx, data)
            case 17..=24:
                first_byte := i8(sample & 0xFF)
                second_byte := i8((sample >> 8) & 0xFF)
                third_byte := i8((sample >> 16) & 0xFF)
                data := slice.reinterpret([]u8, []i8{first_byte, second_byte, third_byte})
                os.write(output_file, data)
                md5.update(&md5_ctx, data)
            case 25..=32:
                first_byte := i8(sample & 0xFF)
                second_byte := i8((sample >> 8) & 0xFF)
                third_byte := i8((sample >> 16) & 0xFF)
                fourth_byte := i8((sample >> 24) & 0xFF)
                data := slice.reinterpret([]u8, []i8{first_byte, second_byte, third_byte, fourth_byte})
                os.write(output_file, data)
                md5.update(&md5_ctx, data)
        }
    }

    fmt.println("cur offset", r.i)
    fmt.println("cur offset bits", r.bits_read_in_byte)

    fmt.println("FINISHED SUBFRAME:", subframe_type_str)

    return nil
}

// TODO: remove
frame_num := 0

decode_frame :: proc(r: ^Reader, streaminfo_bps: u8, streaminfo_sample_rate: u32, channels: u8) -> (err: Error) {
    //
    // Frame Header
    //
    frame_beginning := r.i

    fmt.println("FRAME START AT OFFSET:", r.i)

    data := read_data(r, u16be) or_return

    sync_code := data >> 2
    blocking_strategy := BlockingStrategy(data & 1)
    fmt.println("blocking strategy:", blocking_strategy)

    data = read_data(r, u16be) or_return
    block_size := data >> 12
    sample_rate := SampleRate((data >> 8) & 0xF)
    channel_assignment := ChannelAssignment((data >> 4) & 0xF)
    sample_size := SampleSize((data >> 1) & 7)

    coded_num := decode_extended_utf8(r) or_return
    if blocking_strategy == .VARIABLE {
        // Sample number of first sample
        // MUST NOT be larger than 36 bits unencoded or 7 bytes encoded.
        // MUST be equal to the number of samples preceding the current frame. Otherwise seeking is not possible.
        // TODO: also write a check for the number of samples so we'll probably keep track of how many samples we decoded
        // maybe the number of decoded samples can be inferred by the number of frames ?? or just use the length of 
        // the decoded_samples slice.
        if coded_num > 0x1000000000 {
            // TODO: Sample number can't be bigger than 36 bits
        }
    } else {
        // Frame number
        // MUST NOT be larger than 31 bits unencoded or 6 bytes encoded.
        // MUST be equal to the number of frames preceding the current frame. Otherwise seeking is not possible.
        // TODO: also write a check for the number of frames so we'll probably keep track of how many frames we decoded.
        if coded_num > 0x80000000 {
            // TODO: Frame number cannot be bigger than 31 bits
        }
    }

    actual_block_size: u16be
    switch block_size {
        case 1:
            actual_block_size = 192
        case 2..=5:
            actual_block_size = 576 * auto_cast (math.pow2_f32(block_size - 2))
        case 6:
            actual_block_size = auto_cast (read_byte(r) or_return) + 1
        case 7:
            actual_block_size = (read_data(r, u16be) or_return) + 1
        case 8..=15:
            actual_block_size = 256 * auto_cast (math.pow2_f32(block_size - 8))
        case:
            return .Invalid_Block_Size
    }

    //if actual_block_size < 15 && !last_frame {
        // TODO: block sizes less than 16 are only valid for the last frame and MUST NOT be used for any other frame.
    //}

    actual_sample_rate_in_Hz: u32
    switch sample_rate {
        case .USE_STREAMINFO:
            // TODO: ditto for global streaminfo
            actual_sample_rate_in_Hz = streaminfo_sample_rate
        case ._88_2kHz:
            actual_sample_rate_in_Hz = 88200
        case ._176_4kHz:
            actual_sample_rate_in_Hz = 176400
        case ._192kHz:
            actual_sample_rate_in_Hz = 192000
        case ._8kHz:
            actual_sample_rate_in_Hz = 8000
        case ._16kHz:
            actual_sample_rate_in_Hz = 16000
        case ._22_05kHz:
            actual_sample_rate_in_Hz = 22005
        case ._24kHz:
            actual_sample_rate_in_Hz = 24000
        case ._32kHz:
            actual_sample_rate_in_Hz = 32000
        case ._44_1kHz:
            actual_sample_rate_in_Hz = 44100
        case ._48kHz:
            actual_sample_rate_in_Hz = 48000
        case ._96kHz:
            actual_sample_rate_in_Hz = 96000
        case .USE_8_BITS_IN_kHz_FROM_HEADER_END:
            actual_sample_rate_in_Hz = auto_cast (read_byte(r) or_return) * 1000
        case .USE_16_BITS_IN_Hz_FROM_HEADER_END:
            actual_sample_rate_in_Hz = auto_cast (read_data(r, u16be) or_return)
        case .USE_16_BITS_IN_TENS_OF_Hz_FROM_HEADER_END:
            actual_sample_rate_in_Hz = auto_cast (read_data(r, u16be) or_return) * 10
        case .INVALID: fallthrough
        case:
            return .Invalid_Sample_Rate
    }

    // TODO: sample rate MUST NOT be 0 if the subframe contains audio.
    // a sample rate of 0 MAY be used when non-audio is represented.

    frame_header_end := r.i

    frame_header_crc := read_byte(r) or_return
    calculated_header_crc := calculate_crc8(r.s[frame_beginning:frame_header_end])

    fmt.printfln("block size bits: 0b%b", block_size)
    fmt.printfln("actual block size: %d sample(s)", actual_block_size)
    fmt.println("sample rate bits:", sample_rate)
    fmt.printfln("actual sample rate: %dHz", actual_sample_rate_in_Hz)
    fmt.println("channel assignment:", channel_assignment)

    if frame_header_crc != calculated_header_crc {
        fmt.printfln("Expected frame header CRC: 0x%X, got: 0x%X", frame_header_crc, calculated_header_crc)
        return .CRC_Mismatch
    }

    //
    // Subframes
    //
    bps: u8
    switch sample_size {
        case .USE_STREAMINFO:
            // TODO: maybe we'll store the streaminfo data in a global flac struct and then retrieve from there
            // instead of passing a parameter
            bps = streaminfo_bps
        case ._8BPS:
            bps = 8
        case ._12BPS:
            bps = 12
        case ._16BPS:
            bps = 16
        case ._20BPS:
            bps = 20
        case ._24BPS:
            bps = 24
        case ._32BPS:
            bps = 32
    }

    fmt.println("channels:", channels)
    fmt.println("bps:", bps)
    fmt.println("sample size:", sample_size)
    fmt.println("cur offset:", r.i)
    fmt.println("cur offset bits:", r.bits_read_in_byte)

    if bps != streaminfo_bps {
        return .Bits_Per_Second_Mismatch
    }

    for i in 0..<channels {
        frame_bps := bps
        // For side channels we increase the bps by 1
        // Left, mid and right channels don't need an extra bit.
        // ref: https://github.com/ietf-wg-cellar/flac-specification/blob/master/rfc_backmatter.md#first-audio-frame
        if (channel_assignment == .STEREO_SIDE_RIGHT && i == 0) ||
            ((channel_assignment == .STEREO_LEFT_SIDE || channel_assignment == .STEREO_MID_SIDE) && i == 1) {
            frame_bps += 1
        }

        decode_subframe(r, frame_bps, auto_cast actual_block_size) or_return
    }

    align_to_byte(r)

    // TODO: for stereo with side channels we must decorrelate the samples depending on the channel assignment
    // otherwise we'll be saving incorrect samples.

    //
    // Frame Footer
    //
    frame_end := r.i
    frame_crc := read_data(r, u16be) or_return
    calculated_frame_crc := calculate_crc16(r.s[frame_beginning:frame_end])

    fmt.println("FINISHED FRAME", frame_num)

    if auto_cast frame_crc != calculated_frame_crc {
        fmt.eprintfln("Expected frame CRC 0x%X, got 0x%X", frame_crc, calculated_frame_crc)
        return .CRC_Mismatch
    }

    frame_num += 1


    return nil
}

//@(optimization_mode="speed")
//calculate_crc8_simple :: proc(data: []byte) -> (crc: u8) #no_bounds_check {
//    for i in 0..<len(data) {
//        crc ~= data[i]
//
//        for j in 0..<8 {
//            if crc & 0x80 == 0x80 { // MSB is 1
//                crc = (crc << 1) ~ POLYNOMIAL8
//            } else {
//                crc <<= 1
//            }
//        }
//    }
//
//    return
//}

@(optimization_mode="speed")
calculate_crc8 :: proc(data: []byte) -> u8 #no_bounds_check {
    crc: u8 = 0

    for i in 0..<len(data) {
        crc = crc8_lookup[crc ~ data[i]]
    }

    return crc
}

@(optimization_mode="speed")
calculate_crc16 :: proc(data: []byte) -> u16 #no_bounds_check {
    crc: u16 = 0

    for i in 0..<len(data) {
        byte := u16(data[i])
        pos := (crc >> 8) ~ byte
        crc = (crc << 8) ~ crc16_lookup[pos]
    }

    return crc
}

decode_extended_utf8 :: proc(r: ^Reader) -> (decoded_num: u64, err: Error) {
    MASKX :: 0b0011_1111
    MASK2 :: 0b0001_1111
    MASK3 :: 0b0000_1111
    MASK4 :: 0b0000_0111
    MASK5 :: 0b0000_0011
    MASK6 :: 0b0000_0001

    decoded_num = u64(0)

    fmt.println("cur offset", r.i)
    fmt.println("cur offset bits", r.bits_read_in_byte)

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

    fmt.println("seq len:", utf8_sequence_len)

    if utf8_sequence_len > 0 {
        octets := make([dynamic]byte, 0, 8)
        for i := utf8_sequence_len - 1; i > 0; i -= 1 {
            append(&octets, read_byte(r) or_return)
        }

        // TODO: Implement the rest of the utf8 seq len
        switch utf8_sequence_len {
            case 2:
            fmt.printfln("first utf8 byte:0x%X", first_byte & MASK2)
                fmt.printfln("second utf8 byte:0x%X", octets[0] & MASKX)
                decoded_num = (u64(first_byte) & MASK2) << 6 | (u64(octets[0]) & MASKX)
            case 3:
                fmt.printfln("first utf8 byte:0x%X", first_byte & MASK3)
                fmt.printfln("second utf8 byte:0x%X", octets[0] & MASKX)
                fmt.printfln("third utf8 byte:0x%X", octets[1] & MASKX)
                decoded_num = (u64(first_byte) & MASK3) << 12 | (u64(octets[0]) & MASKX) << 6 | (u64(octets[1]) & MASKX)
            case 4:
                fmt.printfln("first utf8 byte:0x%X", first_byte & MASK4)
                fmt.printfln("second utf8 byte:0x%X", octets[0] & MASKX)
                fmt.printfln("third utf8 byte:0x%X", octets[1] & MASKX)
                fmt.printfln("fourth utf8 byte:0x%X", octets[2] & MASKX)
                decoded_num = (u64(first_byte) & MASK3) << 18 | (u64(octets[0]) & MASKX) << 12 | (u64(octets[1]) & MASKX) << 6 | (u64(octets[0]) & MASKX)
            case 5:
                return 0, .Unimplemented_Utf8
            case 6:
                return 0, .Unimplemented_Utf8
            case 7:
                return 0, .Unimplemented_Utf8
        }
    } else {
        decoded_num = u64(first_byte & 0x7F)
    }

    fmt.println("decoded num:", decoded_num)

    return decoded_num, nil
}

load_from_bytes :: proc(data: []byte, allocator := context.allocator) -> (err: Error) {
    r: Reader
    bytes.reader_init(&r, data)

    md5.init(&md5_ctx)
    defer md5.reset(&md5_ctx)

    header := read_data(&r, FlacHeader) or_return
    if header.magic != FLAC_MAGIC {
        return .Invalid_Signature
    }

    fmt.println(header)

    /*bit_field u64be {
        sample_rate: u32be | 20,
        num_channel_minus_one: u8 | 3,
        bits_per_sample_minus_one: u8 | 5,
        total_samples: u64be | 36,
    }*/
    sample_rate := header.streaminfo.sr_chan_bps_ts >> 44
    num_channel_minus_one := (header.streaminfo.sr_chan_bps_ts >> 41) & 7
    bits_per_sample_minus_one := (header.streaminfo.sr_chan_bps_ts >> 36) & 0x1F
    total_samples := header.streaminfo.sr_chan_bps_ts & 0xFFFFFFFFF

    fmt.println("sample rate:", sample_rate)
    fmt.println("channels:", num_channel_minus_one + 1)
    fmt.println("bits per sample:", bits_per_sample_minus_one + 1)
    fmt.println("total samples:", total_samples)

    /*bit_field u32be {
        last_block: bool | 1,
        type: BlockType | 7,
        length: u32be | 24,
    }*/
    streaminfo_header := MetadataBlockHeader{
        last_block = bool(header.streaminfo_header >> 31),
        type = BlockType((header.streaminfo_header >> 24) & 0x7F),
        length = u32(header.streaminfo_header & 0xFFFFFF),
    }

    if streaminfo_header.type != .STREAMINFO {
        return .Missing_StreamInfo
    }

    last_block := streaminfo_header.last_block
    for !last_block {
        md_block_hdr := read_data(&r, u32be) or_return
        metadata_block_header := MetadataBlockHeader{
            last_block = bool(md_block_hdr >> 31),
            type = BlockType((md_block_hdr >> 24) & 0x7F),
            length = u32(md_block_hdr & 0xFFFFFF),
        }
        fmt.println("Metadata block", metadata_block_header)

        last_block = cast(bool)(metadata_block_header.last_block)

        switch metadata_block_header.type {
            case .STREAMINFO:
                // Do nothing, we already parse the mandatory streaminfo metadata
            case .PADDING:
                fmt.printfln("Skipping %d bytes of padding data", metadata_block_header.length)
                bytes.reader_seek(&r, auto_cast metadata_block_header.length, .Current)
            case .APPLICATION:
                //app_id := read_slice(&r, 4) or_return
                //fmt.println("Found application with ID:", string(app_id))
                fmt.printfln("Skipping %d bytes of application metadata block", metadata_block_header.length)
                bytes.reader_seek(&r, auto_cast metadata_block_header.length, .Current)
                // TODO: handle the application data
            case .SEEKTABLE:
                // TODO: check for size mismatch?
                seekpoints := metadata_block_header.length / 18
                fmt.printfln("we have %d seekpoints", seekpoints)
                for i in 0..<seekpoints {
                    seekpoint := read_data(&r, Seekpoint) or_return
                    fmt.println(seekpoint)
                }
            case .VORBIS_COMMENT:
                // TODO: save this info to a struct
                vendor_name_len := read_data(&r, u32le) or_return
                vendor_name := string(read_slice(&r, auto_cast vendor_name_len) or_return)
                user_comment_list_len := read_data(&r, u32le) or_return

                actual_size := 4 + vendor_name_len + 4

                for i in 0..<user_comment_list_len {
                    comment_len := read_data(&r, u32le) or_return
                    comment := string(read_slice(&r, auto_cast comment_len) or_return)
                    fmt.println(comment)
                    actual_size += 4 + comment_len
                }
                if metadata_block_header.length != u32(actual_size) {
                    // TODO: should this be a warning instead of an error that halts the decoding?
                    // I think so, the comment isn't crucial to the decoding process.
                    fmt.println("Metadata header length mismatch!")
                    fmt.printfln("Expected size: %d, Got %d", metadata_block_header.length, actual_size)
                    return .Metadata_Block_Length_Mismatch
                }
                // TODO: framing bit??
                fmt.println(vendor_name)
            case .CUESHEET:
                // TODO: save this to a struct
                // + there's some CD-DA stuff that we need to consider I think
                cuesheet := read_data(&r, CueSheet) or_return
                if cuesheet.num_tracks < 1 {
                    // TODO: should this be a warning instead of an error that halts the decoding?
                    return .Missing_Lead_Out_Track
                }
                fmt.println(cuesheet)
                for i in 0..<cuesheet.num_tracks {
                    track := read_data(&r, CueSheetTrack) or_return
                    for i in 0..<track.num_track_index_points {
                        track_index := read_data(&r, CueSheetTrackIndex) or_return
                        fmt.println(track_index)
                    }
                    fmt.println(track)
                }
            case .PICTURE:
                // TODO: save the pic data into a struct
                pic_type := read_data(&r, PictureType) or_return
                mime_len := read_data(&r, u32be) or_return
                mimetype := string(read_slice(&r, auto_cast mime_len) or_return)
                desc_len := read_data(&r, u32be) or_return
                desc := string(read_slice(&r, auto_cast desc_len) or_return)
                width := read_data(&r, u32be) or_return
                height := read_data(&r, u32be) or_return
                depth := read_data(&r, u32be) or_return
                num_colors := read_data(&r, u32be) or_return
                data_len := read_data(&r, u32be) or_return
                data := read_slice(&r, auto_cast data_len) or_return
                fmt.println(pic_type)
                fmt.println(mimetype)
                fmt.println(desc)
                fmt.println(width)
                fmt.println(height)
                fmt.println(depth)
                fmt.println(num_colors)
                fmt.println(data_len)
                //fmt.println(data)
            case .INVALID:
                fmt.eprintln("Invalid block type")
                bytes.reader_seek(&r, auto_cast metadata_block_header.length, .Current)
            case:
                fmt.printfln("Skipping %d bytes of Unknown metadata block", metadata_block_header.length)
                bytes.reader_seek(&r, auto_cast metadata_block_header.length, .Current)
        }
    }

    // Yucky
    err = decode_frame(&r, u8(bits_per_sample_minus_one + 1), u32(sample_rate), u8(num_channel_minus_one + 1))
    for err == nil {
        err = decode_frame(&r, u8(bits_per_sample_minus_one + 1), u32(sample_rate), u8(num_channel_minus_one + 1))
    }

    if err != .EOF {
        return err
    }

    //
    // Validate the decoded audio data's md5
    //
    calculated_md5 := make([]byte, 16)
    md5.final(&md5_ctx, calculated_md5)

    if mem.compare(calculated_md5, header.streaminfo.md5[:]) != 0 {
        fmt.printfln("expected: %X", header.streaminfo.md5)
        fmt.printfln("got: %X", calculated_md5)
        return .MD5_Mismatch
    }

    return nil
}

load_from_file :: proc(filename: string, allocator := context.allocator) -> (err: Error) {
    context.allocator = allocator

    output_file, _ = os.open("output.raw", os.O_WRONLY | os.O_CREATE | os.O_TRUNC, 0o664)
    defer os.close(output_file)

    data, ok := os.read_entire_file(filename)
    defer delete(data)

    if ok {
        return load_from_bytes(data)
    } else {
        return .Unable_To_Read_File
    }
}
