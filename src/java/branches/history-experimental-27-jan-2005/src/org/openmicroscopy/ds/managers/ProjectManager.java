/*
 * org.openmicroscopy.ds.managers.ProjectManager
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

import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.dto.Project;
import org.openmicroscopy.ds.dto.Dataset;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class ProjectManager
    extends AbstractService
{
    public ProjectManager() { super(); }

    /**
     * Creates a new <code>ProjectManager</code> which communicates
     * with a data server using the specified {@link RemoteCaller}.
     * This {@link RemoteCaller} is first wrapped in an instance of
     * {@link InstantiatingCaller}.
     */
    public ProjectManager(RemoteCaller caller)
    {
        super();
        initializeService(DataServices.getInstance(caller));
    }

    /**
     * Adds a {@link Dataset} to a {@link Project}.  If the dataset
     * already belongs to that project, nothing happens.
     */
    public void addDatasetToProject(Project project, Dataset dataset)
    {
        if (project == null)
            throw new IllegalArgumentException("Project cannot be null");
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");

        caller.dispatch("addDatasetsToProject",
                        new Object[] {
                            new Integer(project.getID()),
                            new Integer(dataset.getID())
                        });
    }

    /**
     * Adds a {@link Dataset} to a {@link Project}.  If the dataset
     * already belongs to that project, nothing happens.
     */
    public void addDatasetToProject(int projectID, int datasetID)
    {
        caller.dispatch("addDatasetsToProject",
                        new Object[] {
                            new Integer(projectID),
                            new Integer(datasetID)
                        });
    }

    /**
     * Adds a {@link List} of {@link Dataset}s to a {@link Project}.
     * If the dataset already belongs to that project, nothing
     * happens.
     */
    public void addDatasetsToProject(Project project, List datasets)
    {
        if (project == null)
            throw new IllegalArgumentException("Project cannot be null");
        if (datasets == null)
            throw new IllegalArgumentException("Datasets cannot be null");

        List list = new ArrayList(datasets.size());
        Iterator it = datasets.iterator();
        while (it.hasNext())
        {
            Object o = it.next();
            if (o instanceof Dataset)
                list.add(new Integer(((Dataset) o).getID()));
            else
                throw new IllegalArgumentException("List must contain Datasets");
        }
 
        caller.dispatch("addDatasetsToProject",
                        new Object[] {
                            new Integer(project.getID()),
                            list
                        });
    }

    /**
     * Adds a {@link List} of {@link Dataset}s to a {@link Project}.
     * If the dataset already belongs to that project, nothing
     * happens.
     */
    public void addDatasetsToProject(int projectID, List datasetIDs)
    {
        if (datasetIDs == null)
            throw new IllegalArgumentException("Dataset IDs cannot be null");

        caller.dispatch("addDatasetsToProject",
                        new Object[] {
                            new Integer(projectID),
                            datasetIDs
                        });
    }

    /**
     * Adds a {@link Dataset} to a {@link List} of {@link Project}s.
     * No error is thrown if the dataset already belongs to any of the
     * projects.
     */
    public void addDatasetToProjects(List projects, Dataset dataset)
    {
        if (projects == null)
            throw new IllegalArgumentException("Project cannot be null");
        if (dataset == null)
            throw new IllegalArgumentException("Datasets cannot be null");

        List list = new ArrayList(projects.size());
        Iterator it = projects.iterator();
        while (it.hasNext())
        {
            Object o = it.next();
            if (o instanceof Project)
                list.add(new Integer(((Project) o).getID()));
            else
                throw new IllegalArgumentException("List must contain Projects");
        }
 
        caller.dispatch("addDatasetToProjects",
                        new Object[] {
                            list,
                            new Integer(dataset.getID())
                        });
    }

    /**
     * Adds a {@link Dataset} to a {@link List} of {@link Project}s.
     * No error is thrown if the dataset already belongs to any of the
     * projects.
     */
    public void addDatasetToProjects(List projectIDs, int datasetID)
    {
        if (projectIDs == null)
            throw new IllegalArgumentException("Project IDs cannot be null");

        caller.dispatch("addDatasetToProjects",
                        new Object[] {
                            projectIDs,
                            new Integer(datasetID),
                        });
    }

    /**
     * Removes a {@link Dataset} from a {@link Project}.  If the
     * dataset doesn't belongs to that project, nothing happens.
     */
    public void removeDatasetFromProject(Project project, Dataset dataset)
    {
        if (project == null)
            throw new IllegalArgumentException("Project cannot be null");
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");

        caller.dispatch("removeDatasetsFromProject",
                        new Object[] {
                            new Integer(project.getID()),
                            new Integer(dataset.getID())
                        });
    }

    /**
     * Removes a {@link Dataset} from a {@link Project}.  If the
     * dataset doesn't belongs to that project, nothing happens.
     */
    public void removeDatasetFromProject(int projectID, int datasetID)
    {
        caller.dispatch("removeDatasetsFromProject",
                        new Object[] {
                            new Integer(projectID),
                            new Integer(datasetID)
                        });
    }

    /**
     * Removes a {@link List} of {@link Dataset}s from a {@link
     * Project}.  If the dataset doesn't belongs to that project,
     * nothing happens.
     */
    public void removeDatasetsFromProject(Project project, List datasets)
    {
        if (project == null)
            throw new IllegalArgumentException("Project cannot be null");
        if (datasets == null)
            throw new IllegalArgumentException("Datasets cannot be null");

        List list = new ArrayList(datasets.size());
        Iterator it = datasets.iterator();
        while (it.hasNext())
        {
            Object o = it.next();
            if (o instanceof Dataset)
                list.add(new Integer(((Dataset) o).getID()));
            else
                throw new IllegalArgumentException("List must contain Datasets");
        }
 
        caller.dispatch("removeDatasetsFromProject",
                        new Object[] {
                            new Integer(project.getID()),
                            list
                        });
    }

    /**
     * Removes a {@link List} of {@link Dataset}s from a {@link
     * Project}.  If the dataset doesn't belongs to that project,
     * nothing happens.
     */
    public void removeDatasetsFromProject(int projectID, List datasetIDs)
    {
        if (datasetIDs == null)
            throw new IllegalArgumentException("Dataset IDs cannot be null");

        caller.dispatch("removeDatasetsFromProject",
                        new Object[] {
                            new Integer(projectID),
                            datasetIDs
                        });
    }

}
