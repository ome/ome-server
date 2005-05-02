/*
 * org.openmicroscopy.ds.st.PixelsPlane
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
 * Created by hochheiserha via omejava on Tue Mar 29 11:02:12 2005
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Repository;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface PixelsPlane
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>SizeY</code> */
    public Integer getSizeY();
    public void setSizeY(Integer value);

    /** Criteria field name: <code>SizeX</code> */
    public Integer getSizeX();
    public void setSizeX(Integer value);

    /** Criteria field name: <code>FileSHA1</code> */
    public String getFileSHA1();
    public void setFileSHA1(String value);

    /** Criteria field name: <code>Repository</code> */
    public Repository getRepository();
    public void setRepository(Repository value);

    /** Criteria field name: <code>PixelType</code> */
    public String getPixelType();
    public void setPixelType(String value);

}
