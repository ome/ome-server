/*
 * org.openmicroscopy.remote.RemoteBindings
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.remote;

import org.openmicroscopy.*;
import java.net.URL;
import java.net.MalformedURLException;

/**
 * <p>The main point-of-entry for using the OME Remote Framework from
 * Java code.  Client code should create an instance of this class,
 * and use it to log into and out of OME via the Remote Framework.
 * The {@link #getSession} and {@link #getFactory} methods can be used
 * to create and retrieve OME objects.  All of the Remote classes
 * implement the interfaces defined in the
 * <code>org.openmicroscopy</code> package.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public class RemoteBindings
{
    private static boolean classesLoaded = false;

    /**
     * <p>Ensures that all of the remote implementations of the
     * <code>org.openmicroscopy</code> interfaces are loaded by the
     * class loader.  This is necessary so that the remote
     * implementation of {@link Factory} can instantiate objects
     * coming in on the XML-RPC stream into their appropriate
     * <code>org.openmicroscopy.remote</code> class.</p>
     *
     * <p><b>NOTE:</b> Though this method is declared
     * <code>public</code>, it should not be called directly.  The
     * {@link #RemoteBindings} constructor will ensure that this
     * method is called before returning.</p>
     * 
     * <p>The hard-wiring of class names into this procedure does not 
     * mean that any of these classes cannot be subclassed. To extend one 
     * of these classes, several steps mus be taken:
     *  <ul><li>The appropriate class must be declared as a subclass
     *  of one of these classes (which all subclass {@link RemoteOMEObject}).
     * <li>In the subclass, the call to the appropriate "OME::ClassName" structure
     * must be associated with the new class via a call to RemoteObject.addClass()".
     * This call will override the entry in RemoteObject associating the OME Class
     * with the superclass of the new class.
     * <li>A "Class.forName()" call for the new class must be made in some 
     * appropriate spot. One way to do this would be to extend RemoteBindings. 
     * Alternatively, this call could be made?
     *  
     */

    public static void loadClasses()
        throws ClassNotFoundException
    {
        if (!classesLoaded)
        {
            Class.forName("org.openmicroscopy.remote.RemoteModuleExecution");
            Class.forName("org.openmicroscopy.remote.RemoteModuleCategory");
            Class.forName("org.openmicroscopy.remote.RemoteAnalysisPath");
            Class.forName("org.openmicroscopy.remote.RemoteAttribute");
            Class.forName("org.openmicroscopy.remote.RemoteSemanticType");
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

    /**
     * <p>Creates a new instance of the <code>RemoteBindings</code>
     * class.  There should be one instance of
     * <code>RemoteBindings</code> for each simultaneous login that
     * the client supports.  (In most cases, this means that there
     * should be exactly one <code>RemoteBindings</code> instance per
     * client.)</p>
     */

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

    /**
     * <p>Logs into OME via the Remote Framework.  The URL should
     * refer to an XML-RPC server implementing the Remote Framework
     * interface.  If this <code>RemoteBindings</code> is already
     * logged into an OME server, this method does nothing.</p>
     *
     * @param url the URL of the OME Remote server
     * @param username the username to log in as
     * @param password the password to log in with
     * @throws MalformedURLException if <code>url</code> does not
     * represent a valid URL
     */

    public void loginXMLRPC(String url, String username, String password)
        throws MalformedURLException
    {
        loginXMLRPC(new URL(url),username,password);
    }

    /**
     * <p>Logs into OME via the Remote Framework.  The URL should
     * refer to an XML-RPC server implementing the Remote Framework
     * interface.  If this <code>RemoteBindings</code> is already
     * logged into an OME server, this method does nothing.</p>
     *
     * @param url the URL of the OME Remote server
     * @param username the username to log in as
     * @param password the password to log in with
     */

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
		if (session != null) {
		    factory = session.getFactory();
		    loggedIn = true;
		}
		else {
		    throw new RemoteException("Failed to log in");
		}
            } else {
                throw new RemoteException("Already logged in!");
            }
        }
    }

    /**
     * <p>Logs out of OME.  If this <code>RemoteBindings</code> is not
     * logged into an OME server, this method does nothing.</p>
     */

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

    /**
     * <p>Returns the {@link Session} object associated with this
     * <code>RemoteBindings</code>.  If it is not logged into OME,
     * this method returns <code>null</code>.</p>
     *
     * @return the {@link Session} object associated with this
     * instance
     */

    public Session getSession() { return session; }

    /**
     * <p>Returns the {@link Factory} object associated with this
     * <code>RemoteBindings</code>.  If it is not logged into OME,
     * this method returns <code>null</code>.</p>
     *
     * @return the {@link Factory} object associated with this
     * instance
     */

    public Factory getFactory() { return factory; }
}
