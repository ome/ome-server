/*
 * org.openmicroscopy.ds.dto.AnalysisPathDTO
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
 * Created by dcreager via omejava on Wed Feb 11 16:06:46 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.dto;

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class AnalysisPathDTO
    extends MappedDTO
    implements AnalysisPath
{
    public AnalysisPathDTO() { super(); }
    public AnalysisPathDTO(Map elements) { super(elements); }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public AnalysisChain getChain()
    { return (AnalysisChain) getObjectElement("analysis_chain"); }
    public void setChain(AnalysisChain value)
    { setElement("analysis_chain",value); }

    public int getLength()
    { return getIntElement("path_length"); }
    public void setLength(int value)
    { setElement("path_length",new Integer(value)); }

    public List getEntries()
    { return (List) getObjectElement("path_nodes"); }
    public int countEntries()
    { return countListElement("path_nodes"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("analysis_chain",AnalysisChainDTO.class);
        parseListElement("path_nodes",AnalysisPathEntryDTO.class);
    }

}
