/*
 * org.openmicroscopy.vis.chains.ome.CDataset
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
import org.openmicroscopy.vis.piccolo.PDataset;
import org.openmicroscopy.remote.RemoteDataset;
import org.openmicroscopy.remote.RemoteSession;
import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.vis.ome.CProject;
import java.util.Collection;
import java.util.Iterator;
import java.util.Vector;
import java.lang.Comparable;
import java.util.HashSet;


 
/** 
 * <p>A {@link Dataset} subclass used to hold information about datasets 
 * in the chain builder.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CDataset extends RemoteDataset implements Comparable{
	
	Vector images = new Vector();
	int imageCount =-1;
	
	private PDataset node;
	private HashSet projectHash;
	static {
		RemoteObjectCache.addClass("OME::Dataset",CDataset.class);
	}
	
	public CDataset() {
		super();
	}
	
	public CDataset(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	
	
	public  synchronized void loadImages(Connection connection) {
		//System.err.println("Dataset "+getID()+", loading images");
		if (images.size() > 0)  {
			//System.err.println("images already loaded...");
			return;
		}
		Collection i = getImages();
		Iterator iter = i.iterator();
		while (iter.hasNext()) {
			CImage image = (CImage) iter.next();
		//	System.err.println("loading image "+image.getID());
			image.loadImageData(connection);
			images.add(image);		
		}
		
		// load hash set of projects here also
		Collection projects = getProjects();
		projectHash = new HashSet(projects);
	}
	
	public synchronized Collection getCachedImages(Connection connection) {
		if (images.size() == 0)
			loadImages(connection);
		return images;
	}
	
	public Collection getChains(Connection connection) {
		return connection.getChains(this);
	}

	
	public int compareTo(Object o) {
		if (o instanceof CDataset) {
			CDataset d2 = (CDataset) o;
			return getID()-d2.getID();
		}
		else
			return -1;
	}

	public int getImageCount() {
		if (imageCount == -1) // hasn't been calculated
			imageCount = getImages().size();
		return imageCount;
	}	
	
	public String getLabel() {
		return new String(getID()+". "+getName());
	}
	
	
	public boolean hasProject(CProject p) {
		return projectHash.contains(p);
	}
	
	/**
	 * @return
	 */
	public PDataset getNode() {
		return node;
	}

	/**
	 * @param dataset
	 */
	public void setNode(PDataset dataset) {
		node = dataset;
	}
	
	

}
