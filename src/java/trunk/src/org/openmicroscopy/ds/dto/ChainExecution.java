/*
 * org.openmicroscopy.ds.dto.ChainExecution
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003-2004 Open Microscopy Environment
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
 * THIS IS AUTOMATICALLY GENERATED CODE.  DO NOT MODIFY.
 * Created by dcreager via omejava on Tue Feb 24 17:23:09 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.st.ExperimenterDTO;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface ChainExecution
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>analysis_chain</code> */
    public AnalysisChain getChain();
    public void setChain(AnalysisChain value);

    /** Criteria field name: <code>dataset</code> */
    public Dataset getDataset();
    public void setDataset(Dataset value);

    /** Criteria field name: <code>timestamp</code> */
    public String getTimestamp();
    public void setTimestamp(String value);

    /** Criteria field name: <code>experimenter</code> */
    public Experimenter getExperimenter();
    public void setExperimenter(Experimenter value);

    /** Criteria field name: <code>node_executions</code> */
    public List getNodeExecutions();
    /** Criteria field name: <code>#node_executions</code> or <code>node_executions</code> */
    public int countNodeExecutions();

}
