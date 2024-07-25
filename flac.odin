package flac

import "core:bytes"
import "core:bufio"
import "core:crypto/legacy/md5"
import "core:fmt"
import "core:io"
import "core:mem"
import "core:os"
import "core:time"

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
    CRC_Mismatch,
    MD5_Mismatch,
    Unsupported_BPS, // Remove when implemented
    Unencoded_BPS_For_Fixed_Subframe_Is_Unsupported, // Remove when implemented
    Invalid_Residual_Coding_Method,
    Invalid_Block_Size,
    Bits_Per_Second_Mismatch,
    Negative_Coefficient_Bits_To_Shift,
}

/*
Option:
    `.skip_md5_check`
        Skips checking the MD5 hash of the decoded sample data.
        Offers a slight performance increase but will not error if the data is incorrect.
    `.only_return_metadata`
        Returns all metadata of a FLAC stream without decoding the audio data.
*/

Option :: enum {
    skip_md5_check,
    only_return_metadata,
}

Options :: bit_set[Option]

PictureType :: enum u32 {
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

Flac :: struct {
    metadata: FlacMetadata,
    samples:  [dynamic]i32,
}

FlacMetadata :: struct {
    total_samples:   u64,
    bits_per_sample: u8,
    channels:        u8,
    sample_rate:     u32,
    expected_md5:    [16]byte,
    calculated_md5:  [16]byte,
    pictures:        []Picture,
    vendor_name:     string,
    vorbis_comments: []string,
}

Picture :: struct {
    type: PictureType,
    mimetype: string,
    description: string,
    width: u32,
    height: u32,
    depth: u32,
    num_colors: u32,
    data: []byte,
}

Frame :: struct {
    channels: u8,
    sample_rate: u32,
    samples: []i32,
}

@(private)
decode_subframe :: proc(r: ^Reader, bps: u8, block_size: u16) -> (samples: []i32, err: Error) #no_bounds_check {
    subframe_samples := make([]i32, block_size)

    data := read_bits(r, 8) or_return

    subframe_type := (data & 0x7E) >> 1
    low_3_bits := subframe_type & 7
    has_wasted_bits := data & 1 == 1
    wasted_bits := 0

    if has_wasted_bits {
        for (read_bits(r, 1) or_return) != 1 {
            wasted_bits += 1
        }
        wasted_bits += 1
    }

    if subframe_type == 0 {     // CONSTANT
        bits_to_read := int(bps) - wasted_bits
        sample := i32(read_bits(r, uint(bits_to_read)) or_return)
        if sample > 0 && (sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
            sample = -(((~sample) & (i32(pow2(bits_to_read)) - 1)) + 1)
        }
        copy(subframe_samples, []i32{sample})
    } else if subframe_type == 1 {     // VERBATIM
        // TODO: this will break if bits per sample is anything BUT 16
        if bps < 16 || bps > 17 {
            return nil, .Unsupported_BPS
        }
        for sample in 0..<block_size {
            bits_to_read := int(bps) - wasted_bits

            // negative samples ??
            unencoded_subblock := i32((read_bits(r, uint(bits_to_read)) or_return))

            subframe_samples[sample] = unencoded_subblock
        }
    } else if (subframe_type >> 5) & 1 == 1 {     // LPC
        sample_i := 0
        predictor_order := (subframe_type & 0x1F) + 1

        bits_to_read := int(bps) - wasted_bits
        for s in 0..<predictor_order {
            // NOTE: samples are signed so we do 2's complement
            unencoded_warmup_sample := i32(read_bits(r, uint(bits_to_read)) or_return)
            if unencoded_warmup_sample > 0 && (unencoded_warmup_sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
                unencoded_warmup_sample = -(((~unencoded_warmup_sample) & (i32(pow2(bits_to_read)) - 1)) + 1)
            }

            subframe_samples[s] = unencoded_warmup_sample
        }

        coeff_precision_minus_one := u8(read_bits(r, 4) or_return)
        if coeff_precision_minus_one == 0xF {
            return nil, .Invalid_Coefficient_Precision
        }
        coeff_precision := coeff_precision_minus_one + 1

        coeff_bits_to_shift := i8(read_bits(r, 5) or_return)
        // NOTE: This is signed 2's complement so we check the MSB
        // NOTE: This is apparently supposed to never be a negative number according to the (new?) spec.
        // TODO: For now we just error if the shift value is negative. I have to find test cases to be sure.
        if (coeff_bits_to_shift >> (5 - 1)) & 1 == 1 {
            return nil, .Negative_Coefficient_Bits_To_Shift
        }

        coefficients := make([]i32, predictor_order)
        defer delete(coefficients)

        for i in 0..<predictor_order {
            unencoded_coefficient := i32(read_bits(r, uint(coeff_precision)) or_return)
            // Ditto
            if unencoded_coefficient > 0 && (unencoded_coefficient >> (coeff_precision - 1)) & 1 == 1 {
                unencoded_coefficient = -(((~unencoded_coefficient) & (i32(pow2(coeff_precision)) - 1)) + 1)
            }
            coefficients[i] = unencoded_coefficient
        }

        residual_coding_method := ResidualCodingMethod(read_bits(r, 2) or_return)
        if residual_coding_method != .RICE && residual_coding_method != .RICE2 {
            return nil, .Invalid_Residual_Coding_Method
        }

        partition_order := read_bits(r, 4) or_return
        partitions := pow2(partition_order)

        lpc_partitions_loop: for i in 0..<partitions {
            rice_parameter := read_bits(r, residual_coding_method == .RICE ? 4 : 5) or_return
            if (residual_coding_method == .RICE && rice_parameter == 15) ||
               (residual_coding_method == .RICE2 && rice_parameter == 31) {
                unencoded_bps := u8(read_bits(r, 5) or_return)

                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(pow2(partition_order)))
                } else {
                    num_samples = int((block_size / u16(pow2(partition_order))) - u16(predictor_order))
                }

                if unencoded_bps == 0 {
                    // Since we initialize a slice to zeros we just have to skip over those zeroed samples in the slice.
                    sample_i += num_samples
                    continue lpc_partitions_loop
                }

                for s in 0..<num_samples {
                    // NOTE: This is signed 2's complement so we check the MSB
                    residual_sample_value := i32(read_bits(r, uint(unencoded_bps)) or_return)
                    if residual_sample_value > 0 && (residual_sample_value >> (unencoded_bps - 1)) & 1 == 1 {
                        residual_sample_value = -(((~residual_sample_value) & (i32(pow2(unencoded_bps)) - 1)) + 1)
                    }

                    // Restore sample values using the predictor and the residual values
                    predictor_before_shift := 0
                    c := 0
                    #reverse for coefficient in coefficients {
                        predictor_before_shift += int(coefficient) * int(subframe_samples[sample_i + c])
                        c += 1
                    }

                    predictor := predictor_before_shift >> u8(coeff_bits_to_shift)

                    sample := i32(predictor + int(residual_sample_value))
                    subframe_samples[sample_i + int(predictor_order)] = sample
                    sample_i += 1
                }
            } else {
                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(pow2(partition_order)))
                } else {
                    num_samples = int((block_size / u16(pow2(partition_order))) - u16(predictor_order))
                }

                //
                // Undo the RICE coding
                //
                for s in 0..<num_samples {
                    quotient := 0
                    // Read bits until we encounter a 1 (also called unary encoding). That's our quotient.
                    for (read_bits(r, 1) or_return) != 1 {
                        quotient += 1
                    }
                    remainder := int(read_bits(r, uint(rice_parameter)) or_return)

                    zigzag_encoded_value := quotient * pow2(rice_parameter) + remainder

                    // Unzigzag the residual sample values
                    residual_sample_value :=
                        zigzag_encoded_value % 2 == 0 ? zigzag_encoded_value / 2 : (zigzag_encoded_value + 1) / -2

                    // Restore sample values using the predictor and the residual values
                    predictor_before_shift := 0
                    c := 0
                    #reverse for coefficient in coefficients {
                        predictor_before_shift += int(coefficient) * int(subframe_samples[sample_i + c])
                        c += 1
                    }

                    predictor := predictor_before_shift >> u8(coeff_bits_to_shift)

                    sample := predictor + residual_sample_value
                    subframe_samples[sample_i + int(predictor_order)] = i32(sample)

                    sample_i += 1
                }
            }
        }
    } else if (subframe_type >> 3) & 1 == 1 && low_3_bits <= 4 {     // FIXED
        sample_i := 0
        predictor_order := low_3_bits

        bits_to_read := int(bps) - wasted_bits

        // NOTE: samples can be negative
        for sample in 0..<predictor_order {
            unencoded_warmup_sample := i32(read_bits(r, uint(bits_to_read)) or_return)
            if unencoded_warmup_sample > 0 && (unencoded_warmup_sample >> (uint(bits_to_read) - 1)) & 1 == 1 {
                unencoded_warmup_sample = -(((~unencoded_warmup_sample) & (i32(pow2(bits_to_read)) - 1)) + 1)
            }

            subframe_samples[sample] = unencoded_warmup_sample
        }

        residual_coding_method := ResidualCodingMethod(read_bits(r, 2) or_return)
        if residual_coding_method != .RICE && residual_coding_method != .RICE2 {
            return nil, .Invalid_Residual_Coding_Method
        }

        partition_order := read_bits(r, 4) or_return
        partitions := pow2(partition_order)

        fixed_partitions_loop: for i in 0..<partitions {
            rice_parameter := read_bits(r, residual_coding_method == .RICE ? 4 : 5) or_return
            if (residual_coding_method == .RICE && rice_parameter == 15) ||
               (residual_coding_method == .RICE2 && rice_parameter == 31) {
                unencoded_bps := u8(read_bits(r, 5) or_return)

                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(pow2(partition_order)))
                } else {
                    num_samples = int((block_size / u16(pow2(partition_order))) - u16(predictor_order))
                }

                if unencoded_bps == 0 {
                    // Since we initialize a slice to zeros we just have to skip over those zeroed samples in the slice.
                    sample_i += num_samples
                    continue fixed_partitions_loop
                }

                for s in 0..<num_samples {
                    // NOTE: This is signed 2's complement so we check the MSB
                    residual_sample_value := i8(read_bits(r, uint(unencoded_bps)) or_return)
                    if residual_sample_value > 0 && (residual_sample_value >> (unencoded_bps - 1)) & 1 == 1 {
                        residual_sample_value = -(((~residual_sample_value) & (i8(pow2(unencoded_bps)) - 1)) + 1)
                    }
                }

                return nil, .Unencoded_BPS_For_Fixed_Subframe_Is_Unsupported

                // TODO: calculate the actual sample value by using the residual AND the previous sample value
                // TODO: add the samples to something ??
            } else {
                num_samples := 0
                if partition_order == 0 {
                    num_samples = int(block_size - u16(predictor_order))
                } else if i != 0 {
                    num_samples = int(block_size / u16(pow2(partition_order)))
                } else {
                    num_samples = int((block_size / u16(pow2(partition_order))) - u16(predictor_order))
                }

                //
                // Undo the RICE coding
                //
                for s in 0..<num_samples {
                    quotient := 0
                    // Read bits until we encounter a 1 (also called unary encoding). That's our quotient.
                    for (read_bits(r, 1) or_return) != 1 {
                        quotient += 1
                    }
                    remainder := int(read_bits(r, uint(rice_parameter)) or_return)

                    zigzag_encoded_value := quotient * pow2(rice_parameter) + remainder

                    // Unzigzag the residual sample values
                    residual_sample_value :=
                        zigzag_encoded_value % 2 == 0 ? zigzag_encoded_value / 2 : (zigzag_encoded_value + 1) / -2

                    sample_value := 0

                    // Restore sample values using the predictor and the residual values
                    if predictor_order == 0 {
                        sample_value = residual_sample_value
                    } else {
                        predictor := 0
                        c := 0
                        #reverse for coefficient in fixed_coefficients[predictor_order - 1] {
                            predictor += int(coefficient) * int(subframe_samples[sample_i + c])
                            c += 1
                        }

                        sample_value = (predictor + residual_sample_value)
                    }

                    subframe_samples[sample_i + int(predictor_order)] = i32(sample_value)

                    sample_i += 1
                }
            }
        }
    }

    // The shifting has to happen after predicting all the sample values.
    for &sample in subframe_samples {
        sample <<= uint(wasted_bits)
    }

    return subframe_samples, nil
}

@(private)
decode_frame :: proc(
    r: ^Reader,
    flac: ^Flac,
    md5_ctx: ^md5.Context,
    options: Options,
) -> (
    err: Error,
) #no_bounds_check {
    //
    // Frame Header
    //
    tee_r: io.Tee_Reader
    crc_buffer: bytes.Buffer
    bytes.buffer_init_allocator(&crc_buffer, 0, 128)
    defer bytes.buffer_destroy(&crc_buffer)
    crc := bytes.buffer_to_stream(&crc_buffer)
    r := &Reader{
        r = io.tee_reader_init(&tee_r, r, crc),
        buf = r.buf,
        x = r.x,
        n = r.n,
    }

    data := read_data(r, u16be) or_return

    sync_code := data >> 2
    blocking_strategy := BlockingStrategy(data & 1)

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
            actual_block_size = 576 * auto_cast (pow2(block_size - 2))
        case 6:
            actual_block_size = auto_cast (read_bits(r, 8) or_return) + 1
        case 7:
            actual_block_size = (read_data(r, u16be) or_return) + 1
        case 8..=15:
            actual_block_size = 256 * auto_cast (pow2(block_size - 8))
        case:
            return .Invalid_Block_Size
    }

    //if actual_block_size < 15 && !last_frame {
        // TODO: block sizes less than 16 are only valid for the last frame and MUST NOT be used for any other frame.
    //}

    actual_sample_rate_in_Hz: u32
    switch sample_rate {
        case .USE_STREAMINFO:
            actual_sample_rate_in_Hz = flac.metadata.sample_rate
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
            actual_sample_rate_in_Hz = auto_cast (read_bits(r, 8) or_return) * 1000
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

    crc8_bytes := bytes.buffer_to_bytes(&crc_buffer)
    frame_header_crc := u8(read_bits(r, 8) or_return)
    calculated_header_crc := calculate_crc8(crc8_bytes)

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
            bps = flac.metadata.bits_per_sample
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

    if bps != flac.metadata.bits_per_sample {
        return .Bits_Per_Second_Mismatch
    }

    frame_channels := flac.metadata.channels
    switch channel_assignment {
        case .MONO:
            frame_channels = 1
        case ._3CHANNELS:
            frame_channels = 3
        case ._4CHANNELS:
            frame_channels = 4
        case ._5CHANNELS:
            frame_channels = 5
        case ._6CHANNELS:
            frame_channels = 6
        case ._7CHANNELS:
            frame_channels = 7
        case ._8CHANNELS:
            frame_channels = 8
        case ._2CHANNELS: fallthrough
        case .STEREO_LEFT_SIDE: fallthrough
        case .STEREO_SIDE_RIGHT: fallthrough
        case .STEREO_MID_SIDE:
            frame_channels = 2
    }

    if frame_channels != flac.metadata.channels {
        // TODO: warning or error?
        // we have a faulty file that says it has 5 channels but subframes all say they got 1
        // we also have an two uncommon files with increasing and decreasing number of channels
        // uncommon are supposed to be unusual but still valid FLAC files. why is that first one faulty then???
        // so many questions...
    }

    subframes := make([][]i32, frame_channels)
    defer delete(subframes)
    for i in 0..<frame_channels {
        frame_bps := bps
        // For side channels we increase the bps by 1
        // Left, mid and right channels don't need an extra bit.
        // ref: https://github.com/ietf-wg-cellar/flac-specification/blob/master/rfc_backmatter.md#first-audio-frame
        if (channel_assignment == .STEREO_SIDE_RIGHT && i == 0) ||
           ((channel_assignment == .STEREO_LEFT_SIDE || channel_assignment == .STEREO_MID_SIDE) && i == 1) {
            frame_bps += 1
        }

        subframes[i] = decode_subframe(r, frame_bps, auto_cast actual_block_size) or_return
    }

    align_to_byte(r)

    correlate(subframes, channel_assignment)

    // Write the samples interleaved.
    for i in 0..<len(subframes[0]) {
        for subframe, sf in subframes {
            sample := subframe[i]
            append(&flac.samples, sample)

            if .skip_md5_check not_in options {
                switch bps {
                    case 1..=8:
                        md5.update(md5_ctx, {u8(sample)})
                    case 9..=16:
                        first_byte := u8(sample & 0xFF)
                        second_byte := u8((sample >> 8) & 0xFF)
                        md5.update(md5_ctx, {first_byte, second_byte})
                    case 17..=24:
                        first_byte := u8(sample & 0xFF)
                        second_byte := u8((sample >> 8) & 0xFF)
                        third_byte := u8((sample >> 16) & 0xFF)
                        md5.update(md5_ctx, {first_byte, second_byte, third_byte})
                    case 25..=32:
                        data := transmute([4]u8)sample
                        md5.update(md5_ctx, data[:])
                    case:
                        fmt.println("INVALID BPS")
                        os.exit(1)
                }
            }
        }
    }

    for subframe in subframes {
        delete(subframe)
    }

    //
    // Frame Footer
    //
    crc16_bytes := bytes.buffer_to_bytes(&crc_buffer)
    frame_crc := u16(read_data(r, u16be) or_return)
    calculated_frame_crc := calculate_crc16(crc16_bytes)

    if frame_crc != calculated_frame_crc {
        fmt.eprintfln("Expected frame CRC 0x%X, got 0x%X", frame_crc, calculated_frame_crc)
        return .CRC_Mismatch
    }

    return nil
}

@(private)
correlate :: proc(subframes: [][]i32, channel_assignment: ChannelAssignment) {
    // Undo Stereo Decorrelation
    #partial switch channel_assignment {
        case .STEREO_MID_SIDE:
            for i in 0..<len(subframes[1]) {
                // These MUST be cast to i64 because overflows can happen if we use i32 or u32
                mid := i64(subframes[0][i]) << 1
                side := i64(subframes[1][i])
                // Since side is a signed integer here. We check for oddity by looking at the LSB instead of doing a check for 1 and -1
                if side & 1 == 1 {
                    mid += 1
                }

                left := i32((mid + side) >> 1)
                right := (mid - side) >> 1

                subframes[0][i] = left
                subframes[1][i] = i32(right)
            }
        case .STEREO_SIDE_RIGHT:
            for i in 0..<len(subframes[0]) {
                side := subframes[0][i]
                right := subframes[1][i]
                subframes[0][i] = side + right
            }
        case .STEREO_LEFT_SIDE:
            for i in 0..<len(subframes[1]) {
                left := subframes[0][i]
                side := subframes[1][i]
                subframes[1][i] = left - side
            }
    }
}

@(private)
read_metadata :: proc(r: ^Reader, buffered := false, allocator := context.allocator) -> (flac: ^Flac, err: Error) {
    header := read_data(r, FlacHeader) or_return
    if header.magic != FLAC_MAGIC {
        return nil, .Invalid_Signature
    }

    sample_rate := header.streaminfo.sr_chan_bps_ts >> 44
    num_channel_minus_one := (header.streaminfo.sr_chan_bps_ts >> 41) & 7
    bits_per_sample_minus_one := (header.streaminfo.sr_chan_bps_ts >> 36) & 0x1F
    total_samples := header.streaminfo.sr_chan_bps_ts & 0xFFFFFFFFF

    streaminfo_header := MetadataBlockHeader {
        last_block = bool(header.streaminfo_header >> 31),
        type       = BlockType((header.streaminfo_header >> 24) & 0x7F),
        length     = u32(header.streaminfo_header & 0xFFFFFF),
    }

    if streaminfo_header.type != .STREAMINFO {
        return flac, .Missing_StreamInfo
    }

    if flac == nil {
        flac = new(Flac)
    }

    flac.metadata.channels = u8(num_channel_minus_one + 1)
    flac.metadata.sample_rate = u32(sample_rate)
    flac.metadata.bits_per_sample = u8(bits_per_sample_minus_one + 1)
    flac.metadata.total_samples = u64(total_samples)
    flac.metadata.expected_md5 = header.streaminfo.md5

    pictures := make([dynamic]Picture, 0, 2, allocator)
    last_block := streaminfo_header.last_block
    for !last_block {
        md_block_hdr := read_data(r, u32be) or_return
        metadata_block_header := MetadataBlockHeader {
            last_block = bool(md_block_hdr >> 31),
            type       = BlockType((md_block_hdr >> 24) & 0x7F),
            length     = u32(md_block_hdr & 0xFFFFFF),
        }

        last_block = cast(bool)(metadata_block_header.last_block)

        switch metadata_block_header.type {
            case .STREAMINFO:
                // Do nothing, we already parse the mandatory streaminfo metadata
            case .PADDING:
                if buffered {
                    reader := cast(^bufio.Reader)r.data
                    skipped := bufio.reader_discard(reader, int(metadata_block_header.length)) or_return
                } else {
                    reader := cast(^bytes.Reader)r.data
                    skipped := bytes.reader_seek(reader, i64(metadata_block_header.length), .Current) or_return
                }
            case .APPLICATION:
                //app_id := read_slice(&r, 4) or_return
                //fmt.println("Found application with ID:", string(app_id))
                //fmt.printfln("Skipping %d bytes of application metadata block", metadata_block_header.length)
                // TODO: handle the application data
                if buffered {
                    reader := cast(^bufio.Reader)r.data
                    skipped := bufio.reader_discard(reader, int(metadata_block_header.length)) or_return
                } else {
                    reader := cast(^bytes.Reader)r.data
                    skipped := bytes.reader_seek(reader, i64(metadata_block_header.length), .Current) or_return
                }
            case .SEEKTABLE:
                seekpoints := metadata_block_header.length / 18
                //fmt.printfln("we have %d seekpoints", seekpoints)
                actual_size := 0
                for i in 0..<seekpoints {
                    _ = read_data(r, Seekpoint) or_return
                    actual_size += size_of(Seekpoint)
                    //fmt.println(seekpoint)
                }

                if metadata_block_header.length != u32(actual_size) {
                    fmt.eprintln("Seektable metadata header length mismatch!")
                    fmt.eprintfln("Expected size: %d, Got %d", metadata_block_header.length, actual_size)
                }
            case .VORBIS_COMMENT:
                vendor_name_len := read_data(r, u32le) or_return
                vendor_name_slice := make([]byte, vendor_name_len)
                read_slice(r, vendor_name_slice) or_return
                vendor_name := string(vendor_name_slice)
                user_comment_list_len := read_data(r, u32le) or_return

                actual_size := 4 + vendor_name_len + 4

                comments := make([]string, user_comment_list_len)
                for i in 0..<user_comment_list_len {
                    comment_len := read_data(r, u32le) or_return
                    comment_slice := make([]byte, comment_len)
                    read_slice(r, comment_slice) or_return
                    comment := string(comment_slice)
                    actual_size += 4 + comment_len

                    comments[i] = comment
                }
                flac.metadata.vorbis_comments = comments
                flac.metadata.vendor_name = vendor_name
                if metadata_block_header.length != u32(actual_size) {
                    fmt.eprintln("Vorbis metadata header length mismatch!")
                    fmt.eprintfln("Expected size: %d, Got %d", metadata_block_header.length, actual_size)
                }
                // TODO: framing bit??
            case .CUESHEET:
                // TODO: save this to a struct
                // + there's some CD-DA stuff that we need to consider I think
                cuesheet := read_data(r, CueSheet) or_return
                if cuesheet.num_tracks < 1 {
                    // TODO: should this be a warning instead of an error that halts the decoding?
                    return flac, .Missing_Lead_Out_Track
                }
                //fmt.println(cuesheet)
                for i in 0..<cuesheet.num_tracks {
                    track := read_data(r, CueSheetTrack) or_return
                    for i in 0..<track.num_track_index_points {
                        _ = read_data(r, CueSheetTrackIndex) or_return
                        //fmt.println(track_index)
                    }
                    //fmt.println(track)
                }
            case .PICTURE:
                pic_type := PictureType(read_data(r, u32be) or_return)
                mime_len := read_data(r, u32be) or_return
                mimetype_slice := make([]byte, mime_len)
                read_slice(r, mimetype_slice) or_return
                mimetype := string(mimetype_slice)
                desc_len := read_data(r, u32be) or_return
                desc_slice := make([]byte, desc_len)
                read_slice(r, desc_slice) or_return
                desc := string(desc_slice)
                metadata := read_data(r, PictureMetadata) or_return
                data := make([]byte, metadata.data_len)
                read_slice(r, data) or_return
                picture := Picture{
                    type = pic_type,
                    mimetype = mimetype,
                    description = desc,
                    width = u32(metadata.width),
                    height = u32(metadata.height),
                    depth = u32(metadata.depth),
                    num_colors = u32(metadata.num_colors),
                    data = data,
                }
                append(&pictures, picture)
            case .INVALID:
                fmt.eprintln("Invalid block type")
                if buffered {
                    reader := cast(^bufio.Reader)r.data
                    skipped := bufio.reader_discard(reader, int(metadata_block_header.length)) or_return
                } else {
                    reader := cast(^bytes.Reader)r.data
                    skipped := bytes.reader_seek(reader, i64(metadata_block_header.length), .Current) or_return
                }
            case:
                fmt.printfln("Skipping %d bytes of Unknown metadata block", metadata_block_header.length)
                if buffered {
                    reader := cast(^bufio.Reader)r.data
                    skipped := bufio.reader_discard(reader, int(metadata_block_header.length)) or_return
                } else {
                    reader := cast(^bytes.Reader)r.data
                    skipped := bytes.reader_seek(reader, i64(metadata_block_header.length), .Current) or_return
                }
        }
    }

    flac.metadata.pictures = pictures[:]

    return flac, nil
}

read_next_frame :: proc(r: ^Reader, flac: ^Flac, allocator := context.allocator) -> (frame: Frame, err: Error) {
    //
    // Frame Header
    //
    context.allocator = allocator
    tee_r: io.Tee_Reader

    crc_buffer: Buffer
    // NOTE: using the default heap allocator here causes a use-after-free bug on files subset/05, subset/06, and subset/25
    // No idea what the cause of the bug is. I am inclined to believe that it's a bug of the default heap allocator but
    // maybe my code is fucking up the memory so bad it makes it seems that way.
    buffer_init_allocator(&crc_buffer, 0, 128)

    crc := buffer_to_stream(&crc_buffer)
    r := &Reader{
        r = io.tee_reader_init(&tee_r, r, crc),
        buf = r.buf,
        x = r.x,
        n = r.n,
    }

    data := read_data(r, u16be) or_return

    sync_code := data >> 2
    blocking_strategy := BlockingStrategy(data & 1)

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
            actual_block_size = 576 * auto_cast (pow2(block_size - 2))
        case 6:
            actual_block_size = auto_cast (read_bits(r, 8) or_return) + 1
        case 7:
            actual_block_size = (read_data(r, u16be) or_return) + 1
        case 8..=15:
            actual_block_size = 256 * auto_cast (pow2(block_size - 8))
        case:
            return {}, .Invalid_Block_Size
    }

    //if actual_block_size < 15 && !last_frame {
        // TODO: block sizes less than 16 are only valid for the last frame and MUST NOT be used for any other frame.
    //}

    actual_sample_rate_in_Hz: u32
    switch sample_rate {
        case .USE_STREAMINFO:
            actual_sample_rate_in_Hz = flac.metadata.sample_rate
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
            actual_sample_rate_in_Hz = auto_cast (read_bits(r, 8) or_return) * 1000
        case .USE_16_BITS_IN_Hz_FROM_HEADER_END:
            actual_sample_rate_in_Hz = auto_cast (read_data(r, u16be) or_return)
        case .USE_16_BITS_IN_TENS_OF_Hz_FROM_HEADER_END:
            actual_sample_rate_in_Hz = auto_cast (read_data(r, u16be) or_return) * 10
        case .INVALID: fallthrough
        case:
            return {}, .Invalid_Sample_Rate
    }

    // TODO: sample rate MUST NOT be 0 if the subframe contains audio.
    // a sample rate of 0 MAY be used when non-audio is represented.

    crc8_bytes := buffer_to_bytes(&crc_buffer)
    frame_header_crc := u8(read_bits(r, 8) or_return)
    calculated_header_crc := calculate_crc8(crc8_bytes)

    if frame_header_crc != calculated_header_crc {
        fmt.printfln("Expected frame header CRC: 0x%X, got: 0x%X", frame_header_crc, calculated_header_crc)
        return {}, .CRC_Mismatch
    }

    //
    // Subframes
    //
    bps: u8
    switch sample_size {
        case .USE_STREAMINFO:
            bps = flac.metadata.bits_per_sample
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

    if bps != flac.metadata.bits_per_sample {
        return {}, .Bits_Per_Second_Mismatch
    }

    frame_channels := flac.metadata.channels
    switch channel_assignment {
        case .MONO:
            frame_channels = 1
        case ._3CHANNELS:
            frame_channels = 3
        case ._4CHANNELS:
            frame_channels = 4
        case ._5CHANNELS:
            frame_channels = 5
        case ._6CHANNELS:
            frame_channels = 6
        case ._7CHANNELS:
            frame_channels = 7
        case ._8CHANNELS:
            frame_channels = 8
        case ._2CHANNELS: fallthrough
        case .STEREO_LEFT_SIDE: fallthrough
        case .STEREO_SIDE_RIGHT: fallthrough
        case .STEREO_MID_SIDE:
            frame_channels = 2
    }

    if frame_channels != flac.metadata.channels {
        // TODO: warning or error?
        // we have a faulty file that says it has 5 channels but subframes all say they got 1
        // we also have an two uncommon files with increasing and decreasing number of channels
        // uncommon are supposed to be unusual but still valid FLAC files. why is that first one faulty then???
        // so many questions...
    }

    subframes := make([][]i32, frame_channels)
    defer delete(subframes)
    for i in 0..<frame_channels {
        frame_bps := bps
        // For side channels we increase the bps by 1
        // Left, mid and right channels don't need an extra bit.
        // ref: https://github.com/ietf-wg-cellar/flac-specification/blob/master/rfc_backmatter.md#first-audio-frame
        if (channel_assignment == .STEREO_SIDE_RIGHT && i == 0) ||
           ((channel_assignment == .STEREO_LEFT_SIDE || channel_assignment == .STEREO_MID_SIDE) && i == 1) {
            frame_bps += 1
        }

        subframes[i] = decode_subframe(r, frame_bps, auto_cast actual_block_size) or_return
    }

    align_to_byte(r)

    correlate(subframes, channel_assignment)

    samples_arr := make([dynamic]i32, 0, block_size * 2)
    // Write the samples interleaved.
    for i in 0..<len(subframes[0]) {
        for subframe, sf in subframes {
            sample := subframe[i]
            append(&samples_arr, sample)
        }
    }

    for subframe in subframes {
        delete(subframe)
    }

    frame.samples = samples_arr[:]
    frame.channels = frame_channels
    frame.sample_rate = actual_sample_rate_in_Hz

    //
    // Frame Footer
    //
    crc16_bytes := buffer_to_bytes(&crc_buffer)
    frame_crc := u16(read_data(r, u16be) or_return)
    calculated_frame_crc := calculate_crc16(crc16_bytes)

    if frame_crc != calculated_frame_crc {
        fmt.eprintfln("Expected frame CRC 0x%X, got 0x%X", frame_crc, calculated_frame_crc)
        return {}, .CRC_Mismatch
    }

    return frame, nil
}

md5hash :: proc(md5_ctx: ^md5.Context, bps: u8, samples: []i32) {
    for sample in samples {
        switch bps {
            case 1..=8:
                md5.update(md5_ctx, {u8(sample)})
            case 9..=16:
                first_byte := u8(sample & 0xFF)
                second_byte := u8((sample >> 8) & 0xFF)
                md5.update(md5_ctx, {first_byte, second_byte})
            case 17..=24:
                first_byte := u8(sample & 0xFF)
                second_byte := u8((sample >> 8) & 0xFF)
                third_byte := u8((sample >> 16) & 0xFF)
                md5.update(md5_ctx, {first_byte, second_byte, third_byte})
            case 25..=32:
                data := transmute([4]u8)sample
                md5.update(md5_ctx, data[:])
            case:
                fmt.println("INVALID BPS")
                os.exit(1)
        }
    }
}

md5sum :: proc(md5_ctx: ^md5.Context, flac: ^Flac) -> Error {
    calculated_md5 := [16]byte{}
    md5.final(md5_ctx, calculated_md5[:])

    flac.metadata.calculated_md5 = calculated_md5

    if mem.compare(calculated_md5[:], flac.metadata.expected_md5[:]) != 0 {
        return .MD5_Mismatch
    }

    return nil
}

// `load_from_bytes` takes a byte slice and initializes a bitreader for it.
// The data is expected to be a full flac stream.
load_from_bytes :: proc(data: []byte, options := Options{}, allocator := context.allocator) -> (flac: ^Flac, err: Error) {
    context.allocator = allocator

    byte_r: bytes.Reader
    bytes.reader_init(&byte_r, data)

    r := Reader{bytes.reader_to_stream(&byte_r), 0, 0, 0}

    flac = read_metadata(&r) or_return
    if .only_return_metadata in options {
        return flac, nil
    }

    md5_ctx: md5.Context
    md5.init(&md5_ctx)
    defer md5.reset(&md5_ctx)

    for {
        err = decode_frame(&r, flac, &md5_ctx, options)
        if err != nil {
            if err == .EOF {
                break
            } else {
                return flac, err
            }
        }
    }

    if err != .EOF {
        return flac, err
    }

    if .skip_md5_check not_in options {
        md5sum(&md5_ctx, flac) or_return
    }

    return flac, nil
}

// `load_from_file` reads the entire file to memory and operates on the returned byte slice.
// Only use this with small files.
load_from_file :: proc(filename: string, options := Options{}, allocator := context.allocator) -> (flac: ^Flac, err: Error) {
    context.allocator = allocator

    data, ok := os.read_entire_file(filename)
    defer delete(data)

    if ok {
        return load_from_bytes(data, options)
    } else {
        return nil, .Unable_To_Read_File
    }
}


// `load_from_file_buffered` initializes a buffered reader for the file and reads all the metadata blocks.
// Calls to `read_next_frame()` MUST be made to decode the audio data.
// This is the recommended way to read most FLAC files as it has a minimal memory overhead.
load_from_file_buffered :: proc(filename: string, allocator := context.allocator) -> (flac: ^Flac, r: ^Reader, err: Error) {
    context.allocator = allocator

    file, open_err := os.open(filename)
    if open_err != os.ERROR_NONE {
        fmt.eprintln(open_err)
        return nil, {}, .Unable_To_Read_File
    }

    br := new(bufio.Reader)
    bufio.reader_init(br, os.stream_from_handle(file))

    r = new(Reader)
    r.r = bufio.reader_to_stream(br)
    r.buf = 0
    r.x = 0
    r.n = 0

    flac = read_metadata(r, true) or_return

    return flac, r, nil
}

/* `destroy` cleans up and frees the memory allocated by all 3 loading functions.
 The returned reader from `load_from_file_buffered` MUST be passed to `destroy` in order to close the file handle.
 `load_from_file` and `load_from_bytes` may pass nil as the reader.
 ---
 The allocator that was used when loading the flac file MUST be passed to `destroy` in order to properly free
 the memory, otherwise a bad free may occur and crash the program.
*/
destroy :: proc(flac: ^Flac, r: ^Reader = nil, allocator := context.allocator) {
    context.allocator = allocator

    delete(flac.samples)
    for picture in flac.metadata.pictures {
        delete(picture.mimetype)
        delete(picture.data)
        delete(picture.description)
    }
    delete(flac.metadata.pictures)

    for comment in flac.metadata.vorbis_comments {
        delete(comment)
    }
    delete(flac.metadata.vorbis_comments)
    delete(flac.metadata.vendor_name)

    free(flac)

    if r != nil {
        br := cast(^bufio.Reader)r.data
        closer, ok := io.to_closer(br.rd)
        io.close(closer)
        bufio.reader_destroy(br)
        free(br)
        free(r)
    }
}
