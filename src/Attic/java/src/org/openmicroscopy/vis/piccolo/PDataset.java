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

import edu.umd.cs.piccolo.util.PBounds;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CImage;
import org.openmicroscopy.vis.ome.Connection;
import org.openmicroscopy.vis.chains.SelectionState;

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
	
	/**
	 * The dataset and connection of interest
	 */
	private CDataset dataset;
	private Connection connection;
	
	
	/** 
	 * Positional coordinates
	 */
	private double x=PConstants.DATASET_IMAGE_GAP;
	private double y=PConstants.DATASET_IMAGE_GAP;
	
	/** 
	 * Name and chains for the datasets
	 */
	private PScalableDatasetLabel nameLabel;
	private PChainLabels chainLabels;
	

	/**
	 * Width and height values,
	 *  with prevWidth so we can revert - needed to create treemap layout.
	 * see {@link PBrowserCanvas}
	 */
	private double prevWidth;
	private double width;
	private double height = 0;
	
	/**
	 * The node that holds the thumbnails
	 */
	private PDatasetImagesNode images=null;
	
	/**
	 * The max width of any row
	 */
	double maxWidth = 0;
	
	/** 
	 * Max width of any thumbnail. Used to guarantee aligned columns
	 */
	private double maxThumbWidth = 0;
	
	public PDataset(CDataset dataset,Connection connection) {
		super();
		this.dataset = dataset;
		this.connection = connection;
		dataset.setNode(this);
	}

	/** 
	 * The main procedure for laying out the images thumbnails
	 *
	 */
	public void layoutImages() {
		
		removeAllChildren();
		// initial starting point
		double x=PConstants.DATASET_IMAGE_GAP;
		double y= PConstants.DATASET_IMAGE_GAP;
		
		// add the name label and move down.
		nameLabel = new PScalableDatasetLabel(dataset,width);
		addChild(nameLabel);
		nameLabel.setOffset(x,y);
		y+= nameLabel.getBounds().getHeight()+PConstants.DATASET_IMAGE_GAP;
		
		// find the total area
		Collection imageCollection = dataset.getCachedImages(connection);
		double totalArea = buildImages(imageCollection,x,y);
	
		// calculate remaining height
		double effectiveHeight = height -y;
		double effectiveWidth = width;
		
		// account for chain exections..	
		Collection chains = dataset.getChains(connection);
		if (chains.size() > 0) {
			double h = buildChainLabels(chains);
			effectiveHeight -= h+2*PConstants.DATASET_IMAGE_GAP;
		}
			
		// find the scaled area
		double scaledArea = effectiveWidth*effectiveHeight;
		double scalefactor = Math.sqrt(totalArea/scaledArea);
		
		// this is the scaled width and height that we must fit into
		double scaledWidth = scalefactor*effectiveWidth;
		double scaledHeight = scalefactor*effectiveHeight;
		
		// layout the images in this space
		if (imageCollection.size() > 0) {
			y = arrangeImages(scaledWidth,scaledHeight);
		}
	
		// update height
		if (y > scaledHeight) 
			scaledHeight = y;
		
		// calculate effective scale factor - compare available height
		// to what was used, and this gives us the effective scale factor.
		double scaleEffective = scaledHeight/effectiveHeight;
		
		// turn that scale into a scale ratio
		if (scaleEffective == 0 || imageCollection.size() == 0)
			scaleEffective = 1; 
		double scaleRatio = 1/scaleEffective;
		
		// adjust the max width
		maxWidth /=scaleEffective;
	
		
		// scale the node holding the thumbnail to by  that ratio
		if (images != null)
			images.setScale(scaleRatio);
			
		// if I have any chain executions, position the label
		if (chains.size() > 0)  {
			if (imageCollection.size() > 0) { 
				PBounds b= images.getGlobalFullBounds();
				y = b.getY()+b.getHeight()+PConstants.DATASET_IMAGE_GAP;
			}
			else {
				y = PConstants.DATASET_IMAGE_GAP+nameLabel.getBounds().getHeight()+PConstants.DATASET_IMAGE_GAP;
			}
			chainLabels.setOffset(PConstants.DATASET_IMAGE_GAP,y);
			// update the width if need be.
			if (maxWidth < chainLabels.getGlobalFullBounds().getWidth())
				maxWidth = chainLabels.getGlobalFullBounds().getWidth();
		}
		
		// if necessary, adjust width to hold the dataset's name label
		if (imageCollection.size() == 0 && 
			maxWidth < nameLabel.getBounds().getWidth())
			maxWidth = nameLabel.getBounds().getWidth();
			
		// adjust the name label to fit.
		nameLabel.resetWidth(maxWidth);
				
		setExtent(maxWidth+PConstants.SMALL_BORDER,
				height+PConstants.SMALL_BORDER);
	}
	
	/**
	 * To build the images, iterate over the colection, build thumbnails for 
	 * each, and add them to the {@link PDatasetImagesNode}, calculating the 
	 * total area along the way
	 * 
	 * @param imageCollection images to be laid out
	 * @param x horiz coord of thumbnail node
	 * @param y vert coord of thumbnail node
 	 * @return area occupied
	 */
	private double buildImages(Collection imageCollection,double x,double y) {
		double totalArea = 0;
		Iterator iter;
		PThumbnail thumb;
		PBounds b;
		int rowCount = 0;
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
				totalArea += b.getWidth()*b.getHeight();
				// track the width of the widest thumbnail
				if (b.getWidth() > maxThumbWidth)
					maxThumbWidth = b.getWidth();
			}
			images.setOffset(x,y);
		}
		return totalArea;
	}
	
	/**
	 * Create chain labels, adjusting max widths and returning the heigh of 
	 * the label
	 * @param chains set of chains that have executions for this dataset.
	 * @return height of the label
	 */
	private double buildChainLabels(Collection chains) {
		chainLabels = new PChainLabels(chains);
		addChild(chainLabels);
			
		chainLabels.layout(width);
		PBounds b =chainLabels.getGlobalFullBounds();
		maxWidth = b.getWidth();
		return b.getHeight();
	}
	
	/**
	 * Place the images in rows according to the provided constraints
	 * 
	 * @param scaledWidth
	 * @param scaledHeight
	 * @return
	 */
	private double arrangeImages(double scaledWidth,double scaledHeight) {
		double x=0;
		double y=0;
		double maxHeight = 0;
		PThumbnail thumb;
		PBounds b;
		int row = 0;
		int rowSz = 0;
		Iterator iter = images.getImageIterator();
		while (iter.hasNext()) {
			thumb = (PThumbnail) iter.next();
			b =  thumb.getGlobalFullBounds();
			double thumbWidth = b.getWidth();
			if (x+thumbWidth  < scaledWidth) {
				// place thumb on current row
				thumb.setOffset(x,y);
			}
			else {
				// move to next row
				y += maxHeight+PConstants.DATASET_IMAGE_GAP;
				x = 0;
				if (rowSz > 0) {
					// finalize row statistics
					images.setRowCount(row,rowSz);
					row++;
					rowSz=0;
				}
				maxHeight = 0;
			}
			// update row size, place image, and update stats.
			rowSz++;
			thumb.setOffset(x,y);
			if (b.getHeight() > maxHeight) 
				maxHeight = (float)b.getHeight();
			x+= maxThumbWidth;
			if (x > maxWidth) 
				maxWidth =  x;
			x+= PConstants.DATASET_IMAGE_GAP;
		}	
		// finalize last row and then complete the image node.
		images.setRowCount(row,rowSz);
		images.completeImages();
		y+= maxHeight;
		return y;
	}

	/**
	 * The "area" of the dataset is pseudo-logarithmic. For datasets with <=20
	 * items, the area is simply the number of items in the dataset. For larger
	 * datasets, the area is the log(datset_size-20).
	 * 
	 * The use of the log lets us handle a wide range of dataset sizes without
	 * too much trouble.
	 * 
	 * @return
	 */
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
	
	/**
	 * The buffered bounds, for zooming in
	 */
	public PBounds getBufferedBounds() {
		PBounds b = getFullBoundsReference();
		return new PBounds(b.getX()-PConstants.SMALL_BORDER,
			b.getY()-PConstants.SMALL_BORDER,
			b.getWidth()+2*PConstants.SMALL_BORDER,
			b.getHeight()+2*PConstants.SMALL_BORDER);
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
	
	/**
	 * Revert back to a previously calculated width
	 *
	 */
	public void revertWidth() {
		width = prevWidth;
	}
	
	/**
	 * Set current and previous width to zero
	 *
	 */
	public void clearWidths() {
		width = prevWidth = 0;
	}
	
	public void setHeight(double height) {
		this.height = height;
	}
	
	/**
	 * scale the height and width. Used to finalize treemap layout. 
	 * see {@link PBrowserCanvas}
	 */
	public void scaleArea(double scale) {
		width *=scale;
		height *=scale;
	}
	
	/**
	 * Set the selected state
	 * @param v true if selected, else false
	 */
	public void setSelected(boolean v) {
		setHighlighted(v);
		if (images !=null) 
			images.setSelected(v);
	}
		
	public void rollover() {
		SelectionState.getState().setRolloverDataset(dataset);
	}
	
	public void setHandler(PBrowserEventHandler handler) {
		if (images != null)
			images.setHandler(handler);
	}
}
