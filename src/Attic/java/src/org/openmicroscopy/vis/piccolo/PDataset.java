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
 * A subclass of {@link PCategoryBox} that is used to provide a colored 
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
	private PScalableDatasetLabel nameLabel;
	private PText chainLabel;
	private PChainLabels chainLabels;
	private double LABEL_SCALE=.6;
	
	private double area = 0;

	private double prevWidth;
	private double width;
	private double height = 0;
	
	public PDataset(CDataset dataset,Connection connection) {
		super();
		this.dataset = dataset;
		this.connection = connection;
		dataset.setNode(this);
	}

	public void layoutImages() {
		
		removeAllChildren();
		double x=HGAP;
		double y= VGAP;
		PBounds b;
		double maxWidth = 0;
		double maxHeight = 0;
		PThumbnail thumb = null;
		PThumbnail lastThumb=null;
	
		nameLabel = new PScalableDatasetLabel(dataset,width);
		//nameLabel.setPickable(false);
		addChild(nameLabel);
		nameLabel.setOffset(x,y);
		nameLabel.setConstrainWidthToTextWidth(false);
		
		y+= nameLabel.getBounds().getHeight()+VGAP;
		
		
		// tweak width to make label fit.
		//iter = getChildrenIterator();
		Iterator iter  = dataset.getCachedImages(connection).iterator();
	
		System.err.println("layting out "+dataset.getName() +"...");
		System.err.println("# of images is "+dataset.getImageCount());
		System.err.println("height is "+height+", width is "+width);
		
		
		while (iter.hasNext() && y < height) {
			CImage image = (CImage) iter.next();
			thumb = new PThumbnail(image);
			
			addChild(thumb);
			
			
			//PThumbnail thumb = (PThumbnail) obj;
		
			b =  thumb.getGlobalFullBounds();
	
			System.err.println("dataset height is "+height);
			System.err.println("dataset width is "+width);
			System.err.println("thumb width is "+b.getWidth()+", height "+b.getHeight());
			System.err.println("starting x is "+x+", starting y is "+y);
			double thumbWidth = b.getWidth();
			if (x+thumbWidth  < width && y+b.getHeight() < height) {
				thumb.setOffset(x,y);
				System.err.println("same row. offset is "+x+","+y);
			}
			else {
				if (y+ maxHeight+b.getHeight() +VGAP< height) {
					y += maxHeight+VGAP;
					x = HGAP;
					thumb.setOffset(x,y);
					
					System.err.println("new row. offset is "+x+","+y);
					maxHeight = 0;
				}
				else {
					System.err.println("wouldn't fit. removing");
					removeChild(thumb);
					//removeChild(lastThumb);
					break;
				}
			}
			lastThumb=thumb;
			if (thumb.getGlobalFullBounds().getHeight() > maxHeight) 
				maxHeight = (float)thumb.getGlobalFullBounds().getHeight();
		 	x+= thumbWidth;
		 	System.err.println("new x is "+x+", new maxHeight is "+maxHeight);
		 	if (x > maxWidth) 
		 		maxWidth =  x;
		 	x+= HGAP;
		}	
	
		
	//	y +=maxHeight;// move y ahead. to next row.
		//System.err.println("y after all is "+y);
	//	x=HGAP;
		// adjust width
		// insert chains, if any.
		Collection chains = dataset.getChains(connection);
		//System.err.println("max width after images..."+maxWidth);
		
		double fullWidth=0;
		if (chains.size() > 0) {
		
			chainLabels = new PChainLabels(chains);
			addChild(chainLabels);
			
			chainLabels.layout(width);
			b =chainLabels.getGlobalFullBounds();
		
			System.err.println("adding chain labels. x is "+x+", width is "+b.getWidth());
			System.err.println("box width is "+width);
			if (x + b.getWidth() >= width) {
				System.err.println("moving to next line");
				y+=maxHeight;
				x=HGAP;
				maxHeight = 0;
			}
			chainLabels.setOffset(x,y);
			if (b.getHeight() > maxHeight)
				y+= b.getHeight();
			else
				y += maxHeight;
			
			fullWidth =  x+b.getWidth();
			//System.err.println("full width with execs"+fullWidth);
			if (fullWidth > maxWidth)
				maxWidth = fullWidth;
		}
		else // no chain executions, but must move to next row.
			y += maxHeight;
		//System.err.println("calculated max widith of dataset.."+maxWidth);
		//System.err.println("original width was "+width);
		if (y < height) 
			height = y;
		if (maxWidth < width)
			nameLabel.resetWidth(maxWidth);		
		setExtent(maxWidth+PConstants.SMALL_BORDER,
			height+PConstants.SMALL_BORDER); // was maxWidth
	}
	
	public double getContentsArea() {
		int count = dataset.getImageCount();
		double num =1;
		if (count > 20)
			num = 20+ Math.log(dataset.getImageCount()-20);
		else if (count >0)
			num = count;
		else 
			num =1;
			 
		return num; 
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
		System.err.println("width is "+width);
	}
	
	public void clearWidths() {
		width = prevWidth = 0;
	}
	
	public void setHeight(double height) {
		this.height = height;
	}
}
