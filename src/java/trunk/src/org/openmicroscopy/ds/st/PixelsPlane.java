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
 * Created by dcreager via omejava on Wed Feb 11 16:08:00 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.Repository;
import java.util.List;
import java.util.Map;

public interface PixelsPlane
    extends Attribute
{
    /** Criteria field name: <code>SizeX</code> */
    public int getSizeX();
    public void setSizeX(int value);

    /** Criteria field name: <code>SizeY</code> */
    public int getSizeY();
    public void setSizeY(int value);

    /** Criteria field name: <code>PixelType</code> */
    public String getPixelType();
    public void setPixelType(String value);

    /** Criteria field name: <code>FileSHA1</code> */
    public String getFileSHA1();
    public void setFileSHA1(String value);

    /** Criteria field name: <code>BitsPerPixel</code> */
    public int getBitsPerPixel();
    public void setBitsPerPixel(int value);

    /** Criteria field name: <code>Repository</code> */
    public Repository getRepository();
    public void setRepository(Repository value);

    /** Criteria field name: <code>Path</code> */
    public String getPath();
    public void setPath(String value);

}
