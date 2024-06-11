Files:-
27 -> This one uses the old format of specifying a variable block strategy. Look into it.
	  The way to know the blocking strategy for this old format FLACs is to see if min_block_size and max_block_size are different,
	  if they are, then the blocking strategy is VARIABLE, if not, then it's FIXED.
61 -> I suspect the predictor DOES overflow here. check it
62 -> I suspect the predictor DOES overflow here. check it
63 -> I suspect the predictor DOES overflow here. check it

uncommon/01 -> This one decodes fine but the expected MD5 is 0x00 * 16 which doesn't match the calculated MD5. not sure what to do about this.
uncommon/02 -> We fail a CRC check
uncommon/03 -> We fail so hard we end up reading an invalid residual coding method
uncommon/04 -> We get a bits per sample mismatch
uncommon/10 -> We error with Invalid Signature. I assume for these two I should look for the frame sync bits. But maybe my decoder should reject these. idk.
uncommon/11 -> We error with Invalid Signature

faulty/01 -> This one works when it shouldn't (Wrong max blocksize)
faulty/02 -> This one works when it shouldn't (Wrong max framesize)
faulty/04 -> We fail on Invalid_Coefficient_Precision. This one has a wrong number of channels (whatever that means)
faulty/05 -> This one works when it shouldn't. (Wrong number of samples)
faulty/08 -> This one works when it shouldn't. (Blocksize 65536, exceeds the allowed max of 65535)
faulty/09 -> This one works when it shouldn't. (Blocksize 1, below the allowed min of 16 (last frame is allowed to have less than 16))

Things:-
[ ] Stereo Decorrelation
[ ] Lots of checks (look at the TODOs in flac.odin)
[ ] MD5 checksums (depends on stereo decorrelation)
	- [ ] VERBATIM subframe
	- [ ] CONSTANT subframe
	- [ ] FIXED subframe
	- [ ] LPC subframe
[ ] Seeking
[x] RICE2
[x] Add check for mismatched bits per sample
[x] Unencoded BPS is zero
[x] CONSTANT subframe

[ ] Encoder (low priority for now)

Security:-
Security concerns will be considered after making the decoder work correctly and robustly.
