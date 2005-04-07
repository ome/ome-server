/*
 * org.openmicroscopy.ds.st.ImageInstrumentDTO
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
 * Created by hochheiserha via omejava on Thu Apr  7 10:47:04 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Instrument;
import org.openmicroscopy.ds.st.Objective;
import org.openmicroscopy.ds.dto.AttributeDTO;
import java.util.List;
import java.util.Map;

public class ImageInstrumentDTO
    extends AttributeDTO
    implements ImageInstrument
{
    public ImageInstrumentDTO() { super(); }
    public ImageInstrumentDTO(Map elements) { super(elements); }

    public String getDTOTypeName() { return "@ImageInstrument"; }
    public Class getDTOType() { return ImageInstrument.class; }

    public Instrument getInstrument()
    { return (Instrument) parseChildElement("Instrument",InstrumentDTO.class); }
    public void setInstrument(Instrument value)
    { setElement("Instrument",value); }

    public Objective getObjective()
    { return (Objective) parseChildElement("Objective",ObjectiveDTO.class); }
    public void setObjective(Objective value)
    { setElement("Objective",value); }


}
