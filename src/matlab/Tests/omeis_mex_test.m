% Tom Macura August 27th, 2005
%
% This test exploit's OMEIS SHA1 based pixels redundancy check to test if the
% getPixels, setPixels, getROI, setROI commands work correctly.
% It is following a convolution path which essentially takes a PixelsSet and
% clones it. We know the clone process happened correctly if the PixelsID
% returned by finishPixels matches the original PixelID

function omeis_mex_test ()

% I am assuming that OMEIS is hosted on the local computer
[s, hostname] = system('hostname');
hostname = hostname(1:end-1);
hostname = sprintf('%s/cgi-bin/omeis', hostname);

% This is hacked code and is evil.
% It queries the ome database to figure out what are the valid OMEIS pixel ids
perl_script = fopen ('omeis_test_helper.pl', 'w');
fprintf(perl_script, 'use strict;\nmy $inf = "ids_tmp";\nmy $ouf = "ids_tmp_clean";\nopen (FILE_IN, "< $inf") or die;\nopen (FILE_OUT, "> $ouf") or die;\nwhile (<FILE_IN>) {\n    print FILE_OUT $1." " if m/\\s*(\\d+)\\s*/;\n}\nclose(FILE_IN);\nclose(FILE_OUT);\n');
fclose(perl_script);

system('/usr/bin/psql -d ome -o ids_tmp -c "SELECT image_server_id FROM image_pixels"');
perl('omeis_test_helper.pl');
ids = sort(load('ids_tmp_clean'));
system('rm ids_tmp ids_tmp_clean omeis_test_helper.pl');

fprintf ('Extracted Info about your OME install\n');
fprintf ('            OMEIS URL: %s\n', hostname);
fprintf ('   OMEIS Pixels Count: %d\n\n', length(ids));

fprintf ('Starting OME/MATLAB Test:');
is = openConnectionOMEIS(hostname);

counter_bp_1_passed = 0;
counter_bp_2_passed = 0;
counter_bp_1_failed = 0;
counter_bp_2_failed = 0;

for pix_id = ids
    fprintf ('Processing PixelsID %d:\n', pix_id);
    
    fprintf ('\tPixelsInfo ...'); im_struct = pixelsInfo (is, pix_id);   fprintf (' done\n');
    if (im_struct.isFinished)
	    fprintf ('\tnewPixels ...');  n_pix_id = newPixels (is, im_struct);  fprintf (' done\n');
    
    	% get image and remove top left corner
    	fprintf ('\tgetPixels ...');  im = getPixels(is, pix_id);            fprintf (' done\n');
    	% figure; imshow(im, [min(min(im)) max(max(im))]);
    
	    [sizeX, sizeY, sizeZ, sizeC, sizeT] = size(im);
   		im (1:floor(sizeX/2), 1:floor(sizeY/2)) = 0;
    
	    % set image (without top left corner) on OMEIS
    	fprintf ('\tsetPixels ...');  setPixels(is, n_pix_id, im);           fprintf (' done\n');
    
	    % get top left corner and set it on the new imae
    	fprintf ('\tgetROI ...');
    	im_q = getROI(is, pix_id, floor(sizeX/4), floor(sizeY/4), 0, 0, 0, floor(sizeX/3)-1, floor(sizeY/2)-1, 0, 0, 0);
    	fprintf (' done\n');
    	% figure; imshow(im_q, [min(min(im_q)) max(max(im_q))]);
    
    	fprintf ('\tsetROI ...');
    	num_pixels = setROI (is, n_pix_id, floor(sizeX/4), floor(sizeY/4), 0, 0, 0, floor(sizeX/3)-1, floor(sizeY/2)-1, 0, 0, 0, im_q);;
    	fprintf (' done\n');
    
	    fprintf ('\tfinishPixels ...'); n_pix_id = finishPixels (is, n_pix_id); fprintf (' done\n');
    	% figure; imshow(getPixels(is,n_pix_id), [min(min(im)) max(max(im))]);
    
    	if (n_pix_id == pix_id)
			if (im_struct.bp == 1)
				counter_bp_1_passed = counter_bp_1_passed + 1;
    		else
				counter_bp_2_passed = counter_bp_2_passed + 1;
			end
       		fprintf ('TEST PASSED \n\n');
    	else
			if (im_struct.bp == 1)
				counter_bp_1_failed = counter_bp_1_failed + 1;
			else
				counter_bp_2_failed = counter_bp_2_failed + 1;
			end
	
			fprintf ('\tdeletePixels ...'); n_pix_id = deletePixels (is, n_pix_id); fprintf (' done\n');	
    		fprintf ('TEST FAILED New PixelsID is %d\n\n', n_pix_id);
    	end
    else
    	fprintf ('SKIPPED unfinished pixels\n');
    end
end

fprintf ('TESTS PASSED (bp=1) [%d] (bp=2) [%d]\n', counter_bp_1_passed, counter_bp_2_passed);
fprintf ('TESTS FAILED (bp=1) [%d] (bp=2) [%d]\n', counter_bp_1_failed, counter_bp_2_failed);
