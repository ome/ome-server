/*
 * org.openmicroscopy.ds.dto.FormalInputDTO
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

import org.openmicroscopy.ds.dto.MappedDTO;
import java.util.List;
import java.util.Map;

public class FormalInputDTO
    extends MappedDTO
    implements FormalInput
{
    public FormalInputDTO() { super(); }
    public FormalInputDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "FormalInput"; }
    public Class getDTOType() { return FormalInput.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public Module getModule()
    { return (Module) getObjectElement("module"); }
    public void setModule(Module value)
    { setElement("module",value); }

    public String getName()
    { return getStringElement("name"); }
    public void setName(String value)
    { setElement("name",value); }

    public String getDescription()
    { return getStringElement("description"); }
    public void setDescription(String value)
    { setElement("description",value); }

    public boolean isOptional()
    { return getBooleanElement("optional"); }
    public void setOptional(boolean value)
    { setElement("optional",new Boolean(value)); }

    public boolean isList()
    { return getBooleanElement("list"); }
    public void setList(boolean value)
    { setElement("list",new Boolean(value)); }

    public SemanticType getSemanticType()
    { return (SemanticType) getObjectElement("semantic_type"); }
    public void setSemanticType(SemanticType value)
    { setElement("semantic_type",value); }

    public LookupTable getLookupTable()
    { return (LookupTable) getObjectElement("lookup_table"); }
    public void setLookupTable(LookupTable value)
    { setElement("lookup_table",value); }

    public boolean isUserDefined()
    { return getBooleanElement("user_defined"); }
    public void setUserDefined(boolean value)
    { setElement("user_defined",new Boolean(value)); }

    public List getActualInputs()
    { return (List) getObjectElement("actual_inputs"); }
    public int countActualInputs()
    { return countListElement("actual_inputs"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("module",ModuleDTO.class);
        parseChildElement("semantic_type",SemanticTypeDTO.class);
        parseChildElement("lookup_table",LookupTableDTO.class);
        parseListElement("actual_inputs",ActualInputDTO.class);
    }

}
