/*
 * org.openmicroscopy.Feature
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
 *      Massachusetts Institue of Technology,
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */




package org.openmicroscopy;

import java.util.List;
import java.util.Iterator;

/**
 * <p>Represents analytic subdivisions of an {@link Image}.  Often,
 * features will correspond to actual pixel regions within an image,
 * specified by a coordinate bounds or image mask.  However, this does
 * not have to be the case; features can be entirely logical divisions
 * in an image.  In a practical sense, they are just used to group
 * attributes which, together, refer to the same portion of an image,
 * but not to the image as a whole.</p>
 *
 * <p>The features of an image form a tree, with the image itself at
 * the root.  (Features right below the image in the tree will have
 * <code>null</code> for their parent feature link.)  Features also
 * have a tag, which allows similar kinds of features (cells, nuclei,
 * etc.) to be grouped for anaylsis.</p>
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 */

public interface Feature
    extends OMEObject
{
    /**
     * Returns the name of this feature.
     * @return the name of this feature
     */
    public String getName();

    /**
     * Sets the name of this feature.
     * @param name the name of this feature
     */
    public void setName(String name);

    /**
     * Returns the tag of this feature.
     * @return the tag of this feature
     */
    public String getTag();

    /**
     * Sets the tag of this feature.
     * @param tag the tag of this feature
     */
    public void setTag(String tag);

    /**
     * Returns the image that this feature belongs to.
     * @return the image that this feature belongs to
     */
    public Image getImage();

    /**
     * Sets the image that this feature belongs to.
     * @param image the image that this feature belongs to
     */
    public void setImage(Image image);

    /**
     * Returns the parent feature of this feature.
     * @return the parent feature of this feature
     */
    public Feature getParentFeature();

    /**
     * Sets the parent feature of this feature.
     * @param parentFeature the parent feature of this feature
     */
    public void setParentFeature(Feature parentFeature);

    /**
     * Returns a list of the child features of this feature.
     * @return a {@link List} of {@link Feature Features}
     */
    public List getChildren();

    /**
     * Returns an iterator of the child features of this feature.
     * @return an {@link Iterator} of {@link Feature Features}
     */
    public Iterator iterateChildren();
}
