/*
 * org.openmicroscopy.ds.st.ImageAnnotationDTO
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
 * Created by dcreager via omejava on Tue Mar 16 15:54:10 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Experimenter;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ImageAnnotationDTO
    extends AttributeDTO
    implements ImageAnnotation
{
    public ImageAnnotationDTO() { super(); }
    public ImageAnnotationDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@ImageAnnotation"; }
    public Class getDTOType() { return ImageAnnotation.class; }

    public Integer getTheZ()
    { return getIntegerElement("TheZ"); }
    public void setTheZ(Integer value)
    { setElement("TheZ",value); }

    public Integer getTheT()
    { return getIntegerElement("TheT"); }
    public void setTheT(Integer value)
    { setElement("TheT",value); }

    public Integer getTheC()
    { return getIntegerElement("TheC"); }
    public void setTheC(Integer value)
    { setElement("TheC",value); }

    public Long getTimestamp()
    { return getLongElement("Timestamp"); }
    public void setTimestamp(Long value)
    { setElement("Timestamp",value); }

    public String getContent()
    { return getStringElement("Content"); }
    public void setContent(String value)
    { setElement("Content",value); }

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
