/*
 * org.openmicroscopy.vis.piccolo.PChainBox
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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

import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.chains.SelectionState;
import edu.umd.cs.piccolo.PNode;

import edu.umd.cs.piccolo.util.PBounds;
import java.util.Iterator;
import java.util.Collection;


/** 
 * A parent node for labels that hold dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PDatasetLabels extends PNode {
	
	private double x =0;
	private double y =0;
	private double HGAP=40;
	private double VGAP=20;
	private double width=0;
	
	public PDatasetLabels(Collection datasets,double width,
			SelectionState selectionState) {
		super();
		this.width = width;
		Iterator iter = datasets.iterator();
		CDataset ds;
		
		while (iter.hasNext()) {
			ds = (CDataset) iter.next();
			buildLabel(ds,selectionState);
		}
	}
	
	private void buildLabel(CDataset ds,SelectionState selectionState) {
		PDatasetLabelText p = new PDatasetLabelText(ds,selectionState);
	
		addChild(p);
		PBounds b = p.getGlobalFullBounds();
		double labelWidth = b.getWidth();
		if (x+labelWidth > width) {
			x =0;
			y+=b.getHeight()+VGAP;
		}
		
		p.setOffset(x,y);
		x += labelWidth+HGAP;
	}
}


