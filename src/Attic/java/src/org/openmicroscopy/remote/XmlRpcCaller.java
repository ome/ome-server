/*
 * org.openmicroscopy.remote.XmlRpcCaller
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




package org.openmicroscopy.remote;

import java.net.URL;
import java.util.*;
import java.io.*;
import org.apache.xmlrpc.XmlRpc;
import org.apache.xmlrpc.XmlRpcClientLite;
import org.openmicroscopy.Session;

public class XmlRpcCaller
    implements RemoteCaller
{
    public static boolean TRACE_CALLS = false;

    private XmlRpcClientLite  xmlrpc;
    private Vector        vparams = new Vector();
    private String        sessionReference = null;
    private Session       session = null;

    private File  traceFilename;
    private PrintWriter  traceFile;

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
                if (TRACE_CALLS)
                {
                    try
                    {
                        traceFilename = File.createTempFile("xmlrpc-",".trc");
                        traceFile = new PrintWriter(
                            new BufferedWriter(new FileWriter(traceFilename)),
                            true);
                        System.err.println("Using trace file "+traceFilename);
                    } catch (IOException e) {
                        System.err.println("Could not create trace file!");
                    }
                    traceFile.println("Login "+username+" ***");
                }

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

                if (TRACE_CALLS)
                {
                    traceFile.println("Logout");
                    traceFile.close();

                    traceFilename = null;
                    traceFile = null;
                }
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
                if (TRACE_CALLS)
                {
                    traceFile.print(method+"(");
                    for (int i = 0; i < vparams.size(); i++)
                    {
                        traceFile.print(vparams.elementAt(i)+",");
                    }
                    traceFile.println(")");
                }

                Object retval = xmlrpc.execute(method,vparams);
                return retval;
            } catch (Exception e) {
                if (TRACE_CALLS)
                {
                    traceFile.println("execute exception ("+e.getClass()+
                                      "): "+e.getMessage());
                    e.printStackTrace(traceFile);
                }
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
            if (target instanceof RemoteObject)
                vparams.addElement(((RemoteObject) target).getReference());
            else
                vparams.addElement(target.toString());
            vparams.addElement(method);
            if (params != null)
            {
                for (int i = 0; i < params.length; i++)
                {
                    if (params[i] == null)
                        vparams.addElement(">>OBJ:NULL");
                    else if (params[i] instanceof RemoteObject)
                        vparams.addElement(((RemoteObject) params[i]).
                                           getReference());
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
