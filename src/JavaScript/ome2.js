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
 * Ported from original functions written by: Jean-Marie Burel
 *                                            <j.burel@dundee.ac.uk>
 *
 *------------------------------------------------------------------------------
 */


/*
 *
 * PAGE CONSTANTS
 *
 */

 GetGraphicsPage = '/perl2/serve.pl?Page=OME::Web::GetGraphics&Popup=1';
 ProjectInfoPage = '/perl2/serve.pl?Page=OME::Web::ProjectManagement&Popup=1';
 DatasetInfoPage = '/perl2/serve.pl?Page=OME::Web::DatasetManagement&Popup=1';
 InfoProjectPage = '/perl2/serve.pl?Page=OME::Web::ProjectTable&Popup=1';
 InfoDatasetPage = '/perl2/serve.pl?Page=OME::Web::DatasetTable&Popup=1';
RelationshipPage = '/perl2/serve.pl?Page=OME::Web::ManageRelationships&Popup=1';

/*
 *
 * FUNCTIONS
 *
 */

// selectAllCheckboxes()
function selectAllCheckboxes (select_name) {
	for (i = 0; i < document.datatable.length; i++)
	{
		if (document.datatable.elements[i].type == "checkbox" &&
		    document.datatable.elements[i].name == select_name)
			document.datatable.elements[i].checked = true;
	}
}

// deselectAllCheckboxes()
function deselectAllCheckboxes (select_name) {
	for (i = 0; i < document.datatable.length; i++)
	{
		if (document.datatable.elements[i].type == "checkbox" &&
		    document.datatable.elements[i].name == select_name)
			document.datatable.elements[i].checked = false;
	}
}

// openRelationships()

function openRelationships (o_type, r_type, oid) {
	window.open(
		RelationshipPage + '&o_type=' + o_type + '&r_type=' + r_type + '&oid=' + oid,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openExistingDataset()
	
function openExistingDataset (group_id) {
	window.open(
		InfoDatasetPage + '&UsergpID=' + group_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openExistingProject()

function openExistingProject (group_id) {
	window.open(
		InfoProjectPage + '&UsergpID=' + group_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoDataset()

function openInfoDataset (dataset_id) {
	window.open(DatasetInfoPage + '&DatasetID=' + dataset_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoProject()

function openInfoProject (project_id) {
	window.open(ProjectInfoPage + '&ProjectID=' + project_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoDatasetImport()

function openInfoDatasetImport (dataset_id) {
	window.open(DatasetInfoPage + '&DatasetID=' + dataset_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}
	
// openPopUpDataset()

function openPopUpDataset (dataset_id) {
	window.open(GetGraphicsPage + '&DatasetID=' + dataset_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}


// openPopUpImage()

function openPopUpImage (image_id) {
	window.open(GetGraphicsPage + '&ImageID=' + image_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500');
}

// openPopUpPixels()

function openPopUpPixels (pixels_id) {
	window.open(GetGraphicsPage + '&PixelsID=' + pixels_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500');
}
