/*
 * org.openmicroscopy.vis.piccolo.PLinkLayer;
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
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.util.PPaintContext;
import java.util.Iterator;
import java.util.Vector;

/** 
 * A Layer specifically designed to hold PLink objects - both PParamLinks and 
 * PModuleLinks. This layer also handles the transition between showing only
 * PModuleLinks and showing the underlying PParamLinks
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */ 


public class PLinkLayer extends PLayer {
	
	// a node to hold all PParamLinks.
	private PNode params;
	// a node to hold all modules;
	private PNode modules;
	
	public PLinkLayer() {
		super();
		params = new PNode();
		addChild(params);
		modules = new PNode();
		addChild(modules);
	}
	
	// addChild() is called when the link starts.
	public void addChild(PParamLink link) {
		params.addChild(link);
		link.setLinkLayer(this);
	}
	
	// completeLink is used to set up the link between modules.
	public void completeLink(PParamLink link) {
		PFormalOutput output = link.getOutput();
		PFormalInput input = link.getInput();
		PModule start = output.getPModule();
		PModule end = input.getPModule();
	
		// only add a link if we don't have one already
	
		PModuleLink lnk = findModuleLink(start,end);
		if (lnk == null) {// if there is no link
			lnk = new PModuleLink(this,start,end);
			modules.addChild(lnk);
		}
	}
	
	protected void paint(PPaintContext aPaintContext) {
		double scale = aPaintContext.getScale();
		if (scale < PConstants.SCALE_THRESHOLD) {
			params.setVisible(false);
			modules.setVisible(true);
		}
		else {
			params.setVisible(true);
			modules.setVisible(false);
		}
	}
	
	
	
	public void removeModuleLinks(PParamLink link) {
		PModule start = link.getOutput().getPModule();
		PModule end = link.getInput().getPModule();
		
		PParamLink lnk;
		PModule s;
		PModule e;
		
		Iterator iter = params.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PParamLink) {
				lnk = (PParamLink) obj;
				s = lnk.getOutput().getPModule();
				e = lnk.getInput().getPModule();
				// if same thing, we're done. don't clobber.
				if (s == start && e == end)
					return;
			}
			else
				System.err.println("*** removeModuleLinks(). Shouldn't get here");
		}
		// nothing equal, we need to remove it.
		removeModuleLink(start,end);
	}
	
	
	private void removeModuleLink(PModule start,PModule end) {
		
		PModuleLink lnk = findModuleLink(start,end);
		if (lnk != null)
			modules.removeChild(lnk);
	}
	
	private PModuleLink findModuleLink(PModule start,PModule end) {
		PModuleLink lnk = null;
		
		Iterator iter = modules.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PModuleLink) {
				lnk = (PModuleLink) obj;
				PModule s = lnk.getStart();
				PModule e = lnk.getEnd();
				if (start == s && end == e) 
					return lnk;
			}
		}
		return null;
	}
	
	public void removeParamLinks(PModuleLink link) {
		PModule start = link.getStart();
		PModule end= link.getEnd();
		
		Vector toRemove = new Vector();
		Iterator iter=params.getChildrenIterator();
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof PParamLink) {
				PParamLink lnk = (PParamLink) obj;
				PModule s = lnk.getOutput().getPModule();
				PModule e = lnk.getInput().getPModule();
				// if it's a link betweenn our two places, kill it.
				// but we don't call lnk.remove(), as this would do bad 
				// recursive things, as it would try to remove the
				// associated modules.. 
				// actually, the recursive call might work, but
				// inefficiently. this will be quicker
				if (s == start && e == end) {
					toRemove.add(lnk);
					lnk.clearLinks();
				}
			}
		}
		params.removeChildren(toRemove);
	}
				
}