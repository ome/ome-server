/*
 * org.openmicroscopy.remote.managers.RemoteProjectManager
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




package org.openmicroscopy.remote.managers;

import org.openmicroscopy.*;
import org.openmicroscopy.managers.ProjectManager;
import org.openmicroscopy.remote.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

/**
 * A Remote framework implementation of the {@link ProjectManager}
 * interface.
 *
 * @author Douglas Creager
 * @version 2.1
 * @since OME2.1
 */
public class RemoteProjectManager
    extends RemoteObject
    implements ProjectManager
{
    static
    {
        RemoteObjectCache.addClass("OME::Tasks::ProjectManager",
                                   RemoteProjectManager.class);
    }

    public RemoteProjectManager() { super(); }
    public RemoteProjectManager(RemoteSession session, String reference)
    { super(session,reference); }

    /**
     * Returns the {@link Session} that this <code>ProjectManager</code>
     * corresponds to.
     * @return the {@link Session} that this <code>ProjectManager</code>
     * corresponds to.
     */
    public Session getSession() { return getRemoteSession(); }

    /**
     * Adds a {@link Dataset} to the given {@link Project}.
     * @param project the project to add the dataset to
     * @param dataset the dataset to add
     */
    public void addDataset(Project project, Dataset dataset)
    {
        Object o = caller.dispatch(this,"addDatasetToProject",
                                   new Object[] { dataset, project });
    }

    /**
     * Adds a {@link Dataset} to the session's current {@link Project}
     * @param dataset the dataset to add
     */
    public void addDataset(Dataset dataset)
    {
        Object o = caller.dispatch(this,"addDatasetToCurrentProject",dataset);
    }

}