/*
 * org.openmicroscopy.ds.XmlRpcCaller
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
import java.util.Map;
import java.util.List;
import java.util.Iterator;
import java.util.Vector;
import java.util.Hashtable;
import java.io.File;
import java.io.FileWriter;
import java.io.BufferedWriter;
import java.io.PrintWriter;
import java.io.IOException;
import org.apache.xmlrpc.XmlRpc;
import org.apache.xmlrpc.XmlRpcClient;
import org.apache.xmlrpc.XmlRpcClientLite;

/**
 * <p>A concrete implementation of the {@link RemoteCaller} interface,
 * which uses XML-RPC as a transport mechanism.</p>
 *
 * <h4>Thread safety</h4>
 *
 * <p>This class only allows a single XML-RPC call to be made at a
 * time.  The methods are appropriately synchronized to ensure that
 * this happens properly.  The <code>invoke</code> and
 * <code>dispatch</code> methods can be safely called from multiple
 * threads.  However, it is not defined in which order simultaneous
 * method calls will be executed, so the possibility for race
 * conditions still exist.  As is usual with multi-threaded
 * applications, care must be taken not to screw things up.</p>
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class XmlRpcCaller
    extends AbstractRemoteCaller
{
    /**
     * The String used to represent the null value in an XML-RPC
     * message.  XML-RPC does not directly support null values, so we
     * must substitute nulls with an implicitly agreed-upon String
     * value.
     */
    public static final String  NULL_REFERENCE = "*([-NULL-])*";

    public static final boolean TRACE_CALLS = false;
    public static final boolean USE_LITE_CLIENT = true;

    private boolean profileCalls = false;
    private long profilerTime = 0L;

    private XmlRpcClient  xmlrpc;
    private Vector        vparams = new Vector();
    private String        sessionKey = null;

    private File  traceFilename;
    private PrintWriter  traceFile;

    public XmlRpcCaller()
    {
        super();
    }

    /**
     * Creates a new <code>XmlRpcCaller</code> which can be used to
     * send remote method calls to the data server at the specified
     * URL.
     */
    public XmlRpcCaller(URL url)
    {
        super();

        try
        {
            xmlrpc = createClient(url);
            XmlRpc.setKeepAlive(false);
        } catch (Exception e) {
            System.err.println(e);
            throw new RemoteConnectionException("Error logging in to data server");
        }
    }

    /**
     * Helper method used to create an instance of the {@link
     * XmlRpcClient} class for this instance.  The default
     * implementation will create an instance of {@link XmlRpcClient}
     * or {@link XmlRpcClientLite}, depending on the value of the
     * {@link #USE_LITE_CLIENT} static field.  If this default is not
     * appropriate, subclasses can override this method to return a
     * different subclass, or an instance with different configuration
     * options.
     */
    protected XmlRpcClient createClient(URL url)
    {
        if (USE_LITE_CLIENT)
            return new XmlRpcClientLite(url);
        else
            return new XmlRpcClient(url);
    }

    /**
     * <p>Encodes an object into a suitable representation to be sent
     * to the XML-RPC layer.  <b>Note:</b> This method is only used to
     * perform encodings specific to the transport layer in use.  For
     * instance, XML-RPC does not support null values, so any null
     * values in the <code>object</code> parameter will be transformed
     * into a String value which can be transmitted.  <b>This method
     * is not intended for translating high-level data representation
     * objects into low-level XML-RPC transmission objects.</b> That
     * functionality is dependent on the high-level encoding in
     * question, and therefore is not appropriate to this class.</p>
     *
     * <p>This method can be overridden if the default encoding is not
     * appropriate.</p>
     */
    protected Object encodeObject(Object object)
    {
        if (object == null)
        {
            return NULL_REFERENCE;
        } else if (object instanceof Long ||
                   object instanceof Short) {
            return object.toString();
        } else if (object instanceof List) {
            List list = new Vector();
            Iterator it = ((List) object).iterator();
            while (it.hasNext())
                list.add(encodeObject(it.next()));
            return list;
        } else if (object instanceof Map) {
            Map map = new Hashtable();
            Iterator it = ((Map) object).keySet().iterator();
            while (it.hasNext())
            {
                Object key = it.next();
                Object value = ((Map) object).get(key);
                map.put(encodeObject(key),encodeObject(value));
            }
            return map;
        } else {
            return object;
        }
    }

    private void addParameter(Object object)
    {
        synchronized(this)
        {
            vparams.add(encodeObject(object));
        }
    }

    public void startProfiler() { profileCalls = true; }
    public void stopProfiler() { profileCalls = false; }
    public void resetProfiler() { profilerTime = 0L; }
    public long getProfiledMilliseconds() { return profilerTime; }

    private Object invoke(String method)
    {
        synchronized(this)
        {
            long startTime = System.currentTimeMillis();

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

                long stopTime = System.currentTimeMillis();
                if (profileCalls)
                {
                    long thisTime = stopTime-startTime;
                    profilerTime += thisTime;
                    System.err.println("Profiler: "+thisTime);
                }

                return retval;
            } catch (IOException e) {
                throw new RemoteConnectionException(e.getMessage());
            } catch (Exception e) {
                if (TRACE_CALLS)
                {
                    traceFile.println("execute exception ("+e.getClass()+
                                      "): "+e.getMessage());
                    e.printStackTrace(traceFile);
                }

                long stopTime = System.currentTimeMillis();
                if (profileCalls)
                {
                    long thisTime = stopTime-startTime;
                    profilerTime += thisTime;
                    System.err.println("Profiler: "+thisTime);
                }

                String msg = e.getMessage();
                if (msg.startsWith("STALE SESSION") ||
                    msg.startsWith("INVALID LOGIN"))
                    throw new RemoteAuthenticationException(msg);
                else
                    throw new RemoteServerErrorException(msg);
            } finally {
                vparams.clear();
            }
        }
    }

    // JAVADOC NOTICE:
    // The following public methods inherit their javadoc
    // documentation from the RemoteCaller interface.

    public void login(String username, String password)
    {
        synchronized(this)
        {
            if (sessionKey == null)
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
                Object result = invoke("createSession");

                sessionKey = (result == null)? null: result.toString();

                if (sessionKey == null || sessionKey.equals(""))
                    throw new RemoteAuthenticationException("Could not log in");
            }
        }
    }

    public void logout()
    {
        synchronized(this)
        {
            if (sessionKey != null)
            {
                vparams.addElement(sessionKey);
                invoke("closeSession");
                sessionKey = null;

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

    public ServerVersion getServerVersion()
    {
        synchronized(this)
        {
            Object result = null;
            try
            {
                result = invoke("serverVersion");
            } catch (RemoteServerErrorException e) {
                String message = e.getMessage();

                if (message.indexOf("Failed to locate method") >= 0)
                {
                    /* The server version method does not exist yet.
                     * Return a null value. */
                    return null;
                } else {
                    /* We can't figure out what this error is, so we
                     * should propagate it. */
                    throw e;
                }
            }
            if (result instanceof List)
            {
                List version = (List) result;
                if (version.size() != 3)
                    throw new RemoteServerErrorException("Server version had the wrong size: "+version.size());

                Integer major = PrimitiveConverters.
                    convertToInteger(version.get(0));
                Integer minor = PrimitiveConverters.
                    convertToInteger(version.get(1));
                Integer patch = PrimitiveConverters.
                    convertToInteger(version.get(2));

                return new ServerVersion(major.intValue(),
                                         minor.intValue(),
                                         patch.intValue());
            } else {
                throw new RemoteServerErrorException("Server version returned was not of the right type: "+result.getClass()+" ("+result+")");
            }
        }
    }

    public String getSessionKey() { return sessionKey; }
    public void setSessionKey(String key) { sessionKey = key; }

    public Object invoke(String method,Object[] params) {
    		return dispatch(method,params);
    }

    public Object dispatch(String method, Object[] params)
    {
        synchronized(this)
        {
            if (sessionKey == null)
                throw new IllegalArgumentException("Have not logged in");

            addParameter(sessionKey);
            addParameter(method);
            if (params != null)
            {
                for (int i = 0; i < params.length; i++)
                    addParameter(params[i]);
            }
            return invoke("dispatch");
        }
    }

}
