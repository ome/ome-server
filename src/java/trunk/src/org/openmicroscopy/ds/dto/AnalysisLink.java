/*
 * org.openmicroscopy.ds.dto.AnalysisLink
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
 * Created by dcreager via omejava on Thu Feb 12 14:34:47 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface AnalysisLink
    extends DataInterface
{
    /** Criteria field name: <code>id</code> */
    public int getID();
    public void setID(int value);

    /** Criteria field name: <code>analysis_chain</code> */
    public AnalysisChain getChain();
    public void setChain(AnalysisChain value);

    /** Criteria field name: <code>from_node</code> */
    public AnalysisNode getFromNode();
    public void setFromNode(AnalysisNode value);

    /** Criteria field name: <code>from_output</code> */
    public FormalOutput getFromOutput();
    public void setFromOutput(FormalOutput value);

    /** Criteria field name: <code>to_node</code> */
    public AnalysisNode getToNode();
    public void setToNode(AnalysisNode value);

    /** Criteria field name: <code>to_input</code> */
    public FormalInput getToInput();
    public void setToInput(FormalInput value);

}
