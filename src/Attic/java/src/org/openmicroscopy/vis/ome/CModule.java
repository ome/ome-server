/*
 * org.openmicroscopy.vis.chains.ome.CModule
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
 
import org.openmicroscopy.remote.RemoteModule;
import org.openmicroscopy.remote.RemoteSession;
import org.openmicroscopy.remote.RemoteObjectCache;
import org.openmicroscopy.vis.chains.ModulePaletteFrame;
import org.openmicroscopy.vis.piccolo.PModule;
import java.util.ArrayList;
import java.io.Serializable;

/** 
 * <p>A {@link RemoteModule} subclass used to hold information about modules 
 * in the chain builder.<p>
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class CModule extends RemoteModule implements Serializable{
	
	static {
		RemoteObjectCache.addClass("OME::Module",CModule.class);
	}
	
	/**
	 * A CModule keeps a list of all of the {@link PModules} that instantiate 
	 * it. ?This list is needed for coordinated highlighting on mouse events:
	 * when one {@link PModule} for a {@link CModule} is selected, this list
	 * is used to make sure that all are highlighted.
	 *  
	 */
	private ArrayList pModules = new ArrayList();
	
	/**
	 * The palette frame in the current application
	 *
	 */
	private ModulePaletteFrame palette;
	
	public CModule() {
		super();
	}
	
	public CModule(RemoteSession session,String reference) {
		super(session,reference);
	}
	
	/**
	 * Add a widget to the list
	 * @param pMod the widget to be added
	 */
	public void addModuleWidget(PModule pMod) {
		pModules.add(pMod);
	}
	
	/**
	 * 
	 * @return the list of {@link PModule} widgets
	 */
	public ArrayList getModuleWidgets() {
		return pModules;
	}
	
	/**
	 * Remove a widget from the list
	 * 
	 * @param mod the widget to be removed
	 */
	public void removeModuleWidget(PModule mod) {
		pModules.remove(mod);
	}
	
	/**
	 * Set modules to be highlighted. Note that this might be better and 
	 * more generally handled by a selecion listener model.
	 * 
	 * @param v true if highlighted, else false
	 */
	public void setModulesHighlighted(boolean v) {
		PModule m;
		ArrayList widgets = getModuleWidgets();
		
		
		for  (int i = 0; i < widgets.size(); i++) {
			m = (PModule) widgets.get(i);
			m.setHighlighted(v);
			m.setParamsHighlighted(v);
		}
		if (palette != null) {
			if (v == true)
				palette.setTreeSelection(this);
			else
				palette.clearTreeSelection();
		}
	}
	
	public void setFrame(ModulePaletteFrame palette) {
		this.palette = palette;
	}
}