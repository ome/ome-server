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
 ProjectInfoPage = '/perl2/serve.pl?Page=OME::Web::DBObjDetail&Type=OME::Project&Popup=1';
 DatasetInfoPage = '/perl2/serve.pl?Page=OME::Web::DBObjDetail&Type=OME::Dataset&Popup=1';
 InfoProjectPage = '/perl2/serve.pl?Page=OME::Web::DBObjTable&Type=OME::Project&Popup=1';
 InfoDatasetPage = '/perl2/serve.pl?Page=OME::Web::DBObjTable&Type=OME::Dataset&Popup=1';
 DetailPage = '/perl2/serve.pl?Page=OME::Web::DBObjDetail';
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
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// addImagesToDataset()

function addImagesToDataset() {
	window.open(
		'/perl2/serve.pl?Page=OME::Web::Search&Popup=1&Type=OME::Image&allow_action=Add%20Images%20to%20this%20Dataset',
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 1000, HEIGHT = 600'
	);
}

// openExistingDataset()
	
function openExistingDataset (group_id) {
	window.open(
		InfoDatasetPage + '&OME::Dataset_group=' + group_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openExistingProject()

function openExistingProject (group_id) {
	window.open(
		InfoProjectPage + '&OME::Project_group=' + group_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoDataset()

function openInfoDataset (dataset_id) {
	window.open(DatasetInfoPage + '&ID=' + dataset_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoProject()

function openInfoProject (project_id) {
	window.open(ProjectInfoPage + '&ID=' + project_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 600'
	);
}

// openInfoDatasetImport()

function openInfoDatasetImport (dataset_id) {
	window.open(DatasetInfoPage + '&ID=' + dataset_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500'
	);
}

// openInfoImage()

function openInfoImage (id) {
	document.location.href = DetailPage + '&Type=OME::Image&ID=' + id;
}

// openPopUpImageAs()

function openPopUpImageAs() {
	if( document.forms && document.forms[0] && document.forms[0].thumb_click_opens) {
		var radio_grp = document.forms[0].thumb_click_opens;
		var val;
		for( var i=0; i<radio_grp.length; i++ ) {
			if( radio_grp[i].checked ) val = radio_grp[i].value;
		}
		return val;
	}
}

// openImage()

function openImage (id) {

	var mode = openPopUpImageAs();
	if ( mode == 'image_detail' ) {
		openInfoImage(id)
	} else {
		openPopUpImage( id );
	} 
}

// openPopUpImage()

function openPopUpImage (id) {

	var mode = openPopUpImageAs();
	if ( mode == 'image_detail' ) {
		document.location.href = DetailPage + '&Type=OME::Image&ID=' + id;
	} else {
		window.open(GetGraphicsPage + '&ImageID=' + id,
			'_blank',
			'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 500');
	} 
}

// openPopUpPixels()

function openPopUpPixels (pixels_id) {
	window.open(GetGraphicsPage + '&PixelsID=' + pixels_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 500, HEIGHT = 500');
}
