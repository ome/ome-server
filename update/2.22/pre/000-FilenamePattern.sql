-- Change the name and regex for the metamorph tiff filename pattern
-- Add a time fragment to the pattern and specify that its for tiffs from Metamorph
UPDATE filename_pattern
    SET name='Metamorph Filename Pattern for TIFFs',
    regex='^(.+)(_w)(\d+.*)(_t)(\d+)(.*)',
    the_t = 5
WHERE attribute_id = (
    SELECT fp.attribute_id
    FROM filename_pattern fp, lsid_object_map lsid
    WHERE fp.attribute_id = lsid.object_id
        AND lsid.lsid = 'urn:lsid:openmicroscopy.org:FilenamePattern:0'
        AND fp.regex='^(.+)(_w)(\d+)(.*)'
    );
