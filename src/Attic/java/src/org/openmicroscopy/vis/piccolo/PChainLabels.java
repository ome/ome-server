/*
 * org.openmicroscopy.vis.piccolo.PChainLabels
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
import java.util.Collection;
import org.openmicroscopy.vis.ome.CChain;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.Iterator;

/** 
 * A parent node for labels that hold dataset names.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PChainLabels extends PNode {
	
	private static final double VGAP =5;
	private static final double HGAP=40;
	private double area = 0;
	
	public PChainLabels(Collection datasets) {
		super();
		Iterator iter = datasets.iterator();
		CChain c;
		while (iter.hasNext()) {
			c = (CChain) iter.next();
			buildLabel(c);
		}
	}
		
	private void buildLabel(CChain c) {
		PNode node  = new PChainLabelText(c);
		addChild(node);
		PBounds b = node.getGlobalFullBounds();
		area += (b.getWidth()+HGAP)*(b.getHeight()+VGAP);
	}
	
	public double getArea() {
		return area;
	}
	
	public void layout(double width) {
		double x =0;
		double y = 0;
		double labelWidth;
		Iterator iter = getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PChainLabelText) {
				// layout.
				PChainLabelText p = (PChainLabelText) obj;
				PBounds b = p.getGlobalFullBounds();
				labelWidth = b.getWidth();
				if (x+labelWidth > width && x > 0) {
					x = 0;
					y += b.getHeight()+VGAP;
				}
				p.setOffset(x,y);
				x +=labelWidth+HGAP;
			}
		}
	}
	
}


