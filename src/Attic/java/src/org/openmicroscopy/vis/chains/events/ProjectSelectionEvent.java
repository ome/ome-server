/*
 * org.openmicroscopy.vis.chains.events.ProjectSelectionEvent
 *
 *------------------------------------------------------------------------------
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
 * Written by:    Harry Hochheiser <hsh@nih.gov>
 *
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.vis.chains.events;
import org.openmicroscopy.vis.ome.CProject;
import org.openmicroscopy.vis.chains.SelectionState;
import java.util.Collection;

/** 
 * An event that indicates that a dataset has been selected or deselected
 *
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class ProjectSelectionEvent extends SelectionEvent {
	
	public static final int SELECTED = 1;
	public static final int DESELECTED=2;
	
	private Collection active;
	private CProject project=null;

	// store state so this event always has a source that is non-null	
	public ProjectSelectionEvent(SelectionState state,
			Collection active,CProject selected) {
		super(state);
		this.project = selected;
		this.active = active;
	}
	
	public Collection getProjects() {
		return active;
		
	}
	public CProject getSelectedProject() {
		return project;
	} 		
}