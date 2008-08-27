/*
 * org.openmicroscopy.ds.DataServices
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds;

import java.util.Map;
import java.util.HashMap;

public class DataServices
{
    private static Map instances = new HashMap();

    public static DataServices getNewInstance()
    {
        DataServices instance = new DataServices();
        return instance;
    }

    public static DataServices getInstance(RemoteCaller caller)
    {
        DataServices instance = (DataServices) instances.get(caller);

        if (instance != null)
            return instance;

        instance = getNewInstance();
        instance.assignRemoteCaller(caller);
        return instance;
    }

    private RemoteCaller  remoteCaller;

    private Map  services = new HashMap();

    private DataServices()
    {
        super();
        this.remoteCaller = null;
    }

    private DataServices(RemoteCaller caller)
    {
        super();
        this.remoteCaller = caller;
    }

    public String getSessionKey()
    {
        if (this.remoteCaller == null)
            throw new IllegalStateException("No RemoteCaller");

        return remoteCaller.getSessionKey();
    }

    public RemoteCaller getRemoteCaller()
    {
        if (this.remoteCaller == null)
            throw new IllegalStateException("No RemoteCaller");

        return remoteCaller;
    }

    public void assignRemoteCaller(RemoteCaller caller)
    {
        if (this.remoteCaller != null)
            throw new IllegalStateException("RemoteCaller already assigned");

        this.remoteCaller = caller;
        instances.put(caller,this);
        services.put(RemoteCaller.class,caller);
    }

    private DataService instantiateService(Class clazz)
    {
        if (!DataService.class.isAssignableFrom(clazz))
            throw new IllegalArgumentException("Class is not a DataService implementation");

        DataService service = (DataService) services.get(clazz);
        if (service != null)
            return service;

        try
        {
            service = (DataService) clazz.newInstance();
        } catch (InstantiationException e) {
            throw new RemoteException("Could not instantiate service");
        } catch (IllegalAccessException e) {
            throw new RemoteException("Could not access service");
        }

        service.initializeService(this);
        services.put(clazz,service);

        return service;
    }

    public DataService getService(Class clazz)
    {
        return instantiateService(clazz);
    }
}
