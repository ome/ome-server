/*
 * org.openmicroscopy.browser.ome.OMEMessageHandler
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
package org.openmicroscopy.browser.ome;

import org.openmicroscopy.browser.MessageHandler;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * <b>Internal version:</b> $Revision$ $Date$
 * @version 2.2
 * @since 2.2
 */
public class OMEMessageHandler implements MessageHandler
{
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportInternalError(java.lang.String)
   */
  public void reportInternalError(String message)
  {
    // TODO: hook up to UserNotifier (integrate) or System.err
  }
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportInternalError(java.lang.String, java.lang.Exception)
   */
  public void reportInternalError(String message, Exception e)
  {
    // TODO: hook up to UserNotifier (integrate) or System.err
  }
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportError(java.lang.String)
   */
  public void reportError(String message)
  {
    // TODO: hook up to UserNotifier (integrate)
  }
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportError(java.lang.String,java.lang.Exception)
   */
  public void reportError(String message, Exception e)
  {
    // TODO: hook up to UserNotifier (integrate)

  }
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportInformation(java.lang.String)
   */
  public void reportInformation(String message)
  {
    // TODO: hook up to UserNotifier (integrate)
  }
  
  /**
   * @see org.openmicroscopy.browser.MessageHandler#reportWarning(java.lang.String)
   */
  public void reportWarning(String message)
  {
    // TODO: hook up to UserNotifier (integrate)
  }

}
