/*
 * org.openmicroscopy.browser.layout.GroupView
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.browser.layout;

import java.awt.Color;
import java.awt.Font;
import java.awt.Shape;

import org.openmicroscopy.browser.UIConstants;

/**
 * The visual representation of a group.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version
 * @since
 */
public class GroupView
{ 
  /**
   * The layout method for the group.
   */
  protected LayoutMethod layoutMethod;
  
  /**
   * The shape bounds of the group (0,0 is always the top-left; this is
   * relative; a top-level browser canvas will control the real position of
   * the group)
   */
  protected Shape bounds;
  
  /**
   * The background color of the group.
   */
  protected Color backgroundColor;
  
  /**
   * The font of the group name.
   */
  protected Font nameFont;
  
  /**
   * The color of the group font/foreground information.
   */
  protected Color foregroundColor;
  
  /**
   * The backing model of the group view.
   */
  protected GroupModel model;
  
  /**
   * Constructs a group model with the default color scheme and layout method.
   * Bounds will be interpolated according to the default layout method.
   * 
   * @param model The model to base the group view on.
   */
  public GroupView(GroupModel model)
  {
    if(model != null)
    {
      this.model = model;
    }
    // TODO: specify default layout method, create bounds shape
    backgroundColor = UIConstants.BUI_GROUPAREA_COLOR;
    foregroundColor = UIConstants.BUI_GROUPTEXT_COLOR;
    nameFont = UIConstants.BUI_GROUPTEXT_FONT;
  }
  
  /**
   * Constructs a group model with the default color scheme and specified
   * layout method.  Bounds will be interpolated according to the default
   * layout method.
   * 
   * @param model The model to base the group view on.
   * @param method The layout method to organize the thumbnails by (in the
   *               group).
   */
  public GroupView(GroupModel model, LayoutMethod method)
  {
    if(model != null)
    {
      this.model = model;
    }
    
    if(method != null)
    {
      this.layoutMethod = method;
    }
    else
    {
      // TODO: specify default layout method, create bounds shape
    }
    
    backgroundColor = UIConstants.BUI_GROUPAREA_COLOR;
    foregroundColor = UIConstants.BUI_GROUPTEXT_COLOR;
    nameFont = UIConstants.BUI_GROUPTEXT_FONT;
  }
  
  /**
   * Constructs a group view with the specified backing model, layout method,
   * and maximum bounds constraints.
   * 
   * @param model The group model to base the view on.
   * @param method The layout method to order the thumbnails by.
   * @param bounds The maximum bounds of the group.
   */
  public GroupView(GroupModel model, LayoutMethod method, Shape bounds)
  {
    if(model != null)
    {
      this.model = model;
    }
    
    if(method != null)
    {
      this.layoutMethod = method;
    }
    else
    {
      // TODO: specify default layout method
    }
    
    if(bounds != null)
    {
      // TODO: set bounds
    }
    else
    {
      // TODO: interpolate based on layout method
    }
  }
}
