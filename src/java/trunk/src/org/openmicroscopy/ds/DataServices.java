/*
 * org.openmicroscopy.ds.RemoteServices
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

public class RemoteServices
{
    private static Map instances = new HashMap();

    public static RemoteServices getInstance(RemoteCaller caller)
    {
        RemoteServices instance = (RemoteServices) instances.get(caller);

        if (instance != null)
            return instance;

        instance = new RemoteServices(caller);
        return instance;
    }

    private RemoteCaller  remoteCaller;

    private Map  services = new HashMap();

    private RemoteServices(RemoteCaller caller)
    {
        super();
        this.remoteCaller = caller;
    }

    public String getSessionKey() { return remoteCaller.getSessionKey(); }

    public RemoteCaller getRemoteCaller() { return remoteCaller; }

    private RemoteService instantiateService(Class clazz)
    {
        if (!RemoteService.class.isAssignableFrom(clazz))
            throw new IllegalArgumentException("Class is not a RemoteService implementation");

        RemoteService service = (RemoteService) services.get(clazz);
        if (service != null)
            return service;

        try
        {
            service = (RemoteService) clazz.newInstance();
        } catch (InstantiationException e) {
            throw new RemoteException("Could not instantiate service");
        } catch (IllegalAccessException e) {
            throw new RemoteException("Could not access service");
        }

        service.initializeService(this);
        services.put(clazz,service);

        return service;
    }

    public RemoteService getService(Class clazz)
    {
        return instantiateService(clazz);
    }
}
