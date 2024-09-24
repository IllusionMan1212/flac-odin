package flac_test

import "core:fmt"
import "core:os"
import "core:testing"
import "shared:flac"

@(test)
test_blocksize_4096_buffered :: proc(t: ^testing.T) {
	data, r, err := flac.load_from_file_buffered("flac-test-files/subset/01 - blocksize 4096.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Read Blocksize 4096 metadata Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 4096 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_4608_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/02 - blocksize 4608.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 4608 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 4608 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_16_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/03 - blocksize 16.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 16 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 16 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_192_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/04 - blocksize 192.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 192 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 192 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_254_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/05 - blocksize 254.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 254 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 254 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_512_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/06 - blocksize 512.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 512 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 512 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_725_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/07 - blocksize 725.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 725 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 725 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_1000_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/08 - blocksize 1000.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 1000 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 1000 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_1937_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/09 - blocksize 1937.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 1937 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 1937 frame Failed with error:", f_err))
	}
}

@(test)
test_blocksize_2304_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/10 - blocksize 2304.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Blocksize 2304 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Blocksize 2304 frame Failed with error:", f_err))
	}
}

@(test)
test_partition_order_8_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/11 - partition order 8.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Partition order 8 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Partition order 8 frame Failed with error:", f_err))
	}
}

@(test)
test_qlp_precision_15_bit_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/12 - qlp precision 15 bit.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("qlp precision 15 bit Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding qlp precision 15 bit frame Failed with error:", f_err))
	}
}

@(test)
test_qlp_precision_2_bit_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/13 - qlp precision 2 bit.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("qlp precision 2 bit Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding qlp precision 2 bit frame Failed with error:", f_err))
	}
}

@(test)
wasted_bits_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/14 - wasted bits.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Wasted bits Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Wasted bits frame Failed with error:", f_err))
	}
}

@(test)
only_verbatim_subframes_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/15 - only verbatim subframes.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Only verbatim subframes Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Only verbatim subframes frame Failed with error:", f_err))
	}
}

@(test)
partition_order_8_containing_escaped_partitions_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/16 - partition order 8 containing escaped partitions.flac")
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("Partition order 8 containing escaped partitions Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Partition order 8 containing escaped partitions frame Failed with error:", f_err))
	}
}

@(test)
all_fixed_orders_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/17 - all fixed orders.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("All fixed orders Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding All fixed orders frame Failed with error:", f_err))
	}
}

@(test)
precision_search_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/18 - precision search.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Precision search Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Precision search frame Failed with error:", f_err))
	}
}

@(test)
samplerate_35467Hz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/19 - samplerate 35467Hz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 35467Hz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 35467Hz frame Failed with error:", f_err))
	}
}

@(test)
samplerate_39kHz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/20 - samplerate 39kHz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 39kHz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 39kHz frame Failed with error:", f_err))
	}
}

@(test)
samplerate_22050Hz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/21 - samplerate 22050Hz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 22050Hz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 22050Hz frame Failed with error:", f_err))
	}
}

@(test)
_12_bit_per_sample_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/22 - 12 bit per sample.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("12 bit per sample Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 12 bit per sample frame Failed with error:", f_err))
	}
}

@(test)
_8_bit_per_sample_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/23 - 8 bit per sample.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("8 bit per sample Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 8 bit per sample frame Failed with error:", f_err))
	}
}

@(test)
variable_blocksize_file_created_with_flake_revision_264_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/24 - variable blocksize file created with flake revision 264.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("Variable blocksize file created with flake revision 264 Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Variable blocksize file created with flake revision 264 frame Failed with error:", f_err))
	}
}

@(test)
variable_blocksize_file_created_with_flake_revision_264_modified_to_create_smaller_blocks_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/25 - variable blocksize file created with flake revision 264, modified to create smaller blocks.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint(
            "Variable blocksize file created with flake revision 264 modified to create smaller blocks Failed with error:",
            err,
        ),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Variable blocksize file created with flake revision 264 modified to create smaller blocks frame Failed with error:", f_err))
	}
}

@(test)
variable_blocksize_file_created_with_CUETools_Flake_2_1_6_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/26 - variable blocksize file created with CUETools.Flake 2.1.6.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("Variable blocksize file created with CUETools.Flake 2.1.6 Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Variable blocksize file created with CUETools Flake 2.1.6 frame Failed with error:", f_err))
	}
}

@(test)
old_format_variable_blocksize_file_created_with_Flake_0_11_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/27 - old format variable blocksize file created with Flake 0.11.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("Old format variable blocksize file created with Flake 0.11 Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Old format variable blocksize file created with CUETools Flake 0.11 frame Failed with error:", f_err))
	}
}

@(test)
high_resolution_audio_default_settings_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered ("flac-test-files/subset/28 - high resolution audio, default settings.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("High resolution audio, default settings Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding High resolution audio, default settings frame Failed with error:", f_err))
	}
}

@(test)
high_resolution_audio_blocksize_16384_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/29 - high resolution audio, blocksize 16384.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("High resolution audio, blocksize 16384 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding High resolution audio, blocksize 16384 frame Failed with error:", f_err))
	}
}

@(test)
high_resolution_audio_blocksize_13456_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/30 - high resolution audio, blocksize 13456.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("High resolution audio, blocksize 13456 Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding High resolution audio, blocksize 13456 frame Failed with error:", f_err))
	}
}

@(test)
high_resolution_audio_using_only_32nd_order_predictors_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/31 - high resolution audio, using only 32nd order predictors.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("High resolution audio, using only 32nd order predictors Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding High resolution audio, using only 32nd predictors frame Failed with error:", f_err))
	}
}

@(test)
high_resolution_audio_partition_order_8_containing_escaped_partitions_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/32 - high resolution audio, partition order 8 containing escaped partitions.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("High resolution audio, partition order 8 containing escaped partitions Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding High resolution audio, partition order 8 containing escaped partitions frame Failed with error:", f_err))
	}
}

@(test)
samplerate_192kHz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/33 - samplerate 192kHz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 192kHz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 192kHz frame Failed with error:", f_err))
	}
}

@(test)
samplerate_192kHz_using_only_32nd_order_predictors_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/34 - samplerate 192kHz, using only 32nd order predictors.flac")
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("Samplerate 192kHz, using only 32nd order predictors Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 192kHz, using only 32nd predictors frame Failed with error:", f_err))
	}
}

@(test)
samplerate_134560Hz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/35 - samplerate 134560Hz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 134560Hz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 134560Hz frame Failed with error:", f_err))
	}
}

@(test)
samplerate_384kHz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/36 - samplerate 384kHz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Samplerate 384kHz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Samplerate 384kHz frame Failed with error:", f_err))
	}
}

@(test)
_20_bit_per_sample_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/37 - 20 bit per sample.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("20 bit per sample Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 20 bit per sample frame Failed with error:", f_err))
	}
}

@(test)
_3_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/38 - 3 channels (3.0).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("3 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 3 channels frame Failed with error:", f_err))
	}
}

@(test)
_4_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/39 - 4 channels (4.0).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("4 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 4 channels frame Failed with error:", f_err))
	}
}

@(test)
_5_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/40 - 5 channels (5.0).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("5 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 5 channels frame Failed with error:", f_err))
	}
}

@(test)
_6_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/41 - 6 channels (5.1).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("6 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 6 channels frame Failed with error:", f_err))
	}
}

@(test)
_7_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/42 - 7 channels (6.1).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("7 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 7 channels frame Failed with error:", f_err))
	}
}

@(test)
_8_channels_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/43 - 8 channels (7.1).flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("8 channels Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 8 channels frame Failed with error:", f_err))
	}
}

@(test)
_8_channel_surround_192kHz_24_bit_using_only_32nd_order_predictors_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered(
        "flac-test-files/subset/44 - 8-channel surround, 192kHz, 24 bit, using only 32nd order predictors.flac",
    )
	defer flac.destroy(data, r)
    testing.expect(
        t,
        err == nil,
        fmt.tprint("8-channel surround 192kHz 24 bit using only 32nd order predictors Failed with error:", err),
    )

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 8 channel surround, 192kHz, 24 bit, using only 32nd order predictors frame Failed with error:", f_err))
	}
}

@(test)
no_total_number_of_samples_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/45 - no total number of samples set.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("No total number of samples Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding No total number of samples frame Failed with error:", f_err))
	}
}

@(test)
no_min_max_framesize_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/46 - no min-max framesize set.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("No min-max framesize Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding No min max framesize frame Failed with error:", f_err))
	}
}

@(test)
only_streaminfo_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/47 - only STREAMINFO.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Only STREAMINFO Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Only streaminfo frame Failed with error:", f_err))
	}
}

@(test)
extreme_large_seektable_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/48 - Extremely large SEEKTABLE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Extremely large SEEKTABLE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Extremely large seektable frame Failed with error:", f_err))
	}
}

@(test)
extreme_large_padding_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/49 - Extremely large PADDING.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Extremely large PADDING Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Extremely large padding frame Failed with error:", f_err))
	}
}

@(test)
extreme_large_picture_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/50 - Extremely large PICTURE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Extremely large PICTURE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Extremely large picture frame Failed with error:", f_err))
	}
}

@(test)
extreme_large_vorbiscomment_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/51 - Extremely large VORBISCOMMENT.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Extremely large VORBISCOMMENT Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Extremely large vorbis comment frame Failed with error:", f_err))
	}
}

@(test)
extreme_large_application_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/52 - Extremely large APPLICATION.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Extremely large APPLICATION Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Extremely large application frame Failed with error:", f_err))
	}
}

@(test)
cuesheet_with_very_many_indexes_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/53 - CUESHEET with very many indexes.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("CUESHEET with very many indexes Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Cuesheet with very many indexes frame Failed with error:", f_err))
	}
}

@(test)
_1000x_repeating_vorbiscomment_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/54 - 1000x repeating VORBISCOMMENT.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("1000x repeating VORBSICOMMENT Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding 1000x repeating vorbis comment frame Failed with error:", f_err))
	}
}

@(test)
file_48_53_combined_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/55 - file 48-53 combined.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("File 48-53 combined Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding file 48-53 combined frame Failed with error:", f_err))
	}
}

@(test)
jpg_picture_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/56 - JPG PICTURE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("JPG PICTURE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding JPG picture frame Failed with error:", f_err))
	}
}

@(test)
png_picture_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/57 - PNG PICTURE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("PNG PICTURE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding PNG picture frame Failed with error:", f_err))
	}
}

@(test)
gif_picture_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/58 - GIF PICTURE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("GIF PICTURE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding GIF picture frame Failed with error:", f_err))
	}
}

@(test)
avif_picture_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/59 - AVIF PICTURE.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("AVIF PICTURE Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding AVIF picture frame Failed with error:", f_err))
	}
}

@(test)
mono_audio_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/60 - mono audio.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Mono audio Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Mono audio frame Failed with error:", f_err))
	}
}

@(test)
predictor_overflow_check_16_bit_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/61 - predictor overflow check, 16-bit.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 16-bit Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Predictor overflow check 16 bit frame Failed with error:", f_err))
	}
}

@(test)
predictor_overflow_check_20_bit_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/62 - predictor overflow check, 20-bit.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 20-bit Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Predictor overflow check 20 bit frame Failed with error:", f_err))
	}
}

@(test)
predictor_overflow_check_24_bit_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/63 - predictor overflow check, 24-bit.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 24-bit Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Predictor overflow check 24 bit frame Failed with error:", f_err))
	}
}

@(test)
rice_partitions_with_escape_code_zero_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/subset/64 - rice partitions with escape code zero.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Rice partitions with escape code zero Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Rice partitions with escape code zero frame Failed with error:", f_err))
	}
}

@(test)
uncommon_32_bit_per_sample_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/uncommon/05 - 32bps audio.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Uncommon 32bps audio Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Uncommon 32 bit per sample frame Failed with error:", f_err))
	}
}

@(test)
uncommon_samplerate_768kHz_buffered :: proc(t: ^testing.T) {
    data, r, err := flac.load_from_file_buffered("flac-test-files/uncommon/06 - samplerate 768kHz.flac")
	defer flac.destroy(data, r)
    testing.expect(t, err == nil, fmt.tprint("Uncommon samplerate 768kHz Failed with error:", err))

	for {
		frame, f_err := flac.read_next_frame(r, data)
		if f_err == .EOF {
			break
		}
		testing.expect(t, f_err == nil, fmt.tprint("Decoding Uncommon samplerate 768kHz frame Failed with error:", f_err))
	}
}

// TODO: 
