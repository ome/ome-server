/*
 * org.openmicroscopy.vis.piccolo.PDataset
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
import org.openmicroscopy.vis.ome.CImage;

import org.openmicroscopy.vis.ome.Connection;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import java.util.Collection;
import java.util.Iterator;

/** 
 * A subclass of {@link PCategorBox} that is used to provide a colored 
 * background to the display of images in a dataest 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */

public class PDataset extends PGenericBox {
	
	private CDataset dataset;
	private Connection connection;
	
	private static float VGAP=10;
	private static float HGAP=5;
	private static float FUDGE=5;

	private double x=HGAP;
	private double y=VGAP;
	private float maxHeight = 0;
	private float maxWidth=0;
	private PText nameLabel;
	private PText chainLabel;
	private PChainLabels chainLabels;
	private double LABEL_SCALE=.4;
	
	private double area = 0;

	private double prevWidth;
	private double width;
	
	
	public PDataset(CDataset dataset,Connection connection) {
		super();
		this.dataset = dataset;
		this.connection = connection;
		calcArea();
	}

	private void calcArea() {
		removeAllChildren();
		x=HGAP;
		y=VGAP;
		//	draw label
		//System.err.println("laying out dataset "+dataset.getName());
		 nameLabel = new PText(dataset.getLabel());
		  
		 addChild(nameLabel);
		 PBounds b = nameLabel.getBounds();//nameLabel.getGlobalFullBounds();
		 area += b.getWidth()*b.getHeight();
		 //System.err.println(" label area is "+area);
		 int sz = dataset.getImageCount();

		if (sz > 20) {
			//System.err.println("too many ..images..");
			displayDatasetSizeText(sz);
			return;
		}
		
		Collection images = dataset.getCachedImages(connection);
		Iterator iter = images.iterator();
		maxHeight = 0;
		maxWidth = 0;
		//Vector nodes = new Vector();
		
		nameLabel.setOffset(x,y);
		y+= nameLabel.getHeight()+VGAP;
		//System.err.println("after name label y is "+y);
		float imHeight=0;
		float imWidth =0;
		//draw them
		while (iter.hasNext()) {
			CImage image = (CImage) iter.next();
			PThumbnail thumb = new PThumbnail(image);
			addChild(thumb);
			imHeight  = (float) thumb.getGlobalFullBounds().getHeight();
			imWidth = (float) thumb.getGlobalFullBounds().getWidth();
		
			if (imHeight > maxHeight)
				maxHeight = imHeight;
		}
		
		//	System.err.println("laying out images. width is "+maxWidth);
	
		// space them
		maxHeight += VGAP;
		
		iter = getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PThumbnail) {
				PThumbnail p = (PThumbnail) obj;
			    b = p.getGlobalFullBounds();
				//System.err.println("max height is "+maxHeight);
				//System.err.println("width is "+b.getWidth());
				double imagearea = (b.getWidth()+HGAP)*maxHeight;
				//System.err.println("image area is "+imagearea);
				area += imagearea;
			}
		}
		
		Collection chains = dataset.getChains(connection);
		
		if (chains.size() > 0) {
			chainLabel =new PText("Executions: ");
			chainLabel.setFont(PConstants.LABEL_FONT);
			chainLabel.setPickable(false);
			chainLabel.setScale(LABEL_SCALE);
			addChild(chainLabel);
			b = chainLabel.getGlobalFullBounds();
			double clarea =(b.getWidth()+HGAP)*(b.getHeight()+VGAP);
			//System.err.println("chain label area is "+clarea);
			area += clarea;
			
			chainLabels = new PChainLabels(chains);
			addChild(chainLabels);
			//System.err.println("chain labels area is "+chainLabels.getArea());
			area += chainLabels.getArea();
		}
			
	}
	public void layoutImages() {
		x=HGAP;
		y=VGAP+ nameLabel.getHeight()+VGAP;
		Iterator iter;
	
		iter = getChildrenIterator();
		//System.err.println("laying out images. width is "+width);
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (!(obj instanceof PThumbnail))
				continue;
			
			PThumbnail thumb = (PThumbnail) obj;
		
			//System.err.println("placing thumbnail at "+x+","+y);
			double thumbWidth = thumb.getGlobalFullBounds().getWidth()+HGAP;
			//System.err.println("x is "+x+", thumbwidth "+thumbWidth);
			//System.err.println("y is "+y+", max height is "+maxHeight);
			if (x+thumbWidth  < width) {
				thumb.setOffset(x,y);
			}
			else { 
				y += maxHeight;
				x = HGAP;
				thumb.setOffset(x,y);
			}
		 	x+= thumbWidth;
		}	
		// roll back y if we were just about to start a new row
		if (x== HGAP)
			y-=maxHeight;
		
		y +=maxHeight; // move y ahead. to next row.
		x=HGAP;
		// adjust width
		// insert chains, if any.
		Collection chains = dataset.getChains(connection);
		
		double fullWidth=0;
		if (chains.size() > 0) {
			chainLabel.setOffset(x+HGAP,y);
			PBounds clbounds = chainLabel.getGlobalFullBounds();
			
			// adjust for differentials in scale.
			double ratio =   PChainLabelText.LABEL_SCALE/LABEL_SCALE;
			y += (1-ratio)*clbounds.getHeight()-FUDGE;
			chainLabels.layout(width);
			chainLabels.setOffset(x+clbounds.getWidth()+2*HGAP,y);
			
			PBounds b2 =chainLabels.getGlobalFullBounds();
			y+= b2.getHeight()+VGAP;
			fullWidth =  b2.getX()+b2.getWidth()+VGAP;
			if (fullWidth > width)
				width = fullWidth;
		}
		
		float height =(float)y-VGAP;
		
		//System.err.println("width of dataset is "+width);
		//System.err.println("height is "+height);
		setExtent(width+PConstants.SMALL_BORDER,
			height+PConstants.SMALL_BORDER);
	}
	
	public double getContentsArea() {
		return area;
	}
	
	private void displayDatasetSizeText(int size) {
		PText text = new PText(size +" Images");
		addChild(text);
		text.setOffset(HGAP,y);
		y+= text.getHeight()+VGAP;
		double width =text.getWidth();
		if (nameLabel.getWidth() > width) {
			width = nameLabel.getWidth();
		}
		setExtent(width+2*HGAP,y);
	}
	/**
	 * @return Returns the dataset.
	 */
	public CDataset getDataset() {
		return dataset;
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = getFullBoundsReference();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER,
			b.getY()-PConstants.SMALL_BORDER,
			b.getWidth()+2*PConstants.SMALL_BORDER,
			b.getHeight()+2*PConstants.SMALL_BORDER);
	}
	/**
	 * @return Returns the prevWidth.
	 */
	public double getPrevWidth() {
		return prevWidth;
	}

	/**
	 * @return Returns the width.
	 */
	public double getWidth() {
		return width;
	}
	/**
	 * @param width The width to set.
	 */
	public void setWidth(double width) {
		prevWidth = this.width;
		this.width = width;
	}
	
	public void revertWidth() {
		width = prevWidth;
	}
	
	public void clearWidths() {
		width = prevWidth = 0;
	}
}
