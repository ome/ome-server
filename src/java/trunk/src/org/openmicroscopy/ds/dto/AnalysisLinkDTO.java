/*
 * org.openmicroscopy.ds.dto.AnalysisLinkDTO
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

public class AnalysisLinkDTO
    extends MappedDTO
    implements AnalysisLink
{
    public AnalysisLinkDTO() { super(); }
    public AnalysisLinkDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "AnalysisLink"; }
    public Class getDTOType() { return AnalysisLink.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public AnalysisChain getChain()
    { return (AnalysisChain) getObjectElement("analysis_chain"); }
    public void setChain(AnalysisChain value)
    { setElement("analysis_chain",value); }

    public AnalysisNode getFromNode()
    { return (AnalysisNode) getObjectElement("from_node"); }
    public void setFromNode(AnalysisNode value)
    { setElement("from_node",value); }

    public FormalOutput getFromOutput()
    { return (FormalOutput) getObjectElement("from_output"); }
    public void setFromOutput(FormalOutput value)
    { setElement("from_output",value); }

    public AnalysisNode getToNode()
    { return (AnalysisNode) getObjectElement("to_node"); }
    public void setToNode(AnalysisNode value)
    { setElement("to_node",value); }

    public FormalInput getToInput()
    { return (FormalInput) getObjectElement("to_input"); }
    public void setToInput(FormalInput value)
    { setElement("to_input",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("analysis_chain",AnalysisChainDTO.class);
        parseChildElement("from_node",AnalysisNodeDTO.class);
        parseChildElement("from_output",FormalOutputDTO.class);
        parseChildElement("to_node",AnalysisNodeDTO.class);
        parseChildElement("to_input",FormalInputDTO.class);
    }

}
