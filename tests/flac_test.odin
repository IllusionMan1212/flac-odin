package flac_test

import "core:fmt"
import "core:os"
import "core:testing"
import "shared:flac"

@(test)
test_blocksize_4096 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/01 - blocksize 4096.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 4096 Failed with error:", err))
}

@(test)
test_blocksize_4608 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/02 - blocksize 4608.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 4608 Failed with error:", err))
}

@(test)
test_blocksize_16 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/03 - blocksize 16.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 16 Failed with error:", err))
}

@(test)
test_blocksize_192 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/04 - blocksize 192.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 192 Failed with error:", err))
}

@(test)
test_blocksize_254 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/05 - blocksize 254.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 254 Failed with error:", err))
}

@(test)
test_blocksize_512 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/06 - blocksize 512.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 512 Failed with error:", err))
}

@(test)
test_blocksize_725 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/07 - blocksize 725.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 725 Failed with error:", err))
}

@(test)
test_blocksize_1000 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/08 - blocksize 1000.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 1000 Failed with error:", err))
}

@(test)
test_blocksize_1937 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/09 - blocksize 1937.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 1937 Failed with error:", err))
}

@(test)
test_blocksize_2304 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/10 - blocksize 2304.flac")

    testing.expect(t, err == nil, fmt.tprint("Blocksize 2304 Failed with error:", err))
}

@(test)
test_partition_order_8 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/11 - partition order 8.flac")

    testing.expect(t, err == nil, fmt.tprint("Partition order 8 Failed with error:", err))
}

@(test)
test_qlp_precision_15_bit :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/12 - qlp precision 15 bit.flac")

    testing.expect(t, err == nil, fmt.tprint("qlp precision 15 bit Failed with error:", err))
}

@(test)
test_qlp_precision_2_bit :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/13 - qlp precision 2 bit.flac")

    testing.expect(t, err == nil, fmt.tprint("qlp precision 2 bit Failed with error:", err))
}

@(test)
wasted_bits :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/14 - wasted bits.flac")

    testing.expect(t, err == nil, fmt.tprint("Wasted bits Failed with error:", err))
}

@(test)
only_verbatim_subframes :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/15 - only verbatim subframes.flac")

    testing.expect(t, err == nil, fmt.tprint("Only verbatim subframes Failed with error:", err))
}

@(test)
partition_order_8_containing_escaped_partitions :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/16 - partition order 8 containing escaped partitions.flac")

    testing.expect(t, err == nil, fmt.tprint("Partition order 8 containing escaped partitions Failed with error:", err))
}

@(test)
all_fixed_orders :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/17 - all fixed orders.flac")

    testing.expect(t, err == nil, fmt.tprint("All fixed orders Failed with error:", err))
}

@(test)
precision_search :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/18 - precision search.flac")

    testing.expect(t, err == nil, fmt.tprint("Precision search Failed with error:", err))
}

@(test)
samplerate_35467Hz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/19 - samplerate 35467Hz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 35467Hz Failed with error:", err))
}

@(test)
samplerate_39kHz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/20 - samplerate 39kHz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 39kHz Failed with error:", err))
}

@(test)
samplerate_22050Hz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/21 - samplerate 22050Hz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 22050Hz Failed with error:", err))
}

@(test)
_12_bit_per_sample :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/22 - 12 bit per sample.flac")

    testing.expect(t, err == nil, fmt.tprint("12 bit per sample Failed with error:", err))
}

@(test)
_8_bit_per_sample :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/23 - 8 bit per sample.flac")

    testing.expect(t, err == nil, fmt.tprint("8 bit per sample Failed with error:", err))
}

@(test)
variable_blocksize_file_created_with_flake_revision_264 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/24 - variable blocksize file created with flake revision 264.flac")

    testing.expect(t, err == nil, fmt.tprint("Variable blocksize file created with flake revision 264 Failed with error:", err))
}

@(test)
variable_blocksize_file_created_with_flake_revision_264_modified_to_create_smaller_blocks :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/25 - variable blocksize file created with flake revision 264, modified to create smaller blocks.flac")

    testing.expect(t, err == nil, fmt.tprint("Variable blocksize file created with flake revision 264 modified to create smaller blocks Failed with error:", err))
}

@(test)
variable_blocksize_file_created_with_CUETools_Flake_2_1_6 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/26 - variable blocksize file created with CUETools.Flake 2.1.6.flac")

    testing.expect(t, err == nil, fmt.tprint("Variable blocksize file created with CUETools.Flake 2.1.6 Failed with error:", err))
}

@(test)
old_format_variable_blocksize_file_created_with_Flake_0_11 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/27 - old format variable blocksize file created with Flake 0.11.flac")

    testing.expect(t, err == nil, fmt.tprint("Old format variable blocksize file created with Flake 0.11 Failed with error:", err))
}

@(test)
high_resolution_audio_default_settings :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/28 - high resolution audio, default settings.flac")

    testing.expect(t, err == nil, fmt.tprint("High resolution audio, default settings Failed with error:", err))
}

@(test)
high_resolution_audio_blocksize_16384 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/29 - high resolution audio, blocksize 16384.flac")

    testing.expect(t, err == nil, fmt.tprint("High resolution audio, blocksize 16384 Failed with error:", err))
}

@(test)
high_resolution_audio_blocksize_13456 :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/30 - high resolution audio, blocksize 13456.flac")

    testing.expect(t, err == nil, fmt.tprint("High resolution audio, blocksize 13456 Failed with error:", err))
}

@(test)
high_resolution_audio_using_only_32nd_order_predictors :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/31 - high resolution audio, using only 32nd order predictors.flac")

    testing.expect(t, err == nil, fmt.tprint("High resolution audio, using only 32nd order predictors Failed with error:", err))
}

@(test)
high_resolution_audio_partition_order_8_containing_escaped_partitions :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/32 - high resolution audio, partition order 8 containing escaped partitions.flac")

    testing.expect(t, err == nil, fmt.tprint("High resolution audio, partition order 8 containing escaped partitions Failed with error:", err))
}

@(test)
samplerate_192kHz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/33 - samplerate 192kHz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 192kHz Failed with error:", err))
}

@(test)
samplerate_192kHz_using_only_32nd_order_predictors :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/34 - samplerate 192kHz, using only 32nd order predictors.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 192kHz, using only 32nd order predictors Failed with error:", err))
}

@(test)
samplerate_134560Hz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/35 - samplerate 134560Hz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 134560Hz Failed with error:", err))
}

@(test)
samplerate_384kHz :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/36 - samplerate 384kHz.flac")

    testing.expect(t, err == nil, fmt.tprint("Samplerate 384kHz Failed with error:", err))
}

@(test)
_20_bit_per_sample :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/37 - 20 bit per sample.flac")

    testing.expect(t, err == nil, fmt.tprint("20 bit per sample Failed with error:", err))
}

@(test)
_3_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/38 - 3 channels (3.0).flac")

    testing.expect(t, err == nil, fmt.tprint("3 channels Failed with error:", err))
}

@(test)
_4_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/39 - 4 channels (4.0).flac")

    testing.expect(t, err == nil, fmt.tprint("4 channels Failed with error:", err))
}

@(test)
_5_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/40 - 5 channels (5.0).flac")

    testing.expect(t, err == nil, fmt.tprint("5 channels Failed with error:", err))
}

@(test)
_6_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/41 - 6 channels (5.1).flac")

    testing.expect(t, err == nil, fmt.tprint("6 channels Failed with error:", err))
}

@(test)
_7_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/42 - 7 channels (6.1).flac")

    testing.expect(t, err == nil, fmt.tprint("7 channels Failed with error:", err))
}

@(test)
_8_channels :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/43 - 8 channels (7.1).flac")

    testing.expect(t, err == nil, fmt.tprint("8 channels Failed with error:", err))
}

@(test)
_8_channel_surround_192kHz_24_bit_using_only_32nd_order_predictors :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/44 - 8-channel surround, 192kHz, 24 bit, using only 32nd order predictors.flac")

    testing.expect(t, err == nil, fmt.tprint("8-channel surround 192kHz 24 bit using only 32nd order predictors Failed with error:", err))
}

@(test)
no_total_number_of_samples :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/45 - no total number of samples set.flac")

    testing.expect(t, err == nil, fmt.tprint("No total number of samples Failed with error:", err))
}

@(test)
no_min_max_framesize :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/46 - no min-max framesize set.flac")

    testing.expect(t, err == nil, fmt.tprint("No min-max framesize Failed with error:", err))
}

@(test)
only_streaminfo :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/47 - only STREAMINFO.flac")

    testing.expect(t, err == nil, fmt.tprint("Only STREAMINFO Failed with error:", err))
}

@(test)
extreme_large_seektable :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/48 - Extremely large SEEKTABLE.flac")

    testing.expect(t, err == nil, fmt.tprint("Extremely large SEEKTABLE Failed with error:", err))
}

@(test)
extreme_large_padding :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/49 - Extremely large PADDING.flac")

    testing.expect(t, err == nil, fmt.tprint("Extremely large PADDING Failed with error:", err))
}

@(test)
extreme_large_picture :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/50 - Extremely large PICTURE.flac")

    testing.expect(t, err == nil, fmt.tprint("Extremely large PICTURE Failed with error:", err))
}

@(test)
extreme_large_vorbiscomment :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/51 - Extremely large VORBISCOMMENT.flac")

    testing.expect(t, err == nil, fmt.tprint("Extremely large VORBISCOMMENT Failed with error:", err))
}

@(test)
extreme_large_application :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/52 - Extremely large APPLICATION.flac")

    testing.expect(t, err == nil, fmt.tprint("Extremely large APPLICATION Failed with error:", err))
}

@(test)
cuesheet_with_very_many_indexes :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/53 - CUESHEET with very many indexes.flac")

    testing.expect(t, err == nil, fmt.tprint("CUESHEET with very many indexes Failed with error:", err))
}

@(test)
_1000x_repeating_vorbiscomment :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/54 - 1000x repeating VORBISCOMMENT.flac")

    testing.expect(t, err == nil, fmt.tprint("1000x repeating VORBSICOMMENT Failed with error:", err))
}

@(test)
file_48_53_combined :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/55 - file 48-53 combined.flac")

    testing.expect(t, err == nil, fmt.tprint("File 48-53 combined Failed with error:", err))
}

@(test)
jpg_picture :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/56 - JPG PICTURE.flac")

    testing.expect(t, err == nil, fmt.tprint("JPG PICTURE Failed with error:", err))
}

@(test)
png_picture :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/57 - PNG PICTURE.flac")

    testing.expect(t, err == nil, fmt.tprint("PNG PICTURE Failed with error:", err))
}

@(test)
gif_picture :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/58 - GIF PICTURE.flac")

    testing.expect(t, err == nil, fmt.tprint("GIF PICTURE Failed with error:", err))
}

@(test)
avif_picture :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/59 - AVIF PICTURE.flac")

    testing.expect(t, err == nil, fmt.tprint("AVIF PICTURE Failed with error:", err))
}

@(test)
mono_audio :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/60 - mono audio.flac")

    testing.expect(t, err == nil, fmt.tprint("Mono audio Failed with error:", err))
}

@(test)
predictor_overflow_check_16_bit :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/61 - predictor overflow check, 16-bit.flac")

    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 16-bit Failed with error:", err))
}

@(test)
predictor_overflow_check_20_bit :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/62 - predictor overflow check, 20-bit.flac")

    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 20-bit Failed with error:", err))
}

@(test)
predictor_overflow_check_24_bit :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/63 - predictor overflow check, 24-bit.flac")

    testing.expect(t, err == nil, fmt.tprint("Predictor overflow check, 24-bit Failed with error:", err))
}

@(test)
rice_partitions_with_escape_code_zero :: proc(t: ^testing.T) {
    os.stdout = -1
    err := flac.load_from_file("flac-test-files/subset/64 - rice partitions with escape code zero.flac")

    testing.expect(t, err == nil, fmt.tprint("Rice partitions with escape code zero Failed with error:", err))
}

@(test)
uncommon_32_bit_per_sample :: proc(t: ^testing.T) {
	os.stdout = -1
	err := flac.load_from_file("flac-test-files/uncommon/05 - 32bps audio.flac")

	testing.expect(t, err == nil, fmt.tprint("Uncommon 32bps audio Failed with error:", err))
}

@(test)
uncommon_samplerate_768kHz :: proc(t: ^testing.T) {
	os.stdout = -1
	err := flac.load_from_file("flac-test-files/uncommon/06 - samplerate 768kHz.flac")

	testing.expect(t, err == nil, fmt.tprint("Uncommon samplerate 768kHz Failed with error:", err))
}

// TODO: 
