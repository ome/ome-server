/*
 * org.openmicroscopy.vis.piccolo.PParamLink
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

import org.openmicroscopy.vis.chains.SelectionState;
import org.openmicroscopy.vis.chains.events.SelectionEvent;
import org.openmicroscopy.vis.chains.events.SelectionEventListener;
import org.openmicroscopy.vis.ome.CDataset;
import org.openmicroscopy.vis.ome.CProject;
import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;

import javax.swing.Timer;
import java.awt.Dimension;
import java.awt.Rectangle;
import java.awt.Paint;
import java.util.Collection;
import java.util.Iterator;
import java.util.HashSet;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.awt.event.MouseEvent;


/** 
 * A Piccolo canvas for selecting projects.
 *
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PProjectSelectionCanvas extends PCanvas 
	implements PBufferedObject, SelectionEventListener{
	
	private static final int HEIGHT=50;
	private static final int MAXHEIGHT=150;
	private static final int MAXWIDTH=1000;
	private static final double HGAP=3;
	
	
	private PLayer layer;
	
	private int columnWidth =0;
	private int rowHeight = 0;
	
	public PProjectSelectionCanvas(Collection projects) {
		super();
		layer = getLayer();
		setMinimumSize(new Dimension(0,HEIGHT));
		setPreferredSize(new Dimension(0,HEIGHT));
		setMaximumSize(new Dimension(MAXWIDTH,MAXHEIGHT));
		removeInputEventListener(getPanEventHandler());
		removeInputEventListener(getZoomEventHandler());
		addInputEventListener(new ProjectLabelEventHandler());
		populate(projects);
		SelectionState.getState().addSelectionEventListener(this);
	}

	private void populate(Collection projects) {
		Iterator iter = projects.iterator();
		while (iter.hasNext()) {
			CProject p = (CProject) iter.next();
			ProjectLabel pl = new ProjectLabel(p,this);
            // build node
			layer.addChild(pl);
			//position
			PBounds b = pl.getGlobalFullBounds();		
			if (b.getHeight()* ProjectLabel.SCALE_MULTIPLIER > rowHeight) 
				rowHeight = (int) (b.getHeight() *ProjectLabel.SCALE_MULTIPLIER);
			double myWidth = b.getWidth()*ProjectLabel.SCALE_MULTIPLIER;
			if (myWidth > columnWidth)
				columnWidth = (int)myWidth;
		}
	}
	
	public void layout(int width) {
		Rectangle bounds = getBounds();
		setBounds(new Rectangle((int)bounds.getX(),
				   (int)bounds.getY(),width,(int)bounds.getHeight()));
		Iterator iter = layer.getChildrenIterator();
		double x=0;
		double y =0;
			
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				ProjectLabel pl = (ProjectLabel) obj;
				//System.errprintln("x is "+x+", column width is "+columnWidth);
				//System.errprintln("component width is "+width);
				PBounds b = pl.getGlobalFullBounds();
				double mywidth = pl.getGlobalFullBounds().getWidth()*
					ProjectLabel.SCALE_MULTIPLIER;
				//if (x+columnWidth+HGAP > width) {
				if (x+mywidth+HGAP > width-2*HGAP) {
		
					y +=rowHeight+HGAP;
					x =0;
				}
				pl.setOffset(x,y);
				x += mywidth+HGAP;
				//x += columnWidth+HGAP;
			}	
		}
		//scaleToFit(0);
	}
	
	public PBounds getBufferedBounds() {
		PBounds b = layer.getFullBounds();
		return new PBounds(b.getX()-HGAP,b.getY()-HGAP,
			b.getWidth()+2*HGAP,b.getHeight()+2*HGAP);
	}
	
	private void scaleToFit(int delay) {
		PBounds b = getBufferedBounds();
		getCamera().animateViewToCenterBounds(b,true,delay);
	}
	
	public void selectionChanged(SelectionEvent e) {
		SelectionState state = e.getSelectionState();
		
	 	if ((e.getMask() & SelectionEvent.SET_SELECTED_PROJECT) ==
	 		SelectionEvent.SET_SELECTED_PROJECT) {
	 	//	if (state.getSelectedProject() == null) 
				//scaleToFit(PConstants.ANIMATION_DELAY); 
				setSelectedProject();
	 	}
		else if ((e.getMask() & SelectionEvent.SET_ROLLOVER_DATASET)
				== SelectionEvent.SET_ROLLOVER_DATASET) {
			CDataset rolled = state.getRolloverDataset();
				
		
			Collection projects = null;
			setRollover(rolled);
		}
		else if ((e.getMask() & SelectionEvent.SET_ROLLOVER_PROJECT)
					==  SelectionEvent.SET_ROLLOVER_PROJECT) {
			// set rollover sets things to be active if they are active projects
			setRollover(state.getRolloverProject());
		}
	}
	
	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_PROJECT |
			SelectionEvent.SET_ROLLOVER_PROJECT |
			SelectionEvent.SET_ROLLOVER_DATASET;
	}
	
	public void setRollover(CDataset rolled) {
		Iterator iter = layer.getChildrenIterator();
		ProjectLabel pLabel;
		SelectionState state = SelectionState.getState();
		
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				System.err.println("project selection.");
				if (rolled != null)
					System.err.println(" rolled over dataset .."+rolled.getName());
				pLabel = (ProjectLabel) obj;
				CProject p = pLabel.getProject();
				System.err.println("project is ..."+p.getName());
				System.err.println("is it active? "+state.isActiveProject(p));
				System.err.println("is label active..."+pLabel.isActive());
				if (rolled != null && rolled.hasProject(p)) 
					pLabel.setRollover(true);
				else if (state.isActiveProject(p) || pLabel.isActive())
					pLabel.setActive();
				else if (state.getSelectedProject() == null) 
					pLabel.setNormal();
				else 
					pLabel.setUnselected();
			}
		}
	}
			
 	public void setRollover(CProject proj) {
		Iterator iter = layer.getChildrenIterator();
		ProjectLabel pLabel;
		SelectionState state = SelectionState.getState();
		
		
		while (iter.hasNext()) {
		Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				pLabel = (ProjectLabel) obj;
				if (pLabel.getProject() == proj)
					pLabel.setRollover(true);
				else  if (state.isActiveProject(pLabel.getProject()))
					pLabel.setActive();
				else if (state.getSelectedProject() == null)
					pLabel.setNormal();
				else 
					pLabel.setUnselected();
			}
		}
 	}
 	
	public void setSelectedProject() {
		SelectionState state = SelectionState.getState();
		CProject selected = state.getSelectedProject();
		Iterator iter = layer.getChildrenIterator();
		ProjectLabel pLabel;
		CProject proj;
				
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				pLabel = (ProjectLabel) obj;
				proj = pLabel.getProject();
				if (proj== selected)
					pLabel.setSelected();
				else if (state.isActiveProject(proj))
					pLabel.setActive();
				else if (selected == null)
					pLabel.setNormal();
				else {// if was a selected and i'm not selected
					// then, i want to see if they share any datasets.
					// if they do, set Active. else set unselected
					HashSet selDatasets = selected.getDatasetSet();
					HashSet projDatasets = proj.getDatasetSet();
					selDatasets.retainAll(projDatasets);
					if (selDatasets.size() > 0)
						pLabel.setActive();
					else
						pLabel.setUnselected();
				}
			}
		}
	} 
}


class ProjectLabel extends PText  {
	
	public static final double NORMAL_SCALE=1.0;
	public static final double ACTIVE_SCALE=1.25;	
    public static final double ROLLOVER_SCALE=1.75;
	public static final double SELECTED_SCALE=2.5;
	public static final double SCALE_MULTIPLIER=2;
	public static final double UNSELECTED_SCALE=.75;
	public CProject project;
	
	private double previousScale =NORMAL_SCALE;
	private Paint previousPaint;
	PProjectSelectionCanvas canvas;
	
	private boolean active = false;
	
	ProjectLabel(CProject project,PProjectSelectionCanvas canvas) {
		super();
		this.project = project;
		this.canvas = canvas;
		setText(project.getName());
		setFont(PConstants.THUMBNAIL_LABEL_FONT);
		
	}
	
	public CProject getProject() {
		return project;
	}
	
	public void setUnselected() {
		if (project == SelectionState.getState().getSelectedProject())
			return;
		active = false;
		System.err.println("setting... "+project.getName()+" to be unselected");
		setScale(UNSELECTED_SCALE);
		setPaint(PConstants.DEFAULT_COLOR);	
	}
	
	
	public void setNormal() {
		if (project == SelectionState.getState().getSelectedProject())
			return;
		setScale(NORMAL_SCALE);
		setPaint(PConstants.DEFAULT_COLOR);
	}
	
	public void setActive() {
		if (project == SelectionState.getState().getSelectedProject())
					return;
		active = true;
		setScale(ACTIVE_SCALE);
		setPaint(PConstants.PROJECT_ACTIVE_COLOR);
	}
	
	public void setSelected() {
		System.err.println("setting something to be selected.");
		active = false;
		setScale(SELECTED_SCALE);
		setPaint(PConstants.PROJECT_SELECTED_COLOR);
		// zoom layer.
		//PLayer layer = (PLayer) getParent();
		//layer.getCamera(0).animateViewToCenterBounds(getGlobalFullBounds(),true,
		//	PConstants.ANIMATION_DELAY);
	}
	
	public void setRollover(boolean v) {
		if (project == SelectionState.getState().getSelectedProject())
			return;
		if (v == true) {
			setScale(ROLLOVER_SCALE);
			setPaint(PConstants.PROJECT_ROLLOVER_COLOR);
		}
		else  {
			setNormal();
		}
	}
	
	public boolean isActive() {
		return active;
	}
}

class ProjectLabelEventHandler extends PBasicInputEventHandler implements 
	ActionListener {
	
	private int leftButtonMask = MouseEvent.BUTTON1_MASK;
	private final Timer timer =new Timer(300,this);
	private PInputEvent cachedEvent;
	
	ProjectLabelEventHandler() {
		super();
		
	}
	
	public void mouseEntered(PInputEvent e) {
		if (e.getPickedNode() instanceof ProjectLabel) {
			ProjectLabel pl = (ProjectLabel) e.getPickedNode();
			SelectionState.getState().setRolloverProject(pl.getProject());
		}
	}
	
	public void mouseExited(PInputEvent e) {
		if (e.getPickedNode() instanceof ProjectLabel) {
			SelectionState.getState().setRolloverProject(null);
		}
	}
	
	public void mouseClicked(PInputEvent e) {
		
		if ((e.getModifiers() & leftButtonMask) !=
				leftButtonMask)
			return;
		if (timer.isRunning()) {
			timer.stop();
			doMouseDoubleClicked(e);
		}
		else {
			timer.restart();
			cachedEvent = e;
		}
	}
	
	public void actionPerformed(ActionEvent e) {
		if (cachedEvent != null)
			doMouseClicked(cachedEvent);
		cachedEvent = null;
		timer.stop();
	}
	
	public void doMouseClicked(PInputEvent e) {
		if (e.getPickedNode() instanceof ProjectLabel) {
			//System.errprintln("mouse clicked in project selection. seting project");
			//System.errprintln("event handled is "+e.isHandled());
			ProjectLabel pl = (ProjectLabel) e.getPickedNode();
			System.err.println("clicking on ..."+pl.getProject().getName());
			SelectionState.getState().setSelectedProject(pl.getProject());
		}
	}
	
    public void doMouseDoubleClicked(PInputEvent e) {
    	SelectionState state = SelectionState.getState();
    	if (state.getSelectedProject() != null)
			SelectionState.getState().setSelectedProject(null);
    }
    
	public void mouseReleased(PInputEvent e) {
		//System.errprintln("mouse released call");
		if (e.isPopupTrigger()) {
			e.setHandled(true);
			handlePopup(e);
		}
	}
	
	public void mousePressed(PInputEvent e) {
		//System.errprintln("mouse pressed call");
		mouseReleased(e);
	}
	
	public void handlePopup(PInputEvent e) {
		if (e.getPickedNode() instanceof ProjectLabel) {
			//System.errprintln("trying to handle product in project selection");
			//System.errprintln("event handled is "+e.isHandled());
			ProjectLabel pl = (ProjectLabel) e.getPickedNode();
			CProject picked = pl.getProject();
			CProject selected = SelectionState.getState().getSelectedProject();
			if (picked == selected) 
				SelectionState.getState().setSelectedProject(null);			
		}
	}
 
}