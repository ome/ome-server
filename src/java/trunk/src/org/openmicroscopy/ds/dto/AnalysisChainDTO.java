/*
 * org.openmicroscopy.ds.dto.AnalysisChainDTO
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
import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class AnalysisChainDTO
    extends MappedDTO
    implements AnalysisChain
{
    public AnalysisChainDTO() { super(); }
    public AnalysisChainDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "AnalysisChain"; }
    public Class getDTOType() { return AnalysisChain.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public Experimenter getOwner()
    { return (Experimenter) getObjectElement("owner"); }
    public void setOwner(Experimenter value)
    { setElement("owner",value); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public Boolean isLocked()
    { return getBooleanElement("locked"); }
    public void setLocked(Boolean value)
    { setElement("locked",value); }

    public List getNodes()
    { return (List) getObjectElement("nodes"); }
    public int countNodes()
    { return countListElement("nodes"); }

    public List getLinks()
    { return (List) getObjectElement("links"); }
    public int countLinks()
    { return countListElement("links"); }

    public List getPaths()
    { return (List) getObjectElement("paths"); }
    public int countPaths()
    { return countListElement("paths"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("owner",ExperimenterDTO.class);
        parseListElement("nodes",AnalysisNodeDTO.class);
        parseListElement("links",AnalysisLinkDTO.class);
        parseListElement("paths",AnalysisPathDTO.class);
    }

}
