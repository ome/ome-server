/*
 * org.openmicroscopy.ds.st.RenderingSettingsDTO
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
 * Created by dcreager via omejava on Fri Sep 10 11:22:49 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class RenderingSettingsDTO
    extends AttributeDTO
    implements RenderingSettings
{
    public RenderingSettingsDTO() { super(); }
    public RenderingSettingsDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@RenderingSettings"; }
    public Class getDTOType() { return RenderingSettings.class; }

    public Boolean isActive()
    { return getBooleanElement("Active"); }
    public void setActive(Boolean value)
    { setElement("Active",value); }

    public Integer getAlpha()
    { return getIntegerElement("Alpha"); }
    public void setAlpha(Integer value)
    { setElement("Alpha",value); }

    public Integer getBlue()
    { return getIntegerElement("Blue"); }
    public void setBlue(Integer value)
    { setElement("Blue",value); }

    public Integer getGreen()
    { return getIntegerElement("Green"); }
    public void setGreen(Integer value)
    { setElement("Green",value); }

    public Integer getRed()
    { return getIntegerElement("Red"); }
    public void setRed(Integer value)
    { setElement("Red",value); }

    public Double getInputEnd()
    { return getDoubleElement("InputEnd"); }
    public void setInputEnd(Double value)
    { setElement("InputEnd",value); }

    public Double getInputStart()
    { return getDoubleElement("InputStart"); }
    public void setInputStart(Double value)
    { setElement("InputStart",value); }

    public Integer getTheC()
    { return getIntegerElement("TheC"); }
    public void setTheC(Integer value)
    { setElement("TheC",value); }

    public Integer getBitResolution()
    { return getIntegerElement("BitResolution"); }
    public void setBitResolution(Integer value)
    { setElement("BitResolution",value); }

    public Integer getCdEnd()
    { return getIntegerElement("CdEnd"); }
    public void setCdEnd(Integer value)
    { setElement("CdEnd",value); }

    public Integer getCdStart()
    { return getIntegerElement("CdStart"); }
    public void setCdStart(Integer value)
    { setElement("CdStart",value); }

    public Double getCoefficient()
    { return getDoubleElement("Coefficient"); }
    public void setCoefficient(Double value)
    { setElement("Coefficient",value); }

    public Integer getFamily()
    { return getIntegerElement("Family"); }
    public void setFamily(Integer value)
    { setElement("Family",value); }

    public Integer getModel()
    { return getIntegerElement("Model"); }
    public void setModel(Integer value)
    { setElement("Model",value); }

    public Integer getTheT()
    { return getIntegerElement("TheT"); }
    public void setTheT(Integer value)
    { setElement("TheT",value); }

    public Integer getTheZ()
    { return getIntegerElement("TheZ"); }
    public void setTheZ(Integer value)
    { setElement("TheZ",value); }

    public Experimenter getExperimenter()
    { return (Experimenter) getObjectElement("Experimenter"); }
    public void setExperimenter(Experimenter value)
    { setElement("Experimenter",value); }

    public void setMap(Map elements)
    {
        super.setMap(elements);
        parseChildElement("Experimenter",ExperimenterDTO.class);
    }

}
