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
	
	private static float VGAP=5;
	private static float HGAP=5;
	private static float FUDGE=5;

	private double x=HGAP;
	private double y=VGAP;
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
		dataset.setNode(this);
		calcArea();
	}

	private void calcArea() {
		removeAllChildren();
		x=HGAP;
		y=VGAP;
		//	draw label
		 nameLabel = new PText(dataset.getLabel());
		  
		 addChild(nameLabel);
		 PBounds b = nameLabel.getBounds();
		 area += b.getWidth()*b.getHeight();
		 int sz = dataset.getImageCount();

		
		Collection images = dataset.getCachedImages(connection);
		Iterator iter = images.iterator();
		double maxHeight = 0;
		//Vector nodes = new Vector();
		
		nameLabel.setOffset(x,y);
		y+= nameLabel.getHeight()+VGAP;
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
		
	
		// space them
		maxHeight += VGAP;
		
		iter = getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PThumbnail) {
				PThumbnail p = (PThumbnail) obj;
			    b = p.getGlobalFullBounds();
				double imagearea = (b.getWidth()+HGAP)*maxHeight;
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
			area += clarea;
			
			chainLabels = new PChainLabels(chains);
			addChild(chainLabels);
			area += chainLabels.getArea();
		}
			
	}
	
	public void layoutImages() {
		x=HGAP;
		y=VGAP+ nameLabel.getHeight()+VGAP;
		Iterator iter;
		double maxWidth = 0;
		double maxHeight = 0;
	
		PBounds b;
		
		// tweak width to make label fit.
		iter = getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (!(obj instanceof PThumbnail))
				continue;
			
			PThumbnail thumb = (PThumbnail) obj;
		
			b =  thumb.getGlobalFullBounds();
			double thumbWidth = b.getWidth()+HGAP;
			if (x+thumbWidth  < width) {
				thumb.setOffset(x,y);
			}
			else {
				y += maxHeight+VGAP;
				x = HGAP;
				thumb.setOffset(x,y);
				maxHeight = 0;
			}
			if (thumb.getGlobalFullBounds().getHeight() > maxHeight) 
				maxHeight = (float)thumb.getGlobalFullBounds().getHeight();
		 	x+= thumbWidth;
		 	if (x > maxWidth) {
		 		maxWidth =  x;
		 	}
		}	
	
		
		y +=maxHeight+VGAP; // move y ahead. to next row.
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
			if (fullWidth > maxWidth)
				maxWidth = fullWidth;
		}
		
		float height =(float)y-VGAP;
		
		if (maxWidth < nameLabel.getWidth()+2*HGAP)
			maxWidth = nameLabel.getWidth()+2*HGAP;
		setExtent(maxWidth+PConstants.SMALL_BORDER,
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
