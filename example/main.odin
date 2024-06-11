package flac_example

import "core:fmt"
import "core:os"
import "core:time"

import "../"

main :: proc() {
    start := time.now()
		if len(os.args) < 2 {
        fmt.eprintln("Please provide a path to a flac file.")
        os.exit(1)
    }

    err := flac.load_from_file(os.args[1])
    if err != nil {
        fmt.eprintln(err)
        os.exit(1)
    }

    end := time.now()

    elapsed := time.diff(start, end)
    fmt.println("Decoding took", elapsed)
}
