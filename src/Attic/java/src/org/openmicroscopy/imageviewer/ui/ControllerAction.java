/*
 * org.openmicroscopy.imageviewer.ControllerAction
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
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.imageviewer.ui;

import java.awt.Toolkit;

import javax.swing.AbstractAction;
import javax.swing.KeyStroke;

/**
 * An abstract class for building actions in this controller.
 * Helps to completely detach a view from the controller's
 * implementation by facilitating a one-to-one widget-to-action
 * mapping.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $ Revision: $ $ Date: $
 */
public abstract class ControllerAction
  extends AbstractAction
{
  
  private static int COMMAND_MASK =
    Toolkit.getDefaultToolkit().getMenuShortcutKeyMask();
  
  // default constructor
  /**
   * @see javax.swing.AbstractAction#AbstractAction(java.lang.String)
   */
  public ControllerAction(String name)
  {
    super(name);
  }
  
  // default key-triggered constructor
  /**
   * @see javax.swing.AbstractAction#AbstractAction(java.lang.String,int)
   */
  public ControllerAction(String name, int key)
  {
    super(name);
    putValue(ACCELERATOR_KEY,
             KeyStroke.getKeyStroke(key,COMMAND_MASK));
  }
  
  // default key-with-modifier-triggered constructor
  /**
   * @see javax.swing.AbstractAction#AbstractAction(java.lang.String,int,int)
   */
  public ControllerAction(String name, int key, int modifiers)
  {
    super(name);
    putValue(ACCELERATOR_KEY,
             KeyStroke.getKeyStroke(key,COMMAND_MASK | modifiers));
  }
  
  /**
   * Returns the key stroke that triggers this action.
   * @return See above.
   */
  public KeyStroke getAccelerator()
  {
    return (KeyStroke) getValue(ACCELERATOR_KEY);
  }
  
  /**
   * Good in case the view wants to override the default key trigger.  The
   * specified key plus the default command key will be bound to the action.
   * (i.e., KeyEvent.VK_L -> binds this Action to Ctrl-L/Apple-L.)
   * 
   * @param key The new key trigger to use (plus default command)
   *        i.e., KeyEvent.VK_L -> binds this Action to Ctrl-L/Apple-L.
   */
  public void setAccelerator(int key)
  {
    putValue(ACCELERATOR_KEY,
             KeyStroke.getKeyStroke(key,COMMAND_MASK));
  }
  
  /**
   * Good in case the view wants to override the default key trigger.  The
   * specified key and modifier plus the default command key will be bound
   * to the action.  (i.e., KeyEvent.VK_L, SHIFT_MASK -> binds this action
   * to Ctrl-Shift-L/Apple-Shift-L.)
   * 
   * @param key The new key trigger to use (plus default command)
   * @param modifiers The modifier to use.
   */
  public void setAccelerator(int key, int modifiers)
  {
    putValue(ACCELERATOR_KEY,
             KeyStroke.getKeyStroke(key,COMMAND_MASK | modifiers));
  }
}