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

import edu.umd.cs.piccolo.PCanvas;
import edu.umd.cs.piccolo.PLayer;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.event.PBasicInputEventHandler;
import edu.umd.cs.piccolo.event.PInputEvent;
import org.openmicroscopy.Project;
import javax.swing.Timer;
import java.awt.Dimension;
import java.awt.Rectangle;
import java.awt.Paint;
import java.util.Collection;
import java.util.Iterator;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

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
	private static final double HGAP=5;
	
	private static final double INITIAL_SCALE=.7;
	
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
			Project p = (Project) iter.next();
			ProjectLabel pl = new ProjectLabel(p,this);
            // build node
			layer.addChild(pl);
			//position
			PBounds b = pl.getGlobalFullBounds();
			if (b.getWidth()*ProjectLabel.SELECTED_SCALE > columnWidth) 
				columnWidth = (int) (b.getWidth()*ProjectLabel.SELECTED_SCALE);
			
			if (b.getHeight() > rowHeight) 
				rowHeight = (int) b.getHeight();
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
				System.err.println("x is "+x+", column width is "+columnWidth);
				System.err.println("component width is "+width);
				if (x+columnWidth+HGAP > width) {
					y +=rowHeight+HGAP;
					x =0;
				}
				pl.setOffset(x,y);
			}
			
			x+=columnWidth+HGAP;
		}
		scaleToFit(0);
	}
	
	public void scaleToFit(int delay) {
		PBounds b = layer.getFullBounds();
		System.err.println("bounds are "+b);
		getCamera().animateViewToCenterBounds(b,true,delay);
		getCamera().setViewScale(INITIAL_SCALE);
	}
	
	public void selectionChanged(SelectionEvent e) {
		
	//	if (e.getMask() == SelectionEvent.SET_ROLLOVER_PROJECT &&
	//		  e.getSelectionState().getSelectedProject() == null)
	 	if (e.getSelectionState().getSelectedProject() == null) 
			scaleToFit(PConstants.ANIMATION_DELAY);
	}
	
	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_PROJECT;
	}
			
}


class ProjectLabel extends PText implements SelectionEventListener {
	
	public static final double NORMAL_SCALE=1.0;
	public static final double ACTIVE_SCALE=1.25;	
    public static final double ROLLOVER_SCALE=1.25;
	public static final double SELECTED_SCALE=1.5;
	public Project project;
	
	private double previousScale =NORMAL_SCALE;
	private Paint previousPaint;
	PProjectSelectionCanvas canvas;
	
	ProjectLabel(Project project,PProjectSelectionCanvas canvas) {
		super();
		this.project = project;
		this.canvas = canvas;
		setText(project.getName());
		setFont(PConstants.TOOLTIP_FONT);
		// initially
	//	setScale(SELECTED_SCALE);
		SelectionState.getState().addSelectionEventListener(this);
		
	}
	
	public Project getProject() {
		return project;
	}
	
	public void setNormal() {
		setScale(NORMAL_SCALE);
		setPaint(PConstants.DEFAULT_COLOR);
	}
	
	public void setActive() {
		setScale(ACTIVE_SCALE);
		setPaint(PConstants.PROJECT_ACTIVE_COLOR);
	}
	
	public void setSelected() {
		setScale(SELECTED_SCALE);
		setPaint(PConstants.PROJECT_SELECTED_COLOR);
		// zoom layer.
		PLayer layer = (PLayer) getParent();
		layer.getCamera(0).animateViewToCenterBounds(getGlobalFullBounds(),true,
			PConstants.ANIMATION_DELAY);
	}
	
	public void setRollover(boolean v) {	
		// don't make it smaller if already selected
		setScale(ROLLOVER_SCALE);
		setPaint(PConstants.PROJECT_ROLLOVER_COLOR);
	}
	
	public void selectionChanged(SelectionEvent e) {
		SelectionState state = e.getSelectionState();
		if (project == state.getSelectedProject())
			setSelected();
		else if (project == state.getRolloverProject())
			setRollover(true);
		else if (state.isActiveProject(project))
			setActive();
		else
			setNormal();
	}
	
	public int getEventMask() {
		return SelectionEvent.SET_SELECTED_PROJECT|
			SelectionEvent.SET_ROLLOVER_PROJECT;
	}
}

class ProjectLabelEventHandler extends PBasicInputEventHandler implements 
	ActionListener {
	
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
			ProjectLabel pl = (ProjectLabel) e.getPickedNode();
			SelectionState.getState().setRolloverProject(null);
		}
	}
	
	public void mouseClicked(PInputEvent e) {
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
			ProjectLabel pl = (ProjectLabel) e.getPickedNode();
			SelectionState.getState().setSelectedProject(pl.getProject());
		}
	}
	
    public void doMouseDoubleClicked(PInputEvent e) {
		SelectionState.getState().setSelectedProject(null);
    }
 
}