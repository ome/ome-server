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
import org.apache.xmlrpc.XmlRpc;
import org.apache.xmlrpc.XmlRpcClient;
import org.apache.xmlrpc.XmlRpcClientLite;
import org.openmicroscopy.Session;

public class XmlRpcCaller
    implements RemoteCaller
{
    private XmlRpcClientLite  xmlrpc;
    private Vector        vparams = new Vector();
    private String        sessionReference = null;
    private Session       session = null;

    public XmlRpcCaller(URL url)
    {
        try
        {
            xmlrpc = new XmlRpcClientLite(url);
            XmlRpc.setKeepAlive(false);
        } catch (Exception e) {
            xmlrpc = null;
            System.err.println(e);
        }
    }

    public void login(String username, String password)
    {
        synchronized(this)
        {
            if (sessionReference == null)
            {
                vparams.addElement(username);
                vparams.addElement(password);
		sessionReference = invoke("createSession").toString();
		if (!sessionReference.equals("")) {
		    session = new RemoteSession(sessionReference);
		}
            }
        }
    }

    public void logout()
    {
        synchronized(this)
        {
            if (sessionReference != null)
            {
                vparams.addElement(sessionReference);
                invoke("closeSession");
                sessionReference = null;
                session = null;
            }
        }
    }

    public Session getSession()
    {
        return session;
    }

    private Object invoke(String method)
    {
        synchronized(this)
        {
            try
            {
                Object retval = xmlrpc.execute(method,vparams);
                return retval;
            } catch (Exception e) {
                //System.err.println("execute exception: "+e.getMessage());
                throw new RemoteException(e.getMessage());
            } finally {
                vparams.clear();
            }
        }
    }

    public Object invoke(String method, Object[] params)
    {
        synchronized(this)
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
    }

    public Object dispatch(Object target, String method)
    {
        return dispatch(target,method,(Object[]) null);
    }

    public Object dispatch(Object target, String method,
                           Object param1)
    {
        return dispatch(target,method,new Object[] {param1});
    }

    public Object dispatch(Object target, String method, Object[] params)
    {
        synchronized(this)
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
                    else if (params[i] instanceof List)
                        vparams.addElement(new Vector((List) params[i]));
                    else if (params[i] instanceof Map)
                        vparams.addElement(new Hashtable((Map) params[i]));
                    else
                        vparams.addElement(params[i]);
                }
            }
            return invoke("dispatch");
        }
    }

    public void freeObject(RemoteObject target)
    {
        synchronized(this)
        {
            if (sessionReference == null)
                throw new IllegalArgumentException("Have not logged in");

            vparams.addElement(sessionReference);
            vparams.addElement(target.toString());
            invoke("freeObject");
        }
    }

    public void freeObject(String targetReference)
    {
        synchronized(this)
        {
            if (sessionReference == null)
                throw new IllegalArgumentException("Have not logged in");

            vparams.addElement(sessionReference);
            vparams.addElement(targetReference);
            invoke("freeObject");
        }
    }
}
