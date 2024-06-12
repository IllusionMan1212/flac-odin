Files:-
14 -> MD5 mismatch
23 -> MD5 mismatch
27 -> This one uses the old format of specifying a variable block strategy. Look into it.
	  The way to know the blocking strategy for this old format FLACs is to see if min_block_size and max_block_size are different,
	  if they are, then the blocking strategy is VARIABLE, if not, then it's FIXED.
	  Also MD5 mismatch
28 -> MD5 mismatch
29 -> MD5 mismatch
30 -> MD5 mismatch
31 -> MD5 mismatch
32 -> MD5 mismatch
33 -> MD5 mismatch
34 -> MD5 mismatch
35 -> MD5 mismatch
36 -> MD5 mismatch
38 -> MD5 mismatch
39 -> MD5 mismatch
40 -> MD5 mismatch
44 -> MD5 mismatch + High memory and CPU usage. needs optimization.
--- 40s and 50s have a lot of MD5 mismatches too, too lazy to write them.
60 -> MD5 mismatch
61 -> MD5 mismatch
63 -> MD5 mismatch
64 -> MD5 mismatch

uncommon/01 -> This one decodes fine but the expected MD5 is 0x00 * 16 which doesn't match the calculated MD5. not sure what to do about this.
uncommon/02 -> No MD5
uncommon/03 -> No MD5
uncommon/04 -> We get a bits per sample mismatch
uncommon/05 -> MD5 mismatch
uncommon/06 -> MD5 mismatch
uncommon/10 -> We error with Invalid Signature. I assume for these two I should look for the frame sync bits. But maybe my decoder should reject these. idk.
uncommon/11 -> We error with Invalid Signature

faulty/01 -> This one works when it shouldn't (Wrong max blocksize)
faulty/02 -> This one works when it shouldn't (Wrong max framesize)
faulty/04 -> We fail on Invalid_Coefficient_Precision. This one has a wrong number of channels (whatever that means)
faulty/05 -> This one works when it shouldn't. (Wrong number of samples)
faulty/08 -> This one works when it shouldn't. (Blocksize 65536, exceeds the allowed max of 65535)
faulty/09 -> This one works when it shouldn't. (Blocksize 1, below the allowed min of 16 (last frame(subframe?) is allowed to have less than 16))

Things:-
[ ] Lots of checks (look at the TODOs in flac.odin)
[ ] MD5 checksums (depends on stereo decorrelation)
	- [x] VERBATIM subframe (seems to work fine if all frames are verbatim, might not work if mixed with other frames)
	- [ ] CONSTANT subframe
	- [x] FIXED subframe
	- [ ] LPC subframe
[ ] Seeking
[x] RICE2
[x] Add check for mismatched bits per sample
[x] Unencoded BPS is zero
[x] CONSTANT subframe
[x] Stereo Decorrelation

[ ] Encoder (low priority for now)

Security:-
Security concerns will be considered after making the decoder work correctly and robustly.
