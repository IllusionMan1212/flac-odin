package flac

import "core:io"

// Buffer is a very minimal writable buffer based on bytes.Buffer
Buffer :: struct {
	buf: [dynamic]byte,
}

buffer_init_allocator :: proc(b: ^Buffer, len, cap: int, allocator := context.allocator, loc := #caller_location) {
	b.buf = make([dynamic]byte, len, cap, allocator, loc)
}

buffer_write :: proc(b: ^Buffer, p: []byte) -> (n: int, err: io.Error) {
	return append(&b.buf, ..p), nil
}

buffer_destroy :: proc(b: ^Buffer) {
	delete(b.buf)
}

buffer_to_bytes :: proc(b: ^Buffer) -> []byte {
	return b.buf[:]
}

buffer_to_stream :: proc(b: ^Buffer) -> (s: io.Stream) {
	s.data = b
	s.procedure = _buffer_proc
	return
}

@(private)
_buffer_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	b := (^Buffer)(stream_data)
	#partial switch mode {
	case .Write:
		return io._i64_err(buffer_write(b, p))
	case .Size:
		n = i64(cap(b.buf))
		return
	case .Destroy:
		buffer_destroy(b)
		return
	case .Query:
		return io.query_utility({.Write, .Size, .Destroy})
	}
	return 0, .Empty
}
