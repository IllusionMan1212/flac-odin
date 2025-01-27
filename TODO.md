Files:-
27 -> This one uses the old format of specifying a variable block strategy. Look into it.
	  The way to know the blocking strategy for this old format FLACs is to see if min_block_size and max_block_size are different,
	  if they are, then the blocking strategy is VARIABLE, if not, then it's FIXED.

Playback issues in the example program that may relate to the decoder:-
23 - Crunchy loud noise mixed with the actual audio data

uncommon/02 -> 6 channel audio might be incorrect (not a decoder issue afaik)
uncommon/04 -> We get a bits per sample mismatch
uncommon/10 -> We error with Invalid Signature. I assume for these two I should look for the frame sync bits. But maybe my decoder should reject these. idk.
uncommon/11 -> We error with Invalid Signature

faulty/01 -> This one works when it shouldn't (Wrong max blocksize)
faulty/02 -> This one works when it shouldn't (Wrong max framesize)

Things:-
[ ] Options
	- [x] Vorbis comment data
	- [ ] Cuesheet ?
	- [ ] Seektable ?
	- [x] Picture data
[x] File streaming API? io.Stream??
[ ] Lots of checks (look at the TODOs in flac.odin)
[x] Memory optimizations
[ ] Speed optimizations
	- Does this matter? So far I haven't found a FLAC file that lags while playing or stalls the audio device even without `-o:speed`
[ ] Seeking
[ ] Fuzzing to test the stability of the code
[x] Check if the use-after-free bug happens on Windows, and if so, if the address sanitizer will show us the full stacktrace
	instead of skipping some procs.
	This was caused by `read_data()` and the tee reader writing into the buffer and us using some memory that was freed while the buffer
	resized. Solution is to use buffer data BEFORE calling `read_data()`

[ ] Encoder (low priority for now)

Security:-
Security concerns will be considered after making the decoder work correctly and robustly.
