package flac_linux_example

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
    defer delete(os.args)

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
    //allocator := virtual.arena_allocator(&arena)

    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    defer mem.tracking_allocator_destroy(&track)
    context.allocator = mem.tracking_allocator(&track)

    start := time.now()
    flac_data, reader, err := flac.load_from_file(os.args[1], context.allocator)
    if err != nil {
        fmt.println("Error while reading flac file:", err)
        os.exit(1)
    }

    fmt.println(flac_data)

    alsa_err = alsa.pcm_set_params(handle, .S16_LE, .RW_INTERLEAVED, u32(flac_data.metadata.channels), flac_data.metadata.sample_rate, 1, 500000)
    if alsa_err < 0 {
        fmt.eprintln("Playback open error:", alsa.strerror(alsa_err))
        os.exit(1)
    }

	// TODO: channel mapping is incorrect for anything with more than 2 channels.
    channels := flac_data.metadata.channels

    md5_ctx: md5.Context
    md5.init(&md5_ctx)
    for {
        frame, err := flac.decode_next_frame(reader, flac_data, context.allocator)
        if err != nil {
            if err == .EOF {
                break
            } else {
                fmt.println("Error while decoding frame:", err)
                os.exit(1)
            }
        }

        if frame.channels != channels {
			// Finish playing the previous frame before changing the hw params.
			alsa.pcm_drain(handle)

			channels = frame.channels
			alsa_err = alsa.pcm_set_params(handle, .S16_LE, .RW_INTERLEAVED, u32(channels), flac_data.metadata.sample_rate, 1, 500000)
			if alsa_err < 0 {
				fmt.eprintln("Playback open error:", alsa.strerror(alsa_err))
				os.exit(1)
			}
        }

		// TODO: resampling

		// 8 bps audio
        //converted_samples := make([]u8, len(frame.samples))
        //defer delete(converted_samples)
        //for sample, i in frame.samples {
        //    converted_samples[i] = u8(sample & 0xFF)
        //}

		// 16 bps audio
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

        flac.md5hash(&md5_ctx, flac_data.metadata.bits_per_sample, frame.samples)
    }

    alsa_err = alsa.pcm_drain(handle)
    if alsa_err < 0 {
        fmt.eprintln("pcm_drain failed with:", alsa.strerror(alsa_err))
    }
    alsa.pcm_close(handle)

    end := time.now()

    err = flac.md5sum(&md5_ctx, flac_data)
    if err == .MD5_Mismatch {
        fmt.printfln("Decoded audio data is not correct. Expected MD5: %v, Got: %v", flac_data.metadata.expected_md5, flac_data.metadata.calculated_md5)
        os.exit(1)
    }

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)

    flac.destroy(flac_data, reader, context.allocator)

    for _, leak in track.allocation_map {
        fmt.printfln("%v leaked %m", leak.location, leak.size)
    }
    
    for bad_free in track.bad_free_array {
        fmt.printfln("%v allocation %p was freed badly", bad_free.location, bad_free.memory)
    }
    
    fmt.printfln("Peak Mem: %m", track.peak_memory_allocated)
    fmt.printfln("Total Mem: %m", track.total_memory_allocated)
    fmt.printfln("Current Mem: %m", track.current_memory_allocated)
    fmt.printfln("Total Allocs: %v, Total Frees: %v:", track.total_allocation_count, track.total_free_count)
    fmt.printfln("Total Mem Free'd: %m", track.total_memory_freed)
}
