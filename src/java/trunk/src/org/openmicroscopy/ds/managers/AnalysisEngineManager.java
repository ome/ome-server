/*
 * org.openmicroscopy.ds.managers.AnalysisEngineManager
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

import java.util.Map;

import org.openmicroscopy.ds.RemoteServices;
import org.openmicroscopy.ds.RemoteCaller;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.DataException;
import org.openmicroscopy.ds.dto.AnalysisChain;
import org.openmicroscopy.ds.dto.Dataset;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class AnalysisEngineManager
    extends AbstractService
{
    public AnalysisEngineManager() { super(); }

    public void executeAnalysisChain(AnalysisChain chain, Dataset dataset)
    {
        if (chain == null)
            throw new IllegalArgumentException("Chain cannot be null");
        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");

        Integer chainID = null;
        Integer datasetID = null;

        try
        {
            chainID = new Integer(chain.getID());
        } catch (DataException e) {
            throw new IllegalArgumentException("Chain must be in the database");
        }

        try
        {
            datasetID = new Integer(dataset.getID());
        } catch (DataException e) {
            throw new IllegalArgumentException("Chain must be in the database");
        }

        caller.dispatch("executeAnalysisChain",
                        new Object[] {
                            chainID, datasetID
                        });
    }

}