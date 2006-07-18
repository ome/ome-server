-- The channel pattern was screwed up if non-numeric characters follow the channel
-- number.  Made the pattern more greedy by changing [^_.]*? to [^_.]*.
UPDATE filename_pattern
	SET regex='^(.*?)((_w(\\d+[^_.]*))|(_t(\\d+)))+'
WHERE regex='^(.*?)((_w(\\d+[^_.]*?))|(_t(\\d+)))+';
