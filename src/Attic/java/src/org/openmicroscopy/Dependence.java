/*
 * org.openmicroscopy.Dependence
 *
 * Copyright (C) 2002 Open Microscopy Environment, MIT
 * Author:  Douglas Creager <dcreager@alum.mit.edu>
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
 */

package org.openmicroscopy;

/**
 * Declares constants to represent the possible values for a module
 * executions's dependence.
 *
 * @author Douglas Creager
 * @version 2.0
 * @since OME2.0
 * @see ModuleExecution
 */

public interface Dependence
{
    /**
     * The module execution generated only global attributes, so its
     * dependence is not important.
     */
    public static final int GLOBAL  = 0;

    /**
     * The results of this module execution depend on the dataset it
     * was executed against.
     */
    public static final int DATASET = 1;

    /**
     * The results of this module execution are independent for each
     * image in the dataset.
     */
    public static final int IMAGE   = 2;

    /**
     * {@link String} labels for each of the possible
     * <code>Dependence</code> values.  Useful for populating lists
     * and combo boxes; ensures that the selected index will
     * correspond to the correct <code>Dependence</code> value,
     * assuming that the list or combo box does not rearrange the
     * items.
     */
    public static final String[]  LABELS =
    {"Global","Dataset","Image"};
}
