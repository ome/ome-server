/*
 * org.openmicroscopy.vis.piccolo.PPaletteToolTipHandler
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
 
package org.openmicroscopy.vis.piccolo;

import edu.umd.cs.piccolo.PCamera;
import edu.umd.cs.piccolo.event.PInputEvent;
import edu.umd.cs.piccolo.PNode;

public class PPaletteToolTipHandler extends PToolTipHandler {
	
	public PPaletteToolTipHandler(PCamera camera) {
		super(camera);
	}
	
	public void setToolTipString(PInputEvent event) {
			PNode n = event.getInputManager().getMouseOver().getPickedNode();
			double scale = camera.getViewScale();
			setToolTipText("");
			if (scale < PToolTipHandler.SCALE_THRESHOLD) {
				if (n instanceof PModule)
					setToolTipText(((PModule) n).getModule().getName()); 
				else if (n instanceof PFormalParameter) {
					String t = ((PFormalParameter) n).getPModule().
					getModule().getName();
					setToolTipText(t);

				}
			}
		}
}