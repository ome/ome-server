/*
 * org.openmicroscopy.vis.piccolo.PSelectableText
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
package org.openmicroscopy.vis.piccolo;
import edu.umd.cs.piccolo.PNode;
import edu.umd.cs.piccolo.nodes.PText;
import edu.umd.cs.piccolo.nodes.PPath;
import edu.umd.cs.piccolo.util.PBounds;
import edu.umd.cs.piccolo.util.PPickPath;
import org.openmicroscopy.ChainExecution;
import java.awt.Color;



/** 
 * Node to hold that can be moused over and clicked on.
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PSelectableText extends PNode {

	private ChainExecution exec;
	private PPath rect;
	private PText text;
	
	public PSelectableText() {
		super();
	}
	
	protected void buildString(double scale,String s) {
	
		
		text = new PText(s);
		
		text.setFont(PConstants.LABEL_FONT);
		PBounds b = text.getGlobalFullBounds();
		rect = new PPath(b);
		rect.setPaint(PConstants.DEFAULT_FILL);
		
		addChild(text);
		setScale(scale);
	}
	
	public void setHighlighted(boolean v) {
		if (v == false)
			removeChild(rect);
		else {
			addChild(rect);
			rect.moveToBack();
		}
	}
	
	protected void setColor(Color c) {
		text.setPaint(c);
	}
	
	public boolean pick(PPickPath pickPath) {
		if (pickPath.getPickBounds().intersects(rect.getBounds())) 
			return true;
		else 
			return false;
	}
}