/*
 * org.openmicroscopy.remote.XmlRpcCaller
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

import java.net.URL;
import java.util.*;
import org.apache.xmlrpc.XmlRpcClient;
import org.openmicroscopy.Session;

public class XmlRpcCaller
    implements RemoteCaller
{
    protected XmlRpcClient  xmlrpc;
    protected Vector        vparams = new Vector();
    protected String        sessionReference = null;
    protected Session       session = null;

    public XmlRpcCaller(URL url)
    {
        try
        {
            xmlrpc = new XmlRpcClient(url);
        } catch (Exception e) {
            xmlrpc = null;
            System.err.println(e);
        }
    }

    public void login(String username, String password)
    {
        if (sessionReference == null)
        {
            vparams.addElement(username);
            vparams.addElement(password);
            sessionReference = invoke("createSession").toString();
            session = new RemoteSession(sessionReference);
        }
    }

    public void logout()
    {
        if (sessionReference != null)
        {
            vparams.addElement(sessionReference);
            invoke("closeSession");
            sessionReference = null;
            session = null;
        }
    }

    public Session getSession()
    {
        return session;
    }

    protected Object invoke(String method)
    {
        try
        {
            Object retval = xmlrpc.execute(method,vparams);
            vparams.clear();
            return retval;
        } catch (Exception e) {
            return null;
        }
    }

    public Object invoke(String method, Object[] params)
    {
        if (sessionReference == null)
            throw new IllegalArgumentException("Have not logged in");

        vparams.addElement(sessionReference);
        if (params != null)
        {
            for (int i = 0; i < params.length; i++)
                vparams.addElement(params[i]);
        }
        return invoke(method);
    }

    public Object dispatch(Object target, String method)
    {
        return dispatch(target,method,null);
    }

    public Object dispatch(Object target, String method, 
                           Object param1)
    {
        return dispatch(target,method,new Object[] {param1});
    }

    public Object dispatch(Object target, String method, Object[] params)
    {
        if (sessionReference == null)
            throw new IllegalArgumentException("Have not logged in");

        vparams.addElement(sessionReference);
        vparams.addElement(target.toString());
        vparams.addElement(method);
        if (params != null)
        {
            for (int i = 0; i < params.length; i++)
            {
                if (params[i] instanceof RemoteObject)
                    vparams.addElement(params[i].toString());
                else
                    vparams.addElement(params[i]);
            }
        }
        return invoke("dispatch");
    }
}
