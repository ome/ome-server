/*
 * org.openmicroscopy.ds.DataServer
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy.ds;

import java.net.URL;
import java.net.MalformedURLException;

/**
 * Factory class for retrieving instances of the {@link RemoteCaller}
 * interface.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

public class DataServer
{
    /**
     * This class should never be instantiated, so the constructor
     * throws an exception.
     * @throws UnsupportedOperationException always
     */
    private DataServer()
    { 
        throw new UnsupportedOperationException(
            "DataServer should not be instantiated");
    }

    /**
     * Returns a {@link RemoteCaller} which can be used to communicate
     * with a data server at the specified URL.
     * @param url the URL of the data server
     * @throws MalformedURLException if <code>url</code> does not
     * encode a well-formed URL
     */
    public static RemoteCaller getDefaultCaller(String url)
        throws MalformedURLException
    {
        return getDefaultCaller(new URL(url));
    }

    /**
     * Returns a {@link RemoteCaller} which can be used to communicate
     * with a data server at the specified URL.
     * @param url the URL of the data server
     */
    public static RemoteCaller getDefaultCaller(URL url)
    {
        return new XmlRpcCaller(url);
    }
}
