/*
 * org.openmicroscopy.semanticdemo.OMEManager
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
package org.openmicroscopy.semanticdemo;

import java.net.MalformedURLException;

import org.openmicroscopy.Factory;
import org.openmicroscopy.Session;
import org.openmicroscopy.remote.RemoteBindings;

/**
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class OMEManager
{
  private Session session = null;
  private Factory factory = null;
  private RemoteBindings bindings = null;
  private boolean loggedIn;

  public OMEManager()
    throws OMEException
  {
    try
    {
      bindings = new RemoteBindings();
    }
    catch(ClassNotFoundException ce)
    {
      throw new OMEException("Could not create remote bindings.");
    }
    loggedIn = false;
  }
  
  public void login(String xmlRpcURL, String username, String password)
    throws OMEException
  {
    try
    {
      bindings.loginXMLRPC(xmlRpcURL,username,password);
      session = bindings.getSession();
      factory = bindings.getFactory();
      loggedIn = true;
    }
    catch(MalformedURLException mex)
    {
      throw new OMEException("Invalid URL.");
    }
    catch(Exception e)
    {
      throw new OMEException("Could not log in as "+username
                             +": " + e.getMessage());
    }
  }
  
  public void logout()
    throws OMEException
  {
    if(!loggedIn)
    {
      return;
    }
    try
    {
      bindings.logoutXMLRPC();
      session = null;
      factory = null;
      loggedIn = false;
    }
    catch(Exception e)
    {
      throw new OMEException("Could not log out: " + e.getMessage());
    }
  }
  
  public Session getSession()
  {
    return session;
  }
  
  public Factory getFactory()
  {
    return factory;
  }
  
  public RemoteBindings getBindings()
  {
    return bindings;
  }
  
  public boolean isLoggedIn()
  {
    return loggedIn;
  }
}
