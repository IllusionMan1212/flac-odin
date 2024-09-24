#+private
package flac

import "core:io"

/* Basic byte and bit reader.
 Uses core:bytes reader under the hood with a few useful procedures for reading structs and other types.
*/
Reader :: struct {
    using r: io.Stream,
    // Temporary read buffer.
    buf: [8]u8,
    // Between 0 and 7 buffered bits since previous read operations.
    x: u8,
    // The number of buffered bits in x.
    n: uint,
}

read_slice :: #force_inline proc(r: ^Reader, buf: []u8) -> io.Error {
    io.read_full(r^, buf) or_return

    return nil
}

read_data :: #force_inline proc(r: ^Reader, $T: typeid) -> (res: T, err: io.Error) {
	// b is safe to return here because the proc is always inlined.
    b: [size_of(T)]byte
    read_slice(r, b[:]) or_return

    return (^T)(&b[0])^, nil
}

// Read reads and returns the next n bits, at most 64. It buffers bits up to the
// next byte boundary.
// Borrowed from https://github.com/mewkiz/flac
read_bits :: proc(r: ^Reader, n: uint) -> (res: u64, err: io.Error) #no_bounds_check {
    if n == 0 {
        return 0, nil
    }

    n := n

    // Read buffered bits.
    if r.n > 0 {
        switch {
        case r.n == n:
            r.n = 0
            return u64(r.x), nil
        case r.n > n:
            r.n -= n
            mask := ~u8(0) << r.n
            res = u64(r.x&mask) >> r.n
            r.x &~= mask
            return res, nil
        }
        n -= r.n
        res = u64(r.x)
        r.n = 0
    }

    // Fill the temporary buffer.
    bytes := n / 8
    bits := n % 8
    if bits > 0 {
        bytes += 1
    }
    io.read_full(r, r.buf[:bytes]) or_return

    // Read bits from the temporary buffer.
    for b in r.buf[:bytes-1] {
        res <<= 8
        res |= u64(b)
    }
    b := r.buf[bytes-1]
    if bits > 0 {
        res <<= bits
        r.n = 8 - bits
        mask := ~u8(0) << r.n
        res |= u64(b&mask) >> r.n
        r.x = b & ~mask
    } else {
        res <<= 8
        res |= u64(b)
    }

    return res, nil
}

align_to_byte :: proc(r: ^Reader) {
    r.x = 0
    r.n = 0
}
