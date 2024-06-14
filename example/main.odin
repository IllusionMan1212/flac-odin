package flac_example

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:time"

import "../"

main :: proc() {
    if len(os.args) < 2 {
        fmt.eprintln("Please provide a path to a flac file.")
        os.exit(1)
    }

    arena: virtual.Arena
    arena_err := virtual.arena_init_static(&arena, mem.Megabyte * 8)
    if arena_err != nil {
        fmt.eprintln("Failed to alloc memory")
        return
    }
    allocator := virtual.arena_allocator(&arena)

    start := time.now()
    err := flac.load_from_file(os.args[1], allocator = allocator)
    if err != nil {
        fmt.eprintln(err)
        os.exit(1)
    }

    end := time.now()

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)
}
