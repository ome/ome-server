function [splits_classes, splits_mouse_ids, splits_mouse_labels, splits_contValue] =  read_test_results (path_to_test_results, point, ages)
	
	test_results = load (path_to_test_results);
	
	if (strcmpi (point, 'tile'))
		splits_classes = test_results.class_vector;
		splits_mouse_ids = test_results.sample_ids;
		splits_mouse_labels = test_results.sample_labels;
		splits_contValue = margProb2contValue (test_results.marginal_probs, ages);	
	else
		image_ids = unique(test_results.image_ids);
		num_images = length(image_ids);
		
		for i=1:num_images
			image = image_ids(i);
			tile_indicies = find (image == test_results.image_ids);

			% Convert per tile to per Image statistics
			marginal_probs(i,:) = sum(test_results.marginal_probs([tile_indicies],:)) ./ length(tile_indicies);
			
			splits_classes(i) = test_results.class_vector(tile_indicies(1));
			splits_mouse_ids(i) = test_results.sample_ids(tile_indicies(1));
			splits_mouse_labels(i) = test_results.sample_labels(tile_indicies(1));
		end
		
		splits_contValue = margProb2contValue (marginal_probs, ages);	
	end
return;