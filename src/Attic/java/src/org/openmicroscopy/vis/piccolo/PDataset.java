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
	private PChainLabels chainLabels;
	private double LABEL_SCALE=.6;
	
	private double area = 0;

	private double prevWidth;
	private double width;
	private double height = 0;
	private PDatasetImagesNode images=null;
	Iterator iter;
	
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

		double totalArea = 0;
		
		
		System.err.println("+++++++++++++++++++++");
		System.err.println("dataset..."+dataset.getName()+" "+dataset.getID());
		
		Collection imageCollection = dataset.getCachedImages(connection);
		if (imageCollection.size() > 0) { 
			// if there are images 
			images = new PDatasetImagesNode();
			addChild(images);
		
			iter  = imageCollection.iterator();
			while (iter.hasNext()) {
				CImage image = (CImage) iter.next();
				thumb  =new PThumbnail(image);
				images.addImage(thumb);
				b = thumb.getGlobalFullBounds();
				System.err.println("addign image.."+b.getWidth()+","+b.getHeight());
				totalArea += b.getWidth()*b.getHeight();
			}
			images.setOffset(x,y);
		}
		
		double effectiveHeight = height -y;
		double effectiveWidth = width;
		
		// account for chain exections..
		
		Collection chains = dataset.getChains(connection);
		if (chains.size() > 0) {
			chainLabels = new PChainLabels(chains);
			addChild(chainLabels);
			
			chainLabels.layout(width);
			b =chainLabels.getGlobalFullBounds();
			effectiveHeight -= b.getHeight()+2*VGAP;
			System.err.println("setting max width to "+b.getWidth()+" in chain labels");	
			maxWidth = b.getWidth();
		}
			
		
		
		
		double scaledArea = effectiveWidth*effectiveHeight;
		
		System.err.println("image area is "+totalArea+", scaledArea is "+scaledArea);
		double scalefactor = Math.sqrt(totalArea/scaledArea);
		System.err.println("scaled factor "+scalefactor);
		double scaledWidth = scalefactor*effectiveWidth;
		double scaledHeight = scalefactor*effectiveHeight;
		System.err.println("width is "+effectiveWidth);
		System.err.println("height is "+effectiveHeight);
		System.err.println("scaled width is "+scaledWidth);
		System.err.println("scaled height is "+scaledHeight);
	
		if (imageCollection.size() > 0) {
			iter  = dataset.getCachedImages(connection).iterator();
	
			x=0;
			y=0;
			iter = images.getImageIterator();
			while (iter.hasNext()) {
				thumb = (PThumbnail) iter.next();
				
				
				//PThumbnail thumb = (PThumbnail) obj;
			
				b =  thumb.getGlobalFullBounds();
		
		//		System.err.println("dataset scaled height is "+scaledHeight);
		//		System.err.println("dataset scaled width is "+scaledWidth);
		//		System.err.println("thumb width is "+b.getWidth()+", height "+b.getHeight());
			//	System.err.println("starting x is "+x+", starting y is "+y);
				double thumbWidth = b.getWidth();
				if (x+thumbWidth  < scaledWidth) {
					thumb.setOffset(x,y);
					//System.err.println("same row. offset is "+x+","+y);
				}
				else {
					y += maxHeight+VGAP;
					x = 0;
					thumb.setOffset(x,y);
						
					//	System.err.println("new row. offset is "+x+","+y);
					maxHeight = 0;
				}
				lastThumb=thumb;
				if (b.getHeight() > maxHeight) 
					maxHeight = (float)b.getHeight();
			 	x+= thumbWidth;
			 	//System.err.println("new x is "+x+", new maxHeight is "+maxHeight);
			 	if (x > maxWidth) 
			 		maxWidth =  x;
			 	x+= HGAP;
			}	
			images.completeImages(scaledWidth,scaledHeight);
			y+= maxHeight;
		}
	
		
		//System.err.println("calculated max widith of dataset.."+maxWidth);
		//System.err.println("original width was "+width);
		System.err.println("final height of dataset..."+y);
		if (y > scaledHeight) 
			scaledHeight = y;
		
			
		// calculate effective scale factor.
		double scaleEffective = scaledHeight/effectiveHeight;
		System.err.println("effective scale is "+scaleEffective);
		//double scaleRatio = 1/(scaleEffective*scaleEffective);
		
		if (scaleEffective == 0 || imageCollection.size() == 0)
			scaleEffective = 1; 
		double scaleRatio = 1/scaleEffective;
		System.err.println("scale ratio is "+scaleRatio);
		maxWidth /= scaleEffective;
		
		System.err.println("max width scales to "+maxWidth);
		if (maxWidth < width)
			nameLabel.resetWidth(maxWidth);		
		
		if (images != null)
			images.setScale(scaleRatio);
		if (chains.size() > 0)  {
			if (imageCollection.size() > 0) { 
				b= images.getGlobalFullBounds();
				y = b.getY()+b.getHeight()+VGAP;
			}
			else {
				y = VGAP+nameLabel.getBounds().getHeight()+VGAP;
			}
			chainLabels.setOffset(HGAP,y);
		}
		System.err.println("height is "+height+", max width is "+maxWidth);
		setExtent(maxWidth+PConstants.SMALL_BORDER,
				height+PConstants.SMALL_BORDER);
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
	
	public void scaleArea(double scale) {
		width *=scale;
		height *=scale;
	}
}
