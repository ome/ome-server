/*
 * org.openmicroscopy.remote.RemoteSession
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

import org.openmicroscopy.Session;
import org.openmicroscopy.Factory;
import org.openmicroscopy.Project;
import org.openmicroscopy.Dataset;
import org.openmicroscopy.Attribute;

public class RemoteSession
    extends RemoteOMEObject
    implements Session
{
    static { RemoteObject.addClass("OME::Session",RemoteSession.class); }

    protected void finalize()
    {
        // RemoteObject will automatically call the freeObject method
        // in the remote server when the object is garbage collected.
        // This should not happen for Sessions, so we override
        // finalize to do nothing.
    }

    public RemoteSession() { super(); }
    public RemoteSession(String reference) { super(reference); }

    public Factory getFactory()
    { return (Factory) getRemoteElement(RemoteFactory.class,"Factory"); }

    public Attribute getUser()
    { return (Attribute) getRemoteElement(RemoteAttribute.class,"User"); }

    public Project getProject()
    { return (Project) getRemoteElement(RemoteProject.class,"project"); }
    public void setProject(Project project)
    { setRemoteElement("project",project); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement(RemoteDataset.class,"dataset"); }
    public void setDataset(Dataset dataset)
    { setRemoteElement("dataset",dataset); }

}
