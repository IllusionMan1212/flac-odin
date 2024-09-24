package main

import "core:os"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:time"

import "shared:alsa"
import "shared:flac"

DEVICE :: "default"

main :: proc() {
    if len(os.args) < 2 {
        fmt.eprintln("Please provide a path to a flac file.")
        os.exit(1)
    }
	defer delete(os.args)

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
	defer alsa.pcm_close(handle)

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
	defer delete(converted_samples)

    for sample, i in flac_data.samples {
        new_sample := sample & 0xFF
        new_sample |= ((sample >> 8) & 0xFF) << 8
        converted_samples[i] = i16(new_sample)
    }

    frames := alsa.pcm_writei(handle, raw_data(converted_samples), u64(len(flac_data.samples)) / u64(flac_data.metadata.channels))
    if frames < 0 {
        fmt.eprintln("Error writing to PCM device:", alsa.strerror(auto_cast frames))
		return
    }
    fmt.printfln("Played %d frames", frames)

    alsa_err = alsa.pcm_drain(handle)
    if alsa_err < 0 {
        fmt.eprintln("pcm_drain failed with:", alsa.strerror(alsa_err))
    }

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)
}
