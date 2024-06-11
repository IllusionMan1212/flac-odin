//+private
package flac

import "core:bytes"
import "core:io"
import "core:math"

/* Basic byte reader with support for reading bits.
 Uses core:bytes reader under the hood with a few useful procedures for reading structs and other types.
*/
Reader :: struct {
    using _: bytes.Reader,
    bits_read_in_byte: u8,
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

// TODO: make sure this takes into account the bits in bits_read_in_byte
// Although this is probably not needed since the only times we're not alinged to a byte is when finishing a subframe
// All frames are supposed to end byte-aligned.
read_data :: #force_inline proc(r: ^Reader, $T: typeid) -> (res: T, err: io.Error) {
    b := read_slice(r, size_of(T)) or_return
    return (^T)(&b[0])^, nil
}

read_bit :: #force_inline proc(r: ^Reader) -> (bit: byte, err: Error) {
    if r.i >= i64(len(r.s)) {
        return 0, .EOF
    }
    byte := r.s[r.i]

    // Get the bit that's after however many bits read starting from the MSB in the byte
    bits := 8 - (r.bits_read_in_byte + 1)
    b := (r.s[r.i:r.i+1][0] & auto_cast math.pow2_f32(bits)) >> bits
    r.bits_read_in_byte += 1

    if r.bits_read_in_byte == 8 {
        r.i += 1
        r.bits_read_in_byte = 0
    }

    return b, nil
}

read_bits :: proc(r: ^Reader, n: int) -> (bits: i64, err: Error) {
    x: i64 = 0

    for i in 0 ..< n {
        x = 2 * x + auto_cast read_bit(r) or_return
    }

    return x, nil
}

read_byte :: proc(r: ^Reader) -> (b: byte, err: Error) {
  if r.i >= i64(len(r.s)) {
    return 0, .EOF
  }
  // Continue reading from the current byte if it has unread bits.
  // Needed for the subframes.
  if r.bits_read_in_byte != 0 {
      b = u8(read_bits(r, 8) or_return)
  } else {
      b = r.s[r.i]
      r.i += 1
  }
  return b, nil
}

align_to_byte :: proc(r: ^Reader) -> Error {
    if r.bits_read_in_byte == 0 {
        return nil
    }
    if r.i >= i64(len(r.s)) {
        return .EOF
    }

    // Align by skipping the remaining bits in the byte
    r.bits_read_in_byte = 0
    r.i += 1

    return nil
}
