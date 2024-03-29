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
 * Created by hochheiserha via omejava on Mon May  2 15:18:38 2005
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
    { return (Module) parseChildElement("module",ModuleDTO.class); }
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

    public Boolean isOptional()
    { return getBooleanElement("optional"); }
    public void setOptional(Boolean value)
    { setElement("optional",value); }

    public Boolean isList()
    { return getBooleanElement("list"); }
    public void setList(Boolean value)
    { setElement("list",value); }

    public SemanticType getSemanticType()
    { return (SemanticType) parseChildElement("semantic_type",SemanticTypeDTO.class); }
    public void setSemanticType(SemanticType value)
    { setElement("semantic_type",value); }

    public LookupTable getLookupTable()
    { return (LookupTable) parseChildElement("lookup_table",LookupTableDTO.class); }
    public void setLookupTable(LookupTable value)
    { setElement("lookup_table",value); }

    public Boolean isUserDefined()
    { return getBooleanElement("user_defined"); }
    public void setUserDefined(Boolean value)
    { setElement("user_defined",value); }

    public List getActualInputs()
    { return (List) parseListElement("actual_inputs",ActualInputDTO.class); }
    public int countActualInputs()
    { return countListElement("actual_inputs"); }


}
