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

 GetGraphicsPage  = '/perl2/serve.pl?Page=OME::Web::GetGraphics&Popup=1';
 ProjectInfoPage  = '/perl2/serve.pl?Page=OME::Web::DBObjDetail&Type=OME::Project&Popup=1';
 DatasetInfoPage  = '/perl2/serve.pl?Page=OME::Web::DBObjDetail&Type=OME::Dataset&Popup=1';
 InfoProjectPage  = '/perl2/serve.pl?Page=OME::Web::DBObjTable&Type=OME::Project&Popup=1';
 InfoDatasetPage  = '/perl2/serve.pl?Page=OME::Web::DBObjTable&Type=OME::Dataset&Popup=1';
 DetailPage       = '/perl2/serve.pl?Page=OME::Web::DBObjDetail';
 RelationshipPage = '/perl2/serve.pl?Page=OME::Web::ManageRelationships&Popup=1';
 CreationPage     = '/perl2/serve.pl?Page=OME::Web::DBObjCreate&Popup=1';
 STdocPage        = '/perl2/serve.pl?Page=OME::Web::STdoc&Popup=1';
 SearchPage       = '/perl2/serve.pl?Page=OME::Web::Search&Popup=1';
 SearchPageNoPopup = '/perl2/serve.pl?Page=OME::Web::Search';

/*
 *
 * FUNCTIONS
 *
 */

// selectAllCheckboxes()
function selectAllCheckboxes (select_name) {
	for (i = 0; i < document.forms[0].length; i++)
	{
		if (document.forms[0].elements[i].type == "checkbox" &&
		    document.forms[0].elements[i].name == select_name)
			document.forms[0].elements[i].checked = true;
	}
}

// deselectAllCheckboxes()
function deselectAllCheckboxes (select_name) {
	for (i = 0; i < document.forms[0].length; i++)
	{
		if (document.forms[0].elements[i].type == "checkbox" &&
		    document.forms[0].elements[i].name == select_name)
			document.forms[0].elements[i].checked = false;
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

// creationPopup()
function creationPopup( type, return_to_field ) {
	window.open(
		CreationPage + '&Locked_Type=' + type + '&return_to=' + return_to_field,
		'_create_'+type+'_for_'+return_to_field,
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 1000, HEIGHT = 600'
	);
}

// annotateImage()
function annotateImage( image_id, semantic_type ) {
	window.open(
		CreationPage + '&Locked_Type=' + semantic_type + '&refresh_when_done=1' + '&image=' + image_id,
		'annotateImage',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 300'
	);
}

// annotateDataset()
function annotateDataset( dataset_id, semantic_type ) {
	window.open(
		CreationPage + '&Locked_Type=' + semantic_type + '&refresh_when_done=1' + '&dataset=' + dataset_id,
		'annotateDataset',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 300'
	);
}

// STdocPopup()
function STdocPopup( ST_name ) {
	window.open(
		STdocPage + '&ST_name=' + ST_name,
		'_doc',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 250'
	);
}

// SEdocPopup()
function SEdocPopup( SE_id ) {
	window.open(
		STdocPage + '&SE_id=' + SE_id,
		'_doc',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 600, HEIGHT = 250'
	);
}

// selectOne()

function selectOne( type, return_to ) {
	window.open(
		SearchPage + '&Locked_SearchType=' + type + '&select=one&return_to=' + return_to,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = yes, RESIZABLE = yes, WIDTH = 1000, HEIGHT = 600'
	);
}

// selectMany()

function selectMany( type, return_to, url_parameter ) {
	var url = SearchPage + '&Locked_SearchType=' + type + '&select=many&return_to=' + return_to;
	if( url_parameter ) {
		url += '&'+url_parameter;
	}
	window.open(
		url, '_blank',
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

function openInfoDataset (dataset_id, url_parameter) {
	var url = DatasetInfoPage + '&ID=' + dataset_id;
	if( url_parameter ) {
		url += '&'+url_parameter;
	}
	window.open(url, '_blank',
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
	} else if( mode == 'declassify' ) {
		declassifyImage( id );
	} else if( mode == 'classify' ) {
		classifyImage( id );
	} else {
		openPopUpImage( id );
	} 
}

function declassifyImage (id) {
	if( document.forms && document.forms[0] && document.forms[0].declassifyImage) {
		document.forms[0].declassifyImage.value = id;
		document.forms[0].submit();
	} else {
		alert( 'The document does not have a form properly set up to declassify images.' );
	}
}

function classifyImage (id) {
	if( document.forms && document.forms[0] && document.forms[0].classifyImage) {
		document.forms[0].classifyImage.value = id;
		document.forms[0].submit();
	} else {
		alert( 'The document does not have a form properly set up to classify images.' );
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

// openPopUpOverlay()

function openPopUpOverlay (mex) {

	window.open(GetGraphicsPage + '&MEX_ID=' + mex,
			'_blank',
			'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 500');
}

// openPopUpPixels()

function openPopUpPixels (pixels_id) {
	window.open(GetGraphicsPage + '&PixelsID=' + pixels_id,
		'_blank',
		'TOOLBAR = no, LOCATION = no, STATUS = no, MENUBAR = no, SCROLLBARS = no, RESIZABLE = yes, WIDTH = 600, HEIGHT = 500');
}

// SYNOPOSIS
//	<a href="javascript: search( 'OME::Dataset', 'name', 'foo' );">Search for datasets named foo</a>
//	<a href="javascript: search('@DatasetAnnotation', 'Dataset', <TMPL_VAR Name='id'>)'">Search for dataset annotations associated to this dataset</a>
//	<a href="javascript: search('OME::Image', '__order', '!inserted');">Search for recently imported images</a>
// INTRO
//	Search( SEARCH_TYPE, SEARCH_FIELD, FIELD_VALUE, SEARCH_FIELD_2, FIELD_2_VALUE, ...)
// DESCRIPTION
//	Redirect to a search page.	An API for html templates that wish to 
// search. It uses the same calling convention as $factory->findObjects(...)
function search() {
	var search_type = arguments[0];
	var url = SearchPageNoPopup + '&SearchType=' + search_type;
	for( i = 1; i< arguments.length; i += 2 ) {
		url += '&' + arguments[i] + '=' + arguments[i+1];
	}
	window.location = url;
}
