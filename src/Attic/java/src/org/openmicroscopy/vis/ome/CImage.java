/*
 * org.openmicroscopy.vis.chains.ome.CImage
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
 
package org.openmicroscopy.vis.ome;
import org.openmicroscopy.remote.RemoteException;
import org.openmicroscopy.remote.RemoteImage;
import org.openmicroscopy.remote.RemoteSession;
import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.vis.piccolo.PThumbnail;
import java.awt.image.BufferedImage;
import java.util.Vector;
import java.util.Iterator;
//import java.util.List;

 
/** 
 * <p>A {@link Dataset} subclass used to hold information about images 
 * in the chain builder. Notably, includes code to load and manage a thumbnail
 * image<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CImage extends RemoteImage {
	
	
	static {
		RemoteObjectCache.addClass("OME::Image",CImage.class);
	}
	
	private BufferedImage imageData;
	private Vector thumbnails = new Vector();
	
	private boolean loading = false;
	public CImage() {
		super();
	}
	
	public CImage(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	
	public void loadImageData(Connection connection) {
		if (imageData == null && loading  == false) {
			connection.getThumbnail(this);
			loading = true;
		}
	}
	
	public synchronized void setImageData(BufferedImage i) {
		//System.err.println("getting image data for image "+getID());
		imageData = i;
		notifyAll();		
	}
	
	public void addThumbnail(PThumbnail thumb) {
		
		thumbnails.add(thumb);
	}
	
	public synchronized BufferedImage getImageData() {
		/*System.err.println("getting image data from CImage"+getID());
		if (imageData == null) {
			System.err.println("it's null..");
		}*/
		while (imageData == null) {
			try {
				wait();
			}
			catch(InterruptedException e) {
				System.err.println("interrupted exception...");
			}
		}
		return imageData;
	}
	
	// to prevent re-entrant loops
	private boolean reentrant=false;
	
	public void highlightThumbnails(boolean v) {
		
		if (reentrant == true)
			return;
		// so each of the setHighlighted() calls don't lead to a call back here
		reentrant = true;
		Iterator iter = thumbnails.iterator();
		PThumbnail thumb;
		while (iter.hasNext()) {
			thumb = (PThumbnail) iter.next();
			thumb.setHighlighted(v);
		}
		reentrant = false;
	}
	
	public String getName() {
		String s = null;
		try {
			s = super.getName();
		}
		catch(RemoteException e) {
		}
		return s;
	}
	
}
