/*
 * org.openmicroscopy.ds.dto.ModuleExecutionDTO
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

public class ModuleExecutionDTO
    extends MappedDTO
    implements ModuleExecution
{
    public ModuleExecutionDTO() { super(); }
    public ModuleExecutionDTO(Map elements) { super(elements); }

    public int getID()
    { return getIntElement("id"); }
    public void setID(int value)
    { setElement("id",new Integer(value)); }

    public Module getModule()
    { return (Module) getObjectElement("module"); }
    public void setModule(Module value)
    { setElement("module",value); }

    public boolean isVirtual()
    { return getBooleanElement("virtual_mex"); }
    public void setVirtual(boolean value)
    { setElement("virtual_mex",new Boolean(value)); }

    public String getDependence()
    { return getStringElement("dependence"); }
    public void setDependence(String value)
    { setElement("dependence",value); }

    public Dataset getDataset()
    { return (Dataset) getObjectElement("dataset"); }
    public void setDataset(Dataset value)
    { setElement("dataset",value); }

    public Image getImage()
    { return (Image) getObjectElement("image"); }
    public void setImage(Image value)
    { setElement("image",value); }

    public String getIteratorTag()
    { return getStringElement("iterator_tag"); }
    public void setIteratorTag(String value)
    { setElement("iterator_tag",value); }

    public String getNewFeatureTag()
    { return getStringElement("new_feature_tag"); }
    public void setNewFeatureTag(String value)
    { setElement("new_feature_tag",value); }

    public String getInputTag()
    { return getStringElement("input_tag"); }
    public void setInputTag(String value)
    { setElement("input_tag",value); }

    public String getTimestamp()
    { return getStringElement("timestamp"); }
    public void setTimestamp(String value)
    { setElement("timestamp",value); }

    public float getTotalTime()
    { return getFloatElement("total_time"); }
    public void setTotalTime(float value)
    { setElement("total_time",new Float(value)); }

    public String getStatus()
    { return getStringElement("status"); }
    public void setStatus(String value)
    { setElement("status",value); }

    public String getErrorMessage()
    { return getStringElement("error_message"); }
    public void setErrorMessage(String value)
    { setElement("error_message",value); }

    public List getInputs()
    { return (List) getObjectElement("inputs"); }
    public int countInputs()
    { return countListElement("inputs"); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("module",ModuleDTO.class);
        parseChildElement("dataset",DatasetDTO.class);
        parseChildElement("image",ImageDTO.class);
        parseListElement("inputs",ActualInputDTO.class);
    }

}
