Directions for using OME's Pattern Analysis Infrastruction to run classification or image similarity experiments. 
Written by Josiah Johnston on June 29, 2007


Step 0: Feature computation
	* Import images into OME using the "Import and Annotate Wizard" in the web interface
	* Click "Execute Chain" under the analysis menu on the left
		* Step 1: click "Select" next to step 1, click "Advanced Search" in the pop-up, scroll up and select "All" under Owner, click Search, select the radio box by the "1025 FeatureExtractionChain", and click "Select checked objects"
		* Step 2: Make sure the dataset is what you want to compute on. Click "C" to change it if needed.
		* Step 4: Click "Select" next to "...Number of Tiles" to search for how many tiles to use. Do the same for "...Selected Planes" if you have a multi-channel image and wish to only compute on some of the planes.
		* When you are satisfied with the inputs, click the "Execute Chain" button. The chain execution will take a while, around 2-5 minutes per tile?
	* Export the features to a '.mat' file. See  http://openmicroscopy.org/system-admin/docs/dev_classifier_compile_sigs.html

Step 1: Analysis Setup
	* Copy file(s) of control data to data/OrigSigData/computedInOME_AE
	* Massage the variables to fit the needs of your experiment. (see data file section below)
	* If control data that has accompanying experimental data, make a directory under data/OrigSigData/computedInOME_AE named after the control data file (e.g. foo.mat would get a directory foo), and copy the experimental data into that directory.

Step 2: Analysis Execution
	* Single-process: Open matlab, go to the analysis directory, and type 'run'
	* Multi-process: Open run.m in a text editor and uncomment the "%exit;" line. One the command line, go to the master directory, and type 
		`matlab < run.m &> logs/run.machineX.log.Y &`
	for as many processes as you want to have working on the problem. 

Step 3: Report compilation (typically only needed with multi-threaded execution)
	* Make sure everything finished ok (i.e. no '*in.progress' files left)
		`find data -name '*in.progress'` returns blank
	* Then do `matlab < run.m` again to compile reports

Reports are available under reports/index.html

DATA FILE
	Mandatory variables
* category_names: A cell array of the names of the categories the model will be based on
* image_paths: A cell array of labels for each column in the signature matrix
* signature_labels: A cell array of labels for each signature, or feature
* signature_matrix: A 2-d double array. Rows are indexed by signature, or feature, and columns are indexed by images, or tiles. The last row indicates the class.
	Optional variables
* dataset_name: The name of the data in this file. Defaults to the file name.
* image_thumbnail_href: Stores a url to an image thumbnail for each column of the signature matrix. Will be used in the future during report generation.
* image_metadata_href: Stores a url to detailed information about each column of the signature matrix. Will be used in the future during report generation.
* image_ids: OME image IDs for each column of the signature matrix
* sample_ids: Arbitrary sample IDs for each column of the signature matrix. Typically corresponds to biological replicates.
* split_on: Determines if training/test divisions will be made per-tile, per-image, or pre-sample. Can take the values of "sample_ids", "image_ids", and "tiles". Defaults to sample_ids if that variable is present, then image_ids if that variable is present, and falls back to tiles if neigther variable is present.
	Optional variables if categories are based on a numeric variable
* continuous_values: Stores the numeric experimental value for each column of the signature matrix that the categories are based on.
* class_numeric_values: Stores the mean value of the numeric experimental variable for each class. If present, and continuous_values is absent, continuous_values will be derived from this variable.
	Optional variables for artifact correction
* slide_class_vector: Specifies which slide each column of the signature_matrix was collected from. If present, features that are systematically sensitive to differences between slides of a single experimental condition will be down-played.
* slide_correction_pattern: Can take the place of slide_class_vector. A regular expression that can be applied to image_paths to determine the slide name.
* artifact_correction_vector: A global feature weights vector that identifies which features are systematically sensitive to artifacts. Can be used instead of slide_class_vector.




Troubleshooting multi-process runs:
	If something messes up, kill errant processes, then delete the "*.in.progress" files like so:
		`find data -name '*in.progress*' -exec rm {} \;`
	then restart step 2
	Also, if you delete anything under data/classifiers/ or reports/, it will be re-generated the next time the run command is used.

Advanced topics
	* To change cross-validation settings or types of signatures used, edit run.m
	* To add a pattern recognition algorithm, make a subdirectory under code/Classifiers/ for the new algorithm, and write wrappers (Train.m and Test.m) that follow the conventions and interface of the WND_05 wrappers.
	* Settings for drawing sample-based dendrograms are near the top of code/report.m Currently, sample-based dendrograms often require manual intervention.
	* To manually divide control data into training and test sets, run the analysis and interrupt it after it has finished printing progress on making split directories. Look under data/classifers/YourProblemName/SplitX/ for trainTestSplit.mat. The variables have self explanatory names. Update the variables to your needs, save the file, then delete the subfolder in the directory (e.g. computedInOME_AE). Repeat for all splits, and start the analysis again. Training/test divisions will be loaded from your file instead of being auto-generated.
	* To extend the way trainng/test splits are made, edit updateSplitDirs.m under code/
	* To use a set of signatures that was calculated differently, make a new directory under data/OrigSigData/ to put data files in. Edit run.m to add your new directory next to 'computedInOME_AE'. Delete the "computedInOME_AE" directory and references to it in run.m unless you have both types of signatures computed for all your problems.
