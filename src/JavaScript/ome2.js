/*------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institute of Technology,
 *      National Institutes of Health,
 *      University of Dundee
 *
 *
 *
 *    This library is free software; you can redistribute it and/or
 *    modify it under the terms of the GNU Lesser General Public
 *    License as published by the Free Software Foundation; either
 *    version 2.1 of the License, or (at your option) any later version.
 *
 *    This library is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    Lesser General Public License for more details.
 *
 *    You should have received a copy of the GNU Lesser General Public
 *    License along with this library; if not, write to the Free Software
 *    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *------------------------------------------------------------------------------
 */




/*------------------------------------------------------------------------------
 *
 * Written by:    Chris Allan <callan@blackcat.ca>
 * 
 * Ported from original functions written by Jean-Marie Burel
 *                                           <j.burel@dundee.ac.uk>
 *
 *------------------------------------------------------------------------------
 */


/*
 *
 * PAGE CONSTANTS
 *
 */

GetGraphicsPage = '/perl2/serve.pl?Page=OME::Web::GetGraphics';
GetInfoPage     = '/perl2/serve.pl?Page=OME::Web::GetInfo';
InfoProjectPage = '/perl2/serve.pl?Page=OME::Web::InfoProject';
InfoDatasetPage = '/perl2/serve.pl?Page=OME::Web::InfoDataset';

/*
 *
 * FUNCTIONS
 *
 */

// openExistingDataset()
	
function openExistingDataset (group_id) {
	window.open(
		InfoDatasetPage + '&UsergpID=' + group_id,
		'ExistingDataset',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}

// openExistingProject()

function openExistingProject (group_id) {
	window.open(
		InfoProjectPage + '&UsergpID=' + group_id,
		'ExistingProject',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}

// openInfoDataset()

function openInfoDataset (dataset_id) {
	window.open(GetInfoPage + '&DatasetID=' + dataset_id,
		'InfoDataset',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}

// openInfoProject()

function openInfoProject (project_id) {
	window.open(GetInfoPage + '&ProjectID=' + project_id,
		'InfoProject',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}

// openInfoDatasetImport()

function openInfoDatasetImport (dataset_id) {
	window.open(GetInfoPage + '&DatasetID=' + dataset_id,
		'InfoDatasetImport',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}
	
// openPopUpDataset()

function openPopUpDataset (dataset_id) {
	window.open(GetGraphicsPage + '&DatasetID=' + dataset_id,
		'DatasetViewer',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}


// openPopUpImage()

function openPopUpImage (image_id) {
	window.open(GetGraphicsPage + '&ImageID=' + image_id,
		'ImageViewer',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500');
}
