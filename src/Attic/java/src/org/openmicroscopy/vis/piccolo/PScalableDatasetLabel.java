/*
 * org.openmicroscopy.vis.piccolo.PScalableDatasetLabel
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

import org.openmicroscopy.vis.ome.CDataset;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PBounds;
import java.awt.geom.Rectangle2D;

/** 
 * A label that can show the full name of a dataset or an abbreviated name
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PScalableDatasetLabel extends PNode implements PBrowserNodeWithToolTip {

	private static final int NUM_CHARS=20;
	public static final double FULL_WIDTH=100;
	private CDataset dataset;
	
	private PText shortLabel;
	
	public PScalableDatasetLabel(CDataset dataset,double width) {
		this.dataset = dataset;
		
		shortLabel = getShortLabel(width);
		shortLabel.setPickable(false);
		addChild(shortLabel);
	}
	
	private PText getShortLabel(double width) {
		String name = dataset.getName();
		int length = name.length();
		PText res;
		String text;
		//System.err.println("label of width "+width +" for dataset "+name);
		if (length > NUM_CHARS)
			length  = NUM_CHARS;
		do {
			String shortName = name.substring(0,length);
			if (length < name.length() )
				shortName+="..";
			length--;
			text = Integer.toString(dataset.getID())+". "+shortName;
			text += ": "+Integer.toString(dataset.getImageCount())+" images";
			res = new PText(text);	
		//	System.err.println("label: "+text+" width "+res.getWidth());	
		} while (res.getWidth() > width && length >= 0);
		if (res.getWidth() > width) {
			//cut of "images" and just reurn number.
			text =  Integer.toString(dataset.getID())+". "
				+Integer.toString(dataset.getImageCount());
			res = new PText(text);
		}
		return res;
	}
	
	public void resetWidth(double width) {
		removeChild(shortLabel);
		shortLabel = getShortLabel(width);
		shortLabel.setPickable(false);
		addChild(shortLabel);
	}
	
	public PNode getFullToolTip() {
		PPath p = new PPath();
		String name = dataset.getName();
		String shortName;
		String res = Integer.toString(dataset.getID())+". "+name+" \n";
		
		PText node = new PText(res);
		node.setConstrainWidthToTextWidth(false);
		
		if (node.getWidth() > FULL_WIDTH) {
			PBounds b = node.getBounds();
			node.setBounds(b.getX(),b.getY(),FULL_WIDTH,b.getHeight());
		}
		p.addChild(node);
		PText count = new 
			PText(Integer.toString(dataset.getImageCount())+" images");
		p.addChild(count);
		count.setOffset(0.0,node.getHeight());
		
		p.setPathTo(p.getUnionOfChildrenBounds(null));
		p.setPaint(PToolTipHandler.FILL_COLOR);
		p.setStrokePaint(PToolTipHandler.BORDER_COLOR);
		return p;
	}
	
	public PBounds getBounds() {
		
		return shortLabel.getBounds();
	}
	
	
	public boolean intersects(Rectangle2D localBounds) {
		return shortLabel.intersects(localBounds);
	}
	
	
	
	public PNode getShortToolTip() {
		return getFullToolTip();
	}
}