/*
 * org.openmicroscopy.ds.st.Repository
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
 * Created by dcreager via omejava on Tue Feb 24 17:23:14 2004
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.ds.st;

import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.st.OTF;
import org.openmicroscopy.ds.st.OriginalFile;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.st.PixelsPlane;
import org.openmicroscopy.ds.st.Thumbnail;
import org.openmicroscopy.ds.dto.DataInterface;
import java.util.List;
import java.util.Map;

public interface Repository
    extends DataInterface, Attribute
{
    /** Criteria field name: <code>Local</code> */
    public Boolean isLocal();
    public void setLocal(Boolean value);

    /** Criteria field name: <code>Path</code> */
    public String getPath();
    public void setPath(String value);

    /** Criteria field name: <code>ImageServerURL</code> */
    public String getImageServerURL();
    public void setImageServerURL(String value);

    /** Criteria field name: <code>OTFs</code> */
    public List getOTFs();
    /** Criteria field name: <code>#OTFs</code> or <code>OTFs</code> */
    public int countOTFs();

    /** Criteria field name: <code>OriginalFiles</code> */
    public List getOriginalFiles();
    /** Criteria field name: <code>#OriginalFiles</code> or <code>OriginalFiles</code> */
    public int countOriginalFiles();

    /** Criteria field name: <code>Pixelses</code> */
    public List getPixelses();
    /** Criteria field name: <code>#Pixelses</code> or <code>Pixelses</code> */
    public int countPixelses();

    /** Criteria field name: <code>PixelsPlanes</code> */
    public List getPixelsPlanes();
    /** Criteria field name: <code>#PixelsPlanes</code> or <code>PixelsPlanes</code> */
    public int countPixelsPlanes();

    /** Criteria field name: <code>Thumbnails</code> */
    public List getThumbnails();
    /** Criteria field name: <code>#Thumbnails</code> or <code>Thumbnails</code> */
    public int countThumbnails();

}
