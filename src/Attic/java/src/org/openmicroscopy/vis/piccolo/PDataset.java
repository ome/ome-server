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
	
	private CDataset dataset;
	private Connection connection;
	
	private static float FUDGE=5;

	private double x=PConstants.DATASET_IMAGE_GAP;
	private double y=PConstants.DATASET_IMAGE_GAP;
	private PScalableDatasetLabel nameLabel;
	private PChainLabels chainLabels;
	private double LABEL_SCALE=.6;
	
	private double area = 0;

	private double prevWidth;
	private double width;
	private double height = 0;
	private PDatasetImagesNode images=null;
	Iterator iter;
	double maxWidth = 0;
	private double maxThumbWidth = 0;
	
	public PDataset(CDataset dataset,Connection connection) {
		super();
		this.dataset = dataset;
		this.connection = connection;
		dataset.setNode(this);
	}

	public void layoutImages() {
		
		removeAllChildren();
		double x=PConstants.DATASET_IMAGE_GAP;
		double y= PConstants.DATASET_IMAGE_GAP;
		
		nameLabel = new PScalableDatasetLabel(dataset,width);
		addChild(nameLabel);
		nameLabel.setOffset(x,y);
		y+= nameLabel.getBounds().getHeight()+PConstants.DATASET_IMAGE_GAP;
		
		Collection imageCollection = dataset.getCachedImages(connection);
		double totalArea = buildImages(imageCollection,x,y);
	
		double effectiveHeight = height -y;
		double effectiveWidth = width;
		
		// account for chain exections..	
		Collection chains = dataset.getChains(connection);
		if (chains.size() > 0) {
			double h = buildChainLabels(chains);
			effectiveHeight -= h+2*PConstants.DATASET_IMAGE_GAP;
		}
			
		double scaledArea = effectiveWidth*effectiveHeight;
		double scalefactor = Math.sqrt(totalArea/scaledArea);
		double scaledWidth = scalefactor*effectiveWidth;
		double scaledHeight = scalefactor*effectiveHeight;
			
		if (imageCollection.size() > 0) {
			y = arrangeImages(scaledWidth,scaledHeight);
		}
	
		if (y > scaledHeight) 
			scaledHeight = y;
		
		// calculate effective scale factor.
		double scaleEffective = scaledHeight/effectiveHeight;
		
		if (scaleEffective == 0 || imageCollection.size() == 0)
			scaleEffective = 1; 
		double scaleRatio = 1/scaleEffective;
		maxWidth /=scaleEffective;
	
		
		if (images != null)
			images.setScale(scaleRatio);
		if (chains.size() > 0)  {
			if (imageCollection.size() > 0) { 
				PBounds b= images.getGlobalFullBounds();
				y = b.getY()+b.getHeight()+PConstants.DATASET_IMAGE_GAP;
			}
			else {
				y = PConstants.DATASET_IMAGE_GAP+nameLabel.getBounds().getHeight()+PConstants.DATASET_IMAGE_GAP;
			}
			chainLabels.setOffset(PConstants.DATASET_IMAGE_GAP,y);
			if (maxWidth < chainLabels.getGlobalFullBounds().getWidth())
				maxWidth = chainLabels.getGlobalFullBounds().getWidth();
		}
		if (maxWidth < nameLabel.getBounds().getWidth())
			maxWidth = nameLabel.getBounds().getWidth();
		nameLabel.resetWidth(maxWidth);		
		setExtent(maxWidth+PConstants.SMALL_BORDER,
				height+PConstants.SMALL_BORDER);
	}
	
	private double buildImages(Collection imageCollection,double x,double y) {
		double totalArea = 0;
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
				if (b.getWidth() > maxThumbWidth)
					maxThumbWidth = b.getWidth();
			}
			images.setOffset(x,y);
		}
		return totalArea;
	}
	
	private double buildChainLabels(Collection chains) {
		chainLabels = new PChainLabels(chains);
		addChild(chainLabels);
			
		chainLabels.layout(width);
		PBounds b =chainLabels.getGlobalFullBounds();
		maxWidth = b.getWidth();
		return b.getHeight();
	}
	
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
				thumb.setOffset(x,y);
			}
			else {
				y += maxHeight+PConstants.DATASET_IMAGE_GAP;
				x = 0;
				if (rowSz > 0) {
					images.setRowCount(row,rowSz);
					row++;
					rowSz=0;
				}
				maxHeight = 0;
			}
			rowSz++;
			thumb.setOffset(x,y);
			if (b.getHeight() > maxHeight) 
				maxHeight = (float)b.getHeight();
			x+= maxThumbWidth;
			if (x > maxWidth) 
				maxWidth =  x;
			x+= PConstants.DATASET_IMAGE_GAP;
		}	
		images.setRowCount(row,rowSz);
		images.completeImages(scaledWidth,scaledHeight);
		y+= maxHeight;
		return y;
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
