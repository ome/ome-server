/*
 * org.openmicroscopy.ds.managers.DatasetManager
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


package org.openmicroscopy.ds.managers;

import java.util.Iterator;
import java.util.Map;
import java.util.List;
import java.util.ArrayList;

import org.openmicroscopy.ds.RemoteServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Image;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class DatasetManager
    extends AbstractService
{
    public DatasetManager() { super(); }

    /**
     * Creates a new <code>DatasetManager</code> which communicates
     * with a data server using the specified {@link RemoteCaller}.
     * This {@link RemoteCaller} is first wrapped in an instance of
     * {@link InstantiatingCaller}.
     */
    public DatasetManager(RemoteCaller caller)
    {
        super();
        initializeService(RemoteServices.getInstance(caller));
    }

    /**
     * Adds a {@link Image} to a {@link Dataset}.  If the image
     * already belongs to that dataset, nothing happens.
     */
    public void addImageToDataset(Dataset dataset, Image image)
    {
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");
        if (image == null)
            throw new IllegalArgumentException("Image cannot be null");

        caller.dispatch("addImagesToDataset",
                        new Object[] {
                            new Integer(dataset.getID()),
                            new Integer(image.getID())
                        });
    }

    /**
     * Adds a {@link Image} to a {@link Dataset}.  If the image
     * already belongs to that dataset, nothing happens.
     */
    public void addImageToDataset(int datasetID, int imageID)
    {
        caller.dispatch("addImagesToDataset",
                        new Object[] {
                            new Integer(datasetID),
                            new Integer(imageID)
                        });
    }

    /**
     * Adds a {@link List} of {@link Image}s to a {@link Dataset}.  If
     * the image already belongs to that dataset, nothing happens.
     */
    public void addImagesToDataset(Dataset dataset, List images)
    {
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");
        if (images == null)
            throw new IllegalArgumentException("Images cannot be null");

        List list = new ArrayList(images.size());
        Iterator it = images.iterator();
        while (it.hasNext())
        {
            Object o = it.next();
            if (o instanceof Image)
                list.add(new Integer(((Image) o).getID()));
            else
                throw new IllegalArgumentException("List must contain Images");
        }
 
        caller.dispatch("addImagesToDataset",
                        new Object[] {
                            new Integer(dataset.getID()),
                            list
                        });
    }

    /**
     * Adds a {@link List} of {@link Image}s to a {@link Dataset}.  If
     * the image already belongs to that dataset, nothing happens.
     */
    public void addImagesToDataset(int datasetID, List imageIDs)
    {
        if (imageIDs == null)
            throw new IllegalArgumentException("Image IDs cannot be null");

        caller.dispatch("addImagesToDataset",
                        new Object[] {
                            new Integer(datasetID),
                            imageIDs
                        });
    }

    /**
     * Removes a {@link Image} from a {@link Dataset}.  If the image
     * doesn't belongs to that dataset, nothing happens.
     */
    public void removeImageFromDataset(Dataset dataset, Image image)
    {
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");
        if (image == null)
            throw new IllegalArgumentException("Image cannot be null");

        caller.dispatch("removeImagesFromDataset",
                        new Object[] {
                            new Integer(dataset.getID()),
                            new Integer(image.getID())
                        });
    }

    /**
     * Removes a {@link Image} from a {@link Dataset}.  If the image
     * doesn't belongs to that dataset, nothing happens.
     */
    public void removeImageFromDataset(int datasetID, int imageID)
    {
        caller.dispatch("removeImagesFromDataset",
                        new Object[] {
                            new Integer(datasetID),
                            new Integer(imageID)
                        });
    }

    /**
     * Removes a {@link List} of {@link Image}s from a {@link
     * Dataset}.  If the image doesn't belongs to that dataset,
     * nothing happens.
     */
    public void removeImagesFromDataset(Dataset dataset, List images)
    {
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");
        if (images == null)
            throw new IllegalArgumentException("Images cannot be null");

        List list = new ArrayList(images.size());
        Iterator it = images.iterator();
        while (it.hasNext())
        {
            Object o = it.next();
            if (o instanceof Image)
                list.add(new Integer(((Image) o).getID()));
            else
                throw new IllegalArgumentException("List must contain Images");
        }
 
        caller.dispatch("removeImagesFromDataset",
                        new Object[] {
                            new Integer(dataset.getID()),
                            list
                        });
    }

    /**
     * Removes a {@link List} of {@link Image}s from a {@link
     * Dataset}.  If the image doesn't belongs to that dataset,
     * nothing happens.
     */
    public void removeImagesFromDataset(int datasetID, List imageIDs)
    {
        if (imageIDs == null)
            throw new IllegalArgumentException("Image IDs cannot be null");

        caller.dispatch("removeImagesFromDataset",
                        new Object[] {
                            new Integer(datasetID),
                            imageIDs
                        });
    }

}
