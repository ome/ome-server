/*
 * org.openmicroscopy.ds.dto.AnalysisPathEntryDTO
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

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class AnalysisPathEntryDTO
    extends MappedDTO
    implements AnalysisPathEntry
{
    public AnalysisPathEntryDTO() { super(); }
    public AnalysisPathEntryDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "AnalysisPathEntry"; }
    public Class getDTOType() { return AnalysisPathEntry.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public AnalysisPath getPath()
    { return (AnalysisPath) getObjectElement("path"); }
    public void setPath(AnalysisPath value)
    { setElement("path",value); }

    public Integer getOrder()
    { return getIntegerElement("path_order"); }
    public void setOrder(Integer value)
    { setElement("path_order",value); }

    public AnalysisNode getNode()
    { return (AnalysisNode) getObjectElement("analysis_chain_node"); }
    public void setNode(AnalysisNode value)
    { setElement("analysis_chain_node",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("path",AnalysisPathDTO.class);
        parseChildElement("analysis_chain_node",AnalysisNodeDTO.class);
    }

}
