/*
 * org.openmicroscopy.remote.RemoteSession
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

import org.openmicroscopy.Session;
import org.openmicroscopy.Factory;
import org.openmicroscopy.Project;
import org.openmicroscopy.Dataset;
import org.openmicroscopy.Attribute;
import org.openmicroscopy.managers.ChainManager;
import org.openmicroscopy.managers.ProjectManager;
import org.openmicroscopy.managers.DatasetManager;

public class RemoteSession
    extends RemoteOMEObject
    implements Session
{
    static { RemoteObjectCache.addClass("OME::Session",RemoteSession.class); }

    protected void finalize()
    {
        // RemoteObject will automatically call the freeObject method
        // in the remote server when the object is garbage collected.
        // This should not happen for Sessions, so we override
        // finalize to do nothing.
    }

    protected RemoteObjectCache  objectCache;
    protected boolean            active;

    public RemoteSession()
    {
        super();
        this.objectCache = new RemoteObjectCache(this);
    }

    public RemoteSession(String reference)
    {
        super(null, reference);
        this.objectCache = new RemoteObjectCache(this);
    }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public void commitTransaction()
    {
        caller.dispatch(this,"commitTransaction");
    }

    public void rollbackTransaction()
    {
        caller.dispatch(this,"rollbackTransaction");
    }

    public RemoteSession getRemoteSession() { return this; }
 //   public void setRemoteSession(RemoteSession session) {}

    public RemoteObjectCache getObjectCache() { return objectCache; }

    public Factory getFactory()
    { return (Factory) getRemoteElement("OME::Factory",
                                        "Factory"); }

    public Attribute getUser()
    { return getAttributeElement("User"); }

    public Project getProject()
    { return (Project) getRemoteElement("OME::Project",
                                        "project"); }
    public void setProject(Project project)
    { setRemoteElement("project",project); }

    public Dataset getDataset()
    { return (Dataset) getRemoteElement("OME::Dataset",
                                        "dataset"); }
    public void setDataset(Dataset dataset)
    { setRemoteElement("dataset",dataset); }

    protected boolean chainManagerLoaded = false;
    protected ChainManager cachedChainManager = null;

    public ChainManager getChainManager()
    {
        if (!chainManagerLoaded)
        {
            Object reference = caller.dispatch("OME::Tasks::ChainManager",
                                               "new",
                                               this);

            cachedChainManager = (ChainManager)
                getObjectCache().getObject("OME::Tasks::ChainManager",
                                           (String) reference);
            chainManagerLoaded = true;
        }
        return cachedChainManager;
    }

    protected boolean projectManagerLoaded = false;
    protected ProjectManager cachedProjectManager = null;

    public ProjectManager getProjectManager()
    {
        if (!projectManagerLoaded)
        {
            Object reference = caller.dispatch("OME::Tasks::ProjectManager",
                                               "new");

            cachedProjectManager = (ProjectManager)
                getObjectCache().getObject("OME::Tasks::ProjectManager",
                                           (String) reference);
            projectManagerLoaded = true;
        }
        return cachedProjectManager;
    }

    protected boolean datasetManagerLoaded = false;
    protected DatasetManager cachedDatasetManager = null;

    public DatasetManager getDatasetManager()
    {
        if (!datasetManagerLoaded)
        {
            Object reference = caller.dispatch("OME::Tasks::DatasetManager",
                                               "new");

            cachedDatasetManager = (DatasetManager)
                getObjectCache().getObject("OME::Tasks::DatasetManager",
                                           (String) reference);
            datasetManagerLoaded = true;
        }
        return cachedDatasetManager;
    }
}
