/*
 * org.openmicroscopy.ds.dto.ActualInputDTO
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

public class ActualInputDTO
    extends MappedDTO
    implements ActualInput
{
    public ActualInputDTO() { super(); }
    public ActualInputDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "ActualInput"; }
    public Class getDTOType() { return ActualInput.class; }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public ModuleExecution getModuleExecution()
    { return (ModuleExecution) getObjectElement("module_execution"); }
    public void setModuleExecution(ModuleExecution value)
    { setElement("module_execution",value); }

    public FormalInput getFormalInput()
    { return (FormalInput) getObjectElement("formal_input"); }
    public void setFormalInput(FormalInput value)
    { setElement("formal_input",value); }

    public ModuleExecution getInputMEX()
    { return (ModuleExecution) getObjectElement("input_module_execution"); }
    public void setInputMEX(ModuleExecution value)
    { setElement("input_module_execution",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("module_execution",ModuleExecutionDTO.class);
        parseChildElement("formal_input",FormalInputDTO.class);
        parseChildElement("input_module_execution",ModuleExecutionDTO.class);
    }

}
