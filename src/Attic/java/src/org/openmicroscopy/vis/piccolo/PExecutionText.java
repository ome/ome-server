/*
 * org.openmicroscopy.vis.piccolo.PExecutionText
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
import org.openmicroscopy.ChainExecution;



/** 
 * Node to hold Text for a chain execution
 * 
 * 
 * @author Harry Hochheiser
 * @version 2.1
 * @since OME2.1
 */
public class PExecutionText extends PSelectableText {

	private ChainExecution exec;
	
	public PExecutionText(ChainExecution exec,double scale) {
		super();
		this.exec = exec;
		String s  = getString();
		buildString(scale,s);
	}
	
	private String getString() {
		int id = exec.getID();
		String timestamp = exec.getTimestamp();
		String[] pieces = timestamp.split("\\.");

		return new String(Integer.toString(id)+". "+pieces[0]);
		
	}
	

}