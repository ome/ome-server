/*
 * org.openmicroscopy.remote.RemoteBindings
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.net.URL;
import java.net.MalformedURLException;

public class RemoteBindings
{
    private static boolean classesLoaded = false;
    public static void loadClasses()
        throws ClassNotFoundException
    {
        if (!classesLoaded)
        {
            Class.forName("org.openmicroscopy.remote.RemoteAnalysis");
            Class.forName("org.openmicroscopy.remote.RemoteAnalysisPath");
            Class.forName("org.openmicroscopy.remote.RemoteAttribute");
            Class.forName("org.openmicroscopy.remote.RemoteAttributeType");
            Class.forName("org.openmicroscopy.remote.RemoteChainExecution");
            Class.forName("org.openmicroscopy.remote.RemoteChain");
            Class.forName("org.openmicroscopy.remote.RemoteDataset");
            Class.forName("org.openmicroscopy.remote.RemoteDataTable");
            Class.forName("org.openmicroscopy.remote.RemoteFactory");
            Class.forName("org.openmicroscopy.remote.RemoteFeature");
            Class.forName("org.openmicroscopy.remote.RemoteImage");
            Class.forName("org.openmicroscopy.remote.RemoteIterator");
            Class.forName("org.openmicroscopy.remote.RemoteLookupTable");
            Class.forName("org.openmicroscopy.remote.RemoteModule");
            Class.forName("org.openmicroscopy.remote.RemoteObject");
            Class.forName("org.openmicroscopy.remote.RemoteOMEObject");
            Class.forName("org.openmicroscopy.remote.RemoteProject");
            Class.forName("org.openmicroscopy.remote.RemoteSession");
            classesLoaded = true;
        }
    }

    private boolean      loggedIn;
    private RemoteCaller remoteCaller;
    private XmlRpcCaller xmlRpcCaller;
    private Session      session;
    private Factory      factory;

    public RemoteBindings()
        throws ClassNotFoundException
    {
        loadClasses();
        this.loggedIn = false;
        this.remoteCaller = null;
        this.xmlRpcCaller = null;
        this.session = null;
        this.factory = null;
    }

    public void loginXMLRPC(String url, String username, String password)
        throws MalformedURLException
    {
        loginXMLRPC(new URL(url),username,password);
    }

    public void loginXMLRPC(URL url, String username, String password)
    {
        synchronized(this)
        {
            if (!loggedIn)
            {
                xmlRpcCaller = new XmlRpcCaller(url);
                xmlRpcCaller.login(username,password);
                RemoteObject.setRemoteCaller(xmlRpcCaller);

                remoteCaller = xmlRpcCaller;
                session = xmlRpcCaller.getSession();
                factory = session.getFactory();
                loggedIn = true;
            } else {
                throw new RemoteException("Already logged in!");
            }
        }
    }

    public void logoutXMLRPC()
    {
        synchronized(this)
        {
            if (loggedIn)
            {
                xmlRpcCaller.logout();
                session = null;
                factory = null;
                remoteCaller = null;
                xmlRpcCaller = null;
                loggedIn = false;
            } else {
                throw new RemoteException("Not logged in!");
            }
        }
    }

    public Session getSession() { return session; }
    public Factory getFactory() { return factory; }
}
