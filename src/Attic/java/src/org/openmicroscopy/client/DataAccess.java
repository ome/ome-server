/*
 * org.openmicroscopy.client.DataAccess
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
 * Written by:    Brian S. Hughes <bshughes@mit.edu>
 *
 *------------------------------------------------------------------------------
 */


/**
 * <p>Title: DataAccess.java</p>
 * <p>Description: Class to access data from remote objects </p>
 */


package org.openmicroscopy.client;

import java.util.List;
import java.awt.*;
import java.util.HashMap;
import java.util.Iterator;
import org.openmicroscopy.remote.*;
import org.openmicroscopy.*;         ;



/**
 * Handles creating and using a binding to a remote OME server.
 * Serves as the interface between the client package and OME's
 * remote package, which in turn manages the communications layer
 * to the remote server.
 *
 * @author  Brian S. Hughes 
 * @version 2.0
 * @since   OME 2.0.3
 */


public class DataAccess {
    /**
     * The instance of RemoteBindings to use for this session.
     */
    RemoteBindings  bindings = null;

    /**
     * Constructs the DataAccess instance for use for the duration of the
     * current workstation session. Nothing useful can be done until
     * a DataAccess instance is formed, and it aquires a RemoteBinding.
     *
     * @throws any exception after catching and logging it. 
     * TODO - catch exceptions that can be corrected & re-try.
     * @see org.openmicroscopy.remote.RemoteBindings
     */

    public DataAccess() throws Exception {
	try {
	    bindings = new RemoteBindings();
	} catch (Exception e) {
	    throw(e);
        }
    }


    /**
     *  Calls the binding's loginXMLRPC method to actually do
     * the remote part of a session login.
     *
     * @param URL  the URL of the remote server
     * @param Name the user name to login
     * @param Passwd the user's password
     * @throws any exception, after catching and logging it
     * @see org.openmicroscopy.remote.RemoteBindings#Login
     */
    public void Login(String URL, String Name, String Passwd) throws Exception {
	try {
	    bindings.loginXMLRPC(URL, Name, Passwd);
	} catch (Exception e) {
	    System.err.println("login: caught exception "+e);
	    throw(e);
	}
    }


    /**
     *  Calls the binding's logoutXMLRPC method to actually do
     * the remote part of a session logout.
     * @see .remote.RemoteBindings#Logout
     */
    public void Logout() {
	bindings.logoutXMLRPC();
    }


    /**
     * Retrieve the named dataset's Object. This object 
     * contains all the data and methods needed to work with a dataset.
     *
     * @param name  the text name of the dataset
     * @return Dataset 
     * @see Dataset
     */
    public Dataset getDataset(String name) {
	HashMap criteria = new HashMap();

	criteria.put("name", name);
	return (org.openmicroscopy.Dataset)Lookup("OME::Dataset", criteria);
    }

    /**
     *  Retrieves the name of the active dataset
     */
    public String getDatasetName () {
	return getActiveDataset().getName();
    }

    /**
     * Set the passed Dataset as the active dataset in the remote session
     * @param ds Dataset to set as active
     */
    public void setActiveDataset (Dataset ds) {
	bindings.getSession().setDataset(ds);
    }

    /**
     * Retrieve the active dataset
     * @return Dataset
     */
    public Dataset getActiveDataset() {
	return bindings.getSession().getDataset();
    }


    /**
     * Retrieve the named image's Object. This object 
     * contains all the data and methods needed to work with an image
     *
     * @param name  the text name of the image
     * @return Image
     * @see Image
     */
    public org.openmicroscopy.Image getImage(String name) {
	HashMap criteria = new HashMap();

	criteria.put("name", name);
	return (org.openmicroscopy.Image)Lookup("OME::Image", criteria);
    }


    /**
     * Retrieve the named chain's Object. This object 
     * contains all the data and methods needed to work with a chain
     *
     * @param name  the text name of the chain
     * @return Chain
     * @see Chain
     */
    public Chain getChain(String name) {
	HashMap criteria = new HashMap();

	criteria.put("name", name);
	return (org.openmicroscopy.Chain)Lookup("OME::AnalysisChain", criteria);
    }

    /**
     * Set the passed Project as the active project in the remote session
     * @param p Project to set as active
     */
    public void setActiveProject (Project p) {
	bindings.getSession().setProject(p);
    }

    /**
     * Retrieve the active project
     * @return Project
     */
    public Project getActiveProject() {
	return bindings.getSession().getProject();
    }


    /**
     * Retrieve the current user
     * @return user Attribute
     */
    public Attribute getUser() {
	return(bindings.getSession().getUser());
    }

    /**
     *   Lookup an object that meets a set of criteria
     *   @param what  what type of object to lookup
     *   @param criteria  a hash of lookup criteria
     *   @return an OMEObject of the proper type that meets the criteria.
     *   May return null. If more than one object meet the criteria,
     *   one will be arbitrarily returned.
     */
    public OMEObject Lookup(String what, HashMap criteria) {
	return(bindings.getFactory().findObject(what, criteria));
    }

    /**
     *   Lookup a set of objects that meets a set of criteria
     *   @param what  what type of object to lookup
     *   @param criteria  a hash of lookup criteria
     *   @return an List of OMEObjects of the proper type that meets the criteria.
     *   May return null.
     */
    public List LookupSet(String what, HashMap criteria) {
	return(bindings.getFactory().findObjects(what, criteria));
    }

    /**
     *   Lookup a set of objects that meets a set of criteria
     *   @param what  what type of object to lookup
     *   @param criteria  a hash of lookup criteria
     *   @return an Iterator of OMEObjects of the proper type that meets the criteria.
     *   May return an empty iterator.
     *   @see java.util.Iterator
     */
    public Iterator IterateSet(String what, HashMap criteria) {
	Iterator i = null;
	try {
	    i = bindings.getFactory().iterateObjects(what, criteria);
	}
	catch (Exception e) {
	    System.err.println("Exception: " + e);
	}
	return i;
    }


}



