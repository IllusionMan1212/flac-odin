package flac_example

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:crypto/legacy/md5"
import "core:os"
import "core:time"

import "shared:flac"
import "shared:alsa"

DEVICE :: "default"

main :: proc() {
    if len(os.args) < 2 {
        fmt.eprintln("Please provide a path to a flac file.")
        os.exit(1)
    }

    arena: virtual.Arena
    handle: ^alsa.pcm_t

    alsa_err := alsa.pcm_open(&handle, DEVICE, .PLAYBACK, .BLOCK)
    if alsa_err < 0 {
        fmt.eprintln("Failed to initialize audio device: ", alsa.strerror(alsa_err))
        os.exit(1)
    }

    arena_err := virtual.arena_init_growing(&arena, mem.Megabyte * 8)
    if arena_err != nil {
        fmt.eprintln("Failed to alloc memory")
        return
    }
    allocator := virtual.arena_allocator(&arena)

    start := time.now()
    flac_data, reader, err := flac.load_from_file_buffered(os.args[1], allocator)
    if err != nil {
        fmt.println("Error while reading flac file:", err)
        os.exit(1)
    }
    defer flac.destroy(flac_data, reader, allocator)

    fmt.println(flac_data)

	alsa_err = alsa.pcm_set_params(handle, .S16_LE, .RW_INTERLEAVED, u32(flac_data.metadata.channels), flac_data.metadata.sample_rate, 1, 500000)
	if alsa_err < 0 {
		fmt.eprintln("Playback open error:", alsa.strerror(alsa_err))
		os.exit(1)
	}

	sample_rate := flac_data.metadata.sample_rate
	channels := flac_data.metadata.channels

    //md5_ctx: md5.Context
    //md5.init(&md5_ctx)
    for {
        frame, err := flac.read_next_frame(reader, flac_data)

        defer delete(frame.samples)
        if err != nil {
            if err == .EOF {
                break
            } else {
                fmt.println("Error while decoding frame:", err)
                os.exit(1)
            }
        }

		//if frame.sample_rate != sample_rate || frame.channels != channels {
		//	sample_rate = frame.sample_rate
		//	channels = frame.channels
		//	alsa_err = alsa.pcm_set_params(handle, .S16_LE, .RW_INTERLEAVED, u32(channels), sample_rate, 1, 0)
		//	if alsa_err < 0 {
		//		fmt.eprintln("Playback open error:", alsa.strerror(alsa_err))
		//		os.exit(1)
		//	}
		//}

        //converted_samples := make([]u8, len(samples))
        //defer delete(converted_samples)
        //for sample, i in samples {
        //    converted_samples[i] = u8(sample & 0xFF)
        //}

        converted_samples := make([]i16, len(frame.samples))
        defer delete(converted_samples)
        for sample, i in frame.samples {
            new_sample := sample & 0xFF
            new_sample |= ((sample >> 8) & 0xFF) << 8
            converted_samples[i] = i16(new_sample)
        }

        frames := alsa.pcm_writei(handle, raw_data(converted_samples), u64(len(frame.samples)) / u64(frame.channels))
        if frames < 0 {
            fmt.eprintln("Error writing to PCM device:", alsa.strerror(auto_cast frames))
            break
        }
        fmt.printfln("Played %d frames", frames)

        //flac.md5hash(&md5_ctx, flac_data.metadata.bits_per_sample, samples)
    }
    end := time.now()

    //err = flac.md5sum(&md5_ctx, flac_data)
    //if err == .MD5_Mismatch {
    //    fmt.println("Decoded audio data is not correct.")
    //    os.exit(1)
    //}

    alsa_err = alsa.pcm_drain(handle)
    if alsa_err < 0 {
        fmt.eprintln("pcm_drain failed with:", alsa.strerror(alsa_err))
    }
    alsa.pcm_close(handle)

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)
}

old_main :: proc() {
    if len(os.args) < 2 {
        fmt.eprintln("Please provide a path to a flac file.")
        os.exit(1)
    }

    handle: ^alsa.pcm_t

    arena: virtual.Arena
    arena_err := virtual.arena_init_growing(&arena, mem.Megabyte * 8)
    if arena_err != nil {
        fmt.eprintln("Failed to alloc memory")
        return
    }
    allocator := virtual.arena_allocator(&arena)

    alsa_err := alsa.pcm_open(&handle, DEVICE, .PLAYBACK, .BLOCK)
    if alsa_err < 0 {
        fmt.eprintln("Failed to initialize audio device: ", alsa.strerror(alsa_err))
        os.exit(1)
    }

    start := time.now()
    flac_data, err := flac.load_from_file(os.args[1], allocator = allocator)
    if err != nil {
        fmt.eprintln(err)
        if err == .MD5_Mismatch {
            fmt.printfln("Expected: %v, got: %v", flac_data.metadata.expected_md5, flac_data.metadata.calculated_md5)
        }
        os.exit(1)
    }
    defer flac.destroy(flac_data, allocator = allocator)
    end := time.now()

    fmt.println(flac_data.metadata)

    alsa_err = alsa.pcm_set_params(handle, .S16_LE, .RW_INTERLEAVED, u32(flac_data.metadata.channels), flac_data.metadata.sample_rate, 1, 500000)
    if alsa_err < 0 {
        fmt.eprintln("Playback open error:", alsa.strerror(alsa_err))
        os.exit(1)
    }

    converted_samples := make([]i16, len(flac_data.samples))

    for sample, i in flac_data.samples {
        new_sample := sample & 0xFF
        new_sample |= ((sample >> 8) & 0xFF) << 8
        converted_samples[i] = i16(new_sample)
    }

    for {
        frames := alsa.pcm_writei(handle, raw_data(converted_samples), u64(len(flac_data.samples)) / u64(flac_data.metadata.channels))
        if frames < 0 {
            fmt.eprintln("Error writing to PCM device:", alsa.strerror(auto_cast frames))
            break
        }
        fmt.printfln("Played %d frames", frames)
    }

    alsa_err = alsa.pcm_drain(handle)
    if alsa_err < 0 {
        fmt.eprintln("pcm_drain failed with:", alsa.strerror(alsa_err))
    }
    alsa.pcm_close(handle)

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)
}
