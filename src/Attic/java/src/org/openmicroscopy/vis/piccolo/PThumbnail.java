/*
 * org.openmicroscopy.vis.piccolo.PThumbnail
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
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PImage;
import edu.umd.cs.piccolo.nodes.PText;
import org.openmicroscopy.vis.ome.CImage;
import java.awt.Image;
import java.awt.Font;

/** 
 * A node for displaying a thumbnail of an OME IMAGe
 *
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */

public class PThumbnail extends PNode implements PBufferedNode {

	private final static String DEFAULT_LABEL="Thumbnail Unavailable";
	private final static Font LABEL_FONT = new Font("HELVETICA",Font.BOLD,18);
	private CImage image;	
	private PImage imageNode=null;
	private Image imageData;
	private PText label=null;
	
	
	public PThumbnail(CImage image) {
		super();
		this.image=image;
		imageData = image.getImageData();
		if (imageData != null) {
			imageNode = new PBufferedImage(image.getImageData());
			addChild(imageNode);
		}
		else {
			label = new PText(DEFAULT_LABEL);
			label.setFont(LABEL_FONT);
			addChild(label);
			image.setThumbnail(this);
		}
	}
	/**
	 * @return
	 */
	public CImage getImageData() {
		return image;
	}
	
	public PBounds getBufferedBounds() {
			PBounds b = getGlobalFullBounds();
			return new PBounds(b.getX()-PConstants.BORDER,
				b.getY()-PConstants.BORDER,
				b.getWidth()+2*PConstants.BORDER,
				b.getHeight()+2*PConstants.BORDER);
	}
	
	// note that this only gets called when the imageData was initially null,
	// so we know that we don't have to check if label is null, etc.
	public void notifyImageComplete() {
		removeChild(label);
		imageData = image.getImageData();
		imageNode = new PBufferedImage(image.getImageData());
		addChild(imageNode);
	}
}
