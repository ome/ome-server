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
import org.openmicroscopy.vis.chains.ControlPanel;
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
import java.util.Vector;
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
	implements SelectionEventListener{
	
	private static final int HEIGHT=50;
	private static final int MAXHEIGHT=150;
	private static final int MAXWIDTH=1000;
	private static final double HGAP=20;  
	private static final double VGAP=10;
	private static final double VSEP=5;
	
	
	private PLayer layer;
	
	
	private ControlPanel panel;
	
	private int lastHeight; // last window height
	
	
	public PProjectSelectionCanvas(ControlPanel panel,Collection projects) {
		super();
		this.panel = panel;
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
		}
	}
		
	public void layoutLabels() {
		////System.err.println("----Start of call to layoutLabels()");
		double x=0;
		double y =VSEP;
		ProjectLabel pl;

		int width = getWidth();
		//System.err.println("width is" +width);
		Rectangle bounds = getBounds();
		Iterator iter = layer.getChildrenIterator();
		Vector rows = new Vector();
		Vector row = new Vector();
		Vector widths = new Vector();
		PBounds b;
		double rowWidth;
		
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				pl = (ProjectLabel) obj;
				double labelWidth = pl.getScaledMaxWidth();
				//System.err.println("adding label...");
				if (x+labelWidth > width) {
					//System.err.println("new row. width is "+x);
					rows.add(row);
					widths.add(new Double(x));
					x =0;
					row = new Vector();
				}
				row.add(pl);
				//System.err.println("row added was "+pl.getProject().getName());
				x += labelWidth;
			}
		}
		rows.add(row);
		widths.add(new Double(x));
		double rowHeight  = 0;
		double spacing = 0;
		Iterator iter2;
		//System.err.println("---- laying things out...");
		for (int i = 0; i < rows.size(); i++) {
			row = (Vector) rows.elementAt(i);
			Double rowW = (Double) widths.elementAt(i);
			rowWidth = 	rowW.doubleValue();
			iter = row.iterator();
			//  calculate space between items.
			// leftover is width - rowWidth
			//System.err.println("row "+i+", width is "+rowWidth);
			double remainder = width-rowWidth;
			//System.err.println("remainder..... "+remainder);
			// divide that by n-1 
			if (row.size() >1)
				spacing = remainder/(row.size()+1);
			else 
				spacing = 0;
			//System.err.println("spacing..."+spacing);
			x = 0;
			rowHeight = 0;
			while (iter.hasNext()) {
				pl = (ProjectLabel) iter.next();
				// place this
				//System.err.println("placing "+pl.getProject().getName()+" at "+x);
				//System.err.println("width of pl is "+pl.getScaledMaxWidth());
				pl.setOffset(x,y);
				b = pl.getGlobalFullBounds();
				x += pl.getScaledMaxWidth()+spacing;
				if (pl.getScaledMaxHeight() > rowHeight) 
					rowHeight= pl.getScaledMaxHeight();
			}
			y+= rowHeight;
		}
		
		int height  = (int) (y+VSEP);
		if (height > lastHeight) {
			Dimension d= new Dimension(width,height);
			setMinimumSize(d);
			setPreferredSize(d);
			panel.setDividerLocation(height);
			lastHeight = height;
		}
	}
	
	
	
	public void selectionChanged(SelectionEvent e) {
		SelectionState state = e.getSelectionState();
	 	if (e.isEventOfType(SelectionEvent.SET_SELECTED_PROJECT)) {
	 			setSelectedProject();
	 	}
		else if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_DATASET)) {
			CDataset rolled = state.getRolloverDataset();

			setRollover(rolled);
		}
		else if (e.isEventOfType(SelectionEvent.SET_ROLLOVER_PROJECT)) {
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
		ProjectLabel pLabel=null;
		SelectionState state = SelectionState.getState();
		
		while (iter.hasNext()) {
			Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				pLabel = (ProjectLabel) obj;
				CProject p = pLabel.getProject();
				if (rolled != null && rolled.hasProject(p)) 
					pLabel.setRollover(true);
				else if (p.sharesDatasetsWith(state.getSelectedProject()))
					pLabel.setActive();
				else  
					pLabel.setNormal();
			}
		}
		layoutLabels();
	}
			
 	public void setRollover(CProject proj) {
		Iterator iter = layer.getChildrenIterator();
		ProjectLabel pLabel;
		SelectionState state = SelectionState.getState();
		
		
		while (iter.hasNext()) {
		Object obj = iter.next();
			if (obj instanceof ProjectLabel) {
				pLabel = (ProjectLabel) obj;
				CProject p = pLabel.getProject();
				if (pLabel.getProject() == proj)
					pLabel.setRollover(true);
				else if (p.sharesDatasetsWith(state.getSelectedProject()) ||
					p.hasDataset(state.getSelectedDataset()))
					pLabel.setActive();
				else
					pLabel.setNormal();

			}
		}
		layoutLabels();
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
				else if (proj.hasDataset(state.getSelectedDataset()))
					pLabel.setActive();
				else if (selected == null)
					pLabel.setNormal();
				else if (selected.sharesDatasetsWith(proj))
					pLabel.setActive();
				else
					pLabel.setNormal();
			}
		}
		layoutLabels();
	} 
}


class ProjectLabel extends PText  {
	
	public static final double NORMAL_SCALE=1;	
    public static final double ROLLOVER_SCALE=1.25;
	public static final double SELECTED_SCALE=1.5;
	public CProject project;
	
	private double previousScale =NORMAL_SCALE;
	private Paint previousPaint;
	PProjectSelectionCanvas canvas;
	
	
	
	ProjectLabel(CProject project,PProjectSelectionCanvas canvas) {
		super();
		this.project = project;
		this.canvas = canvas;
		setText(project.getName());
		setFont(PConstants.PROJECT_LABEL_FONT);
		
	}
	
	public double getScaledMaxWidth() {
		PBounds b = getGlobalFullBounds();
		return b.getWidth()*SELECTED_SCALE/getScale();
	}

	public double getScaledMaxHeight() {
		PBounds b = getGlobalFullBounds();
		return b.getHeight()*SELECTED_SCALE/getScale();
	}
	
	
	public CProject getProject() {
		return project;
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
		setScale(NORMAL_SCALE);
		setPaint(PConstants.PROJECT_ACTIVE_COLOR);
	}
	
	public void setSelected() {
		setScale(SELECTED_SCALE);
		setPaint(PConstants.PROJECT_SELECTED_COLOR);
		
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
			CProject p = pl.getProject();
			if (p.hasDatasets())
				SelectionState.getState().setRolloverProject(p);
		}
	}
	
	public void mouseExited(PInputEvent e) {
		if (e.getPickedNode() instanceof ProjectLabel) {
			ProjectLabel p = (ProjectLabel) e.getPickedNode();
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
			CProject project = pl.getProject();
			//System.err.println("clicking on ..."+pl.getProject().getName());
			SelectionState state = SelectionState.getState();
			
			CProject selected = state.getSelectedProject();
			if (selected == project) { 
				// if i've just clicked on what was selected,
				// clear dataset selection
				state.setSelectedDataset(null);
				
			}
			else if (pl.getProject().hasDatasets())
				state.setSelectedProject(project);
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