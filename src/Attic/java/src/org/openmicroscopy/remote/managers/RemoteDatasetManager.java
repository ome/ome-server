/*
 * org.openmicroscopy.remote.managers.RemoteDatasetManager
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
import org.openmicroscopy.managers.DatasetManager;
import org.openmicroscopy.remote.*;
import java.util.List;
import java.util.ArrayList;
import java.util.Iterator;

/**
 * A Remote framework implementation of the {@link DatasetManager}
 * interface.
 *
 * @author Douglas Creager
 * @version 2.1
 * @since OME2.1
 */
public class RemoteDatasetManager
    extends RemoteObject
    implements DatasetManager
{
    static
    {
        RemoteObjectCache.addClass("OME::Tasks::DatasetManager",
                                   RemoteDatasetManager.class);
    }

    public RemoteDatasetManager() { super(); }
    public RemoteDatasetManager(RemoteSession session, String reference)
    { super(session,reference); }

    /**
     * Returns the {@link Session} that this <code>DatasetManager</code>
     * corresponds to.
     * @return the {@link Session} that this <code>DatasetManager</code>
     * corresponds to.
     */
    public Session getSession() { return getRemoteSession(); }

    /**
     * Adds an {@link Image} to the given {@link Dataset}.
     * @param dataset the dataset to add the dataset to
     * @param dataset the dataset to add
     */
    public void addImage(Dataset dataset, Image image)
    {
        Object o = caller.dispatch(this,"addImageToDataset",
                                   new Object[] { dataset, image });
    }

    /**
     * Adds an {@link Image} to the session's current {@link Dataset}
     * @param dataset the dataset to add
     */
    public void addImage(Image dataset)
    {
        Object o = caller.dispatch(this,"addImageToCurrentDataset",dataset);
    }

}