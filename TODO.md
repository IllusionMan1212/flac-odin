Files:-
27 -> This one uses the old format of specifying a variable block strategy. Look into it.
	  The way to know the blocking strategy for this old format FLACs is to see if min_block_size and max_block_size are different,
	  if they are, then the blocking strategy is VARIABLE, if not, then it's FIXED.

Playback issues in the example program that may relate to the decoder:-
23 - Crunchy loud noise mixed with the actual audio data

uncommon/04 -> We get a bits per sample mismatch
uncommon/10 -> We error with Invalid Signature. I assume for these two I should look for the frame sync bits. But maybe my decoder should reject these. idk.
uncommon/11 -> We error with Invalid Signature

faulty/01 -> This one works when it shouldn't (Wrong max blocksize)
faulty/02 -> This one works when it shouldn't (Wrong max framesize)
faulty/04 -> This one works when it shouldn't. This one has a wrong number of channels (whatever that means)
			 Each frame has to be played by itself, otherwise plays sped up.
faulty/05 -> This one works when it shouldn't. (Wrong number of samples)
			 This should be fine to decode and play.
faulty/08 -> This one works when it shouldn't. (Blocksize 65536, exceeds the allowed max of 65535)
			 We should error here. We segfault currently.
faulty/09 -> This one works when it shouldn't. (Blocksize 1, below the allowed min of 16 (only the last frame is allowed to have less than 16))
			 We should error here. We play correctly currently.
faulty/11 -> We return an error now, but we should just warn and decode the audio fine.

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
[ ] Seeking
[ ] Fuzzing to test the stability of the code
[ ] Check if the use-after-free bug happens on Windows, and if so, if the address sanitizer will show us the full stacktrace
	instead of skipping some procs.

[ ] Encoder (low priority for now)

Security:-
Security concerns will be considered after making the decoder work correctly and robustly.
