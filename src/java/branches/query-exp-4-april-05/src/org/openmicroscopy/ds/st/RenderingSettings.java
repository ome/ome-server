/*
 * org.openmicroscopy.ds.st.RenderingSettings
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:09 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface RenderingSettings
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Experimenter</code> */
    public Experimenter getExperimenter();
    public void setExperimenter(Experimenter value);

    /** Criteria field name: <code>TheZ</code> */
    public Integer getTheZ();
    public void setTheZ(Integer value);

    /** Criteria field name: <code>TheT</code> */
    public Integer getTheT();
    public void setTheT(Integer value);

    /** Criteria field name: <code>Model</code> */
    public Integer getModel();
    public void setModel(Integer value);

    /** Criteria field name: <code>Family</code> */
    public Integer getFamily();
    public void setFamily(Integer value);

    /** Criteria field name: <code>Coefficient</code> */
    public Double getCoefficient();
    public void setCoefficient(Double value);

    /** Criteria field name: <code>CdStart</code> */
    public Integer getCdStart();
    public void setCdStart(Integer value);

    /** Criteria field name: <code>CdEnd</code> */
    public Integer getCdEnd();
    public void setCdEnd(Integer value);

    /** Criteria field name: <code>BitResolution</code> */
    public Integer getBitResolution();
    public void setBitResolution(Integer value);

    /** Criteria field name: <code>TheC</code> */
    public Integer getTheC();
    public void setTheC(Integer value);

    /** Criteria field name: <code>InputStart</code> */
    public Double getInputStart();
    public void setInputStart(Double value);

    /** Criteria field name: <code>InputEnd</code> */
    public Double getInputEnd();
    public void setInputEnd(Double value);

    /** Criteria field name: <code>Red</code> */
    public Integer getRed();
    public void setRed(Integer value);

    /** Criteria field name: <code>Green</code> */
    public Integer getGreen();
    public void setGreen(Integer value);

    /** Criteria field name: <code>Blue</code> */
    public Integer getBlue();
    public void setBlue(Integer value);

    /** Criteria field name: <code>Alpha</code> */
    public Integer getAlpha();
    public void setAlpha(Integer value);

    /** Criteria field name: <code>Active</code> */
    public Boolean isActive();
    public void setActive(Boolean value);

}
