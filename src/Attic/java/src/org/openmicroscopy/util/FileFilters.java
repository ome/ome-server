/*
 * org.openmicroscopy.helper.ImageServerHelper
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2003 Open Microscopy Environment
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */

package org.openmicroscopy.util;

import java.io.File;
import java.io.FileFilter;

/**
 * Contains some useful {@link FileFilter}s.
 *
 * @author Douglas Creager
 * @since OME2.1
 * @version 2.1
 */

public class FileFilters
{
    /**
     * {@link FileFilter} which only passes normal files.
     */

    public static final FileFilter NORMAL_FILES =
        new FileFilter()
        {
            public boolean accept(File file)
            {
                return file.isFile();
            }
        };

    /**
     * {@link FileFilter} which only passes directories.
     */

    public static final FileFilter DIRECTORIES =
        new FileFilter()
        {
            public boolean accept(File file)
            {
                return file.isDirectory();
            }
        };

    /**
     * {@link FileFilter} which passes everything.
     */

    public static final FileFilter EVERYTHING =
        new FileFilter()
        {
            public boolean accept(File file)
            {
                return true;
            }
        };

}