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
 * A {@link PLayer} specifically designed to hold PLink objects - both PParamLinks and 
 * PModuleLinks. This layer also handles the transition between showing only
 * PModuleLinks and showing the underlying PParamLinks
 * 
 * @author Harry Hochheiser
 * @version 0.1
 * @since OME2.0
 */ 


public class PLinkLayer extends PLayer {
	
	/**
	 * A node to hold all PParamLinks.
	 */ 
	private PNode params;
	
	/**
	 * A node to hold all modules;
	 */ 
	private PNode modules;
	
	public PLinkLayer() {
		super();
		params = new PNode();
		addChild(params);
		modules = new PNode();
		addChild(modules);
	}
	
	
	/**
	 * When a {@link PParamLink} is added to this layer, give the 
	 * link a pointer back to this layer.
	 * 
	 * @param link
	 */
	// addChild() is called when the link starts.
	public void addChild(PParamLink link) {
		params.addChild(link);
		link.setLinkLayer(this);
	}
	
	/**
	 * 
	 * @return An iterator for the {@link PParamLink} objects held in this 
	 * layer.
	 * 
	 */
	public Iterator linkIterator() {
		return params.getChildrenIterator();
	}
	
	/**
	 * When a link between two parameters is completed, we need to make sure 
	 * that thare is also a direct link between the two modules involved. 
	 * If there is no such link, create a new {@link PModuleLink} for the 
	 * two modules and add it to the modules layer.
	 * 
	 * @param link a newly-completed {@link PParamLink}
	 * @return The link between the two modules involved in link
	 */
	public PModuleLink completeLink(PParamLink link) {
		PFormalOutput output = link.getOutput();
		PFormalInput input = link.getInput();
		PModule start = output.getPModule();
		PModule end = input.getPModule();
	
		// only add a link if we don't have one already
	
		PModuleLink lnk = findModuleLink(start,end);
		if (lnk == null) {// if there is no link
			lnk = new PModuleLink(this,link,start,end);
			modules.addChild(lnk);
		}
		return lnk;
	}
	
	/**
	 * Semantic zooming - if magnification is below a certain threshold, 
	 * make the module links visible and the paramter links invisible. 
	 * Otherwise, take the opposite approach.
	 */
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
	
	
	/**
	 * When a link between parameters is removed, we might need to
	 * remove the link between the associated modules. However, we do this
	 * only if we don't already have another existing link between the two
	 * modules - in that case, we need to keep the link between the modules.
	 * @param link
	 */
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
	
	/**
	 * Do the job of removing the link between modules.
	 * @param start
	 * @param end
	 */
	private void removeModuleLink(PModule start,PModule end) {
		
		PModuleLink lnk = findModuleLink(start,end);
		if (lnk != null)
			modules.removeChild(lnk);
	}
	
	/**
	 * 
	 * @param start The module at the start of a link
	 * @param end   The module at the end of a link
	 * @return the {@link PModuleLink linking thhe two modules
	 */
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
	
	/**
	 * When a direct link between modules is removed, remove 
	 * all {@link PParamLink} instances between those two modules.
	 * @param link
	 */
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
				// associated modules, which would call this proocedure.
				// It's not clear whether or not these calls are sufficiently
				// re-entrant to handle the recursion, so this approac
				// is a bit safer.
				if (s == start && e == end) {
					toRemove.add(lnk);
					lnk.clearLinks();
				}
			}
		}
		params.removeChildren(toRemove);
	}
}