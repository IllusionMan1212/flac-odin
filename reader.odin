//+private
package flac

import "core:bytes"
import "core:io"

/* Basic byte reader with support for reading bits.
 Uses core:bytes reader under the hood with a few useful procedures for reading structs and other types.
*/
Reader :: struct {
    using _: bytes.Reader,
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

// TODO: make sure this takes into account the bits in bits_read_in_byte
// Although this is probably not needed since the only times we're not alinged to a byte is when finishing a subframe
// All frames are supposed to end byte-aligned.
read_data :: #force_inline proc(r: ^Reader, $T: typeid) -> (res: T, err: io.Error) {
    b := read_slice(r, size_of(T)) or_return
    return (^T)(&b[0])^, nil
}

pow2 :: #force_inline proc(#any_int exp: uint) -> int {
    return 1 << exp
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

//read_bits :: proc(r: ^Reader, n: int) -> (bits: u64, err: Error) {
//    x: u64 = 0
//
//    for i in 0 ..< n {
//        x = 2 * x + auto_cast read_bit(r) or_return
//    }
//
//    return x, nil
//}

// TODO: optimize this even more
read_bits :: proc(r: ^Reader, n: int) -> (bits: u64, err: Error) #no_bounds_check {

    //if n % 8 == 0 {

    //}


    //if r.bits_remaining < u8(n) {
    //    // we need to read into the next byte too and possibly more bytes
    //} else if r.bits_remaining == u8(n) {
    //    r.bits_remaining = 0
    //    r.i += 1
    //} else {

    //}

    n := n
    for n > 0 {
		if r.i >= i64(len(r.s)) {
			return 0, .EOF
		}

		to_read := min(n, 8-int(r.bits_read))
		mask := (1 << u8(to_read)) - 1
		shift := 8 - int(r.bits_read) - to_read

		// Extract bits from the current byte
		bitsPart := u64(r.s[r.i] >> u8(shift)) & u64(mask)
		bits |= bitsPart << u64(n - to_read)

		// Update counters
		r.bits_read += u8(to_read)
		n -= to_read

		// Move to the next byte if all bits in the current byte have been read
		if r.bits_read == 8 {
			r.i += 1
			r.bits_read = 0
		}
	}

    return bits, nil
}

read_byte :: proc(r: ^Reader) -> (b: byte, err: Error) #no_bounds_check {
  if r.i >= i64(len(r.s)) {
    return 0, .EOF
  }
  // Continue reading from the current byte if it has unread bits.
  // Needed for the subframes.
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
