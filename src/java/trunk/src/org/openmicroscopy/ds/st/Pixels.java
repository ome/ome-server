/*
 * org.openmicroscopy.ds.st.Pixels
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
 * Created by dcreager via omejava on Thu Feb 12 14:35:08 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.ChannelIndex;
import org.openmicroscopy.ds.st.DisplayOptions;
import org.openmicroscopy.ds.st.PixelChannelComponent;
import org.openmicroscopy.ds.st.Repository;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Pixels
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>SizeX</code> */
    public int getSizeX();
    public void setSizeX(int value);

    /** Criteria field name: <code>SizeY</code> */
    public int getSizeY();
    public void setSizeY(int value);

    /** Criteria field name: <code>SizeZ</code> */
    public int getSizeZ();
    public void setSizeZ(int value);

    /** Criteria field name: <code>SizeC</code> */
    public int getSizeC();
    public void setSizeC(int value);

    /** Criteria field name: <code>SizeT</code> */
    public int getSizeT();
    public void setSizeT(int value);

    /** Criteria field name: <code>BitsPerPixel</code> */
    public int getBitsPerPixel();
    public void setBitsPerPixel(int value);

    /** Criteria field name: <code>PixelType</code> */
    public String getPixelType();
    public void setPixelType(String value);

    /** Criteria field name: <code>FileSHA1</code> */
    public String getFileSHA1();
    public void setFileSHA1(String value);

    /** Criteria field name: <code>Repository</code> */
    public Repository getRepository();
    public void setRepository(Repository value);

    /** Criteria field name: <code>Path</code> */
    public String getPath();
    public void setPath(String value);

    /** Criteria field name: <code>PixelsID</code> */
    public int getPixelsID();
    public void setPixelsID(int value);

    /** Criteria field name: <code>ChannelIndexes</code> */
    public List getChannelIndexes();
    /** Criteria field name: <code>#ChannelIndexes</code> */
    public int countChannelIndexes();

    /** Criteria field name: <code>DisplayOptionses</code> */
    public List getDisplayOptionses();
    /** Criteria field name: <code>#DisplayOptionses</code> */
    public int countDisplayOptionses();

    /** Criteria field name: <code>PixelChannelComponents</code> */
    public List getPixelChannelComponents();
    /** Criteria field name: <code>#PixelChannelComponents</code> */
    public int countPixelChannelComponents();

}
