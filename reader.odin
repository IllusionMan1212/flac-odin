//+private
package flac

import "core:bytes"
import "core:io"

/* Basic byte and bit reader.
 Uses core:bytes reader under the hood with a few useful procedures for reading structs and other types.
*/
Reader :: struct {
    using _:   bytes.Reader,
    bits_read: u8,
}

read_slice :: #force_inline proc(r: ^Reader, size: int) -> (res: []u8, err: io.Error) {
    #no_bounds_check {
        if r.i + i64(size) <= i64(len(r.s)) {
            res = r.s[r.i:r.i + i64(size)]
            r.i += i64(size)
            return res, .None
        }
    }

    if i64(len(r.s)) == r.i {
        return []u8{}, .EOF
    } else {
        return []u8{}, .Short_Buffer
    }
}

read_data :: #force_inline proc(r: ^Reader, $T: typeid) -> (res: T, err: io.Error) {
    b := read_slice(r, size_of(T)) or_return
    return (^T)(&b[0])^, nil
}

read_bit :: proc(r: ^Reader) -> (bit: byte, err: Error) #no_bounds_check {
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }

    bits := 8 - (r.bits_read + 1)
    b := (r.s[r.i] >> bits) & 1
    r.bits_read += 1

    if r.bits_read == 8 {
        r.i += 1
        r.bits_read = 0
    }

    return b, nil
}

read_bits :: proc(r: ^Reader, n: uint) -> (bits: u64, err: Error) #no_bounds_check {
    res: u64

    // Fast path: if we can read all bits within the current byte.
    if r.bits_read + u8(n) <= 8 {
        res = (u64(r.s[r.i]) >> (8 - r.bits_read - u8(n))) & ((1 << n) - 1)
        r.bits_read += u8(n)
        if r.bits_read == 8 {
            r.bits_read = 0
            r.i += 1
        }
        return res, nil
    }

    // General case: reading across multiple bytes.
    rem_bits := n
    if r.bits_read > 0 {
        // Read the remaining bits in the current byte.
        bits_in_byte := 8 - r.bits_read
        res = u64(r.s[r.i]) & ((1 << bits_in_byte) - 1)
        rem_bits -= uint(bits_in_byte)
        r.bits_read = 0
        r.i += 1
    }

    // Read full bytes.
    for rem_bits >= 8 {
        res = (res << 8) | u64(r.s[r.i])
        rem_bits -= 8
        r.i += 1
    }

    // Read remaining bits in the final byte.
    if rem_bits > 0 {
        res = (res << rem_bits) | (u64(r.s[r.i]) >> (8 - rem_bits))
        r.bits_read += u8(rem_bits)
    }

    return res, nil
}

read_byte :: proc(r: ^Reader) -> (b: byte, err: Error) #no_bounds_check {
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    // Continue reading from the current byte if it has unread bits.
    if r.bits_read != 0 {
        cur_byte := r.s[r.i]
        next_byte := r.s[r.i + 1]
        rem_bits := 8 - r.bits_read
        rem_bits_mask: u8 = (1 << rem_bits) - 1
        b = ((cur_byte & rem_bits_mask) << r.bits_read) | (next_byte >> rem_bits)
        r.i += 1
    } else {
        b = r.s[r.i]
        r.i += 1
    }
    return b, nil
}

align_to_byte :: proc(r: ^Reader) -> Error {
    if r.bits_read == 0 {
        return nil
    }
    if r.i >= i64(len(r.s)) {
        return .EOF
    }

    // Align by skipping the remaining bits in the byte
    r.bits_read = 0
    r.i += 1

    return nil
}
