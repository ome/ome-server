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

package org.openmicroscopy.helpers;

import java.io.File;
import java.io.FileFilter;
import java.io.FileNotFoundException;
import java.util.Iterator;
import java.util.List;
import java.util.LinkedList;
import java.util.ArrayList;
import java.util.Map;
import java.util.HashMap;
import org.openmicroscopy.is.ImageServer;
import org.openmicroscopy.is.ImageServerException;
import org.openmicroscopy.util.ProgressTracker;
import org.openmicroscopy.util.FileFilters;

public class ImageServerHelper
{
    /**
     * <p>Normalizes a list of files.  Verifies that each file in the
     * list exists, and uses a default {@link FileFilter} which
     * accepts only normal files.  This causes the search to
     * <b>not</b> be recursive.</p>
     */
    public static List normalizeFiles(List files)
        throws FileNotFoundException
    {
        return normalizeFiles(files,true,FileFilters.NORMAL_FILES);
    }

    /**
     * <p>Normalizes a list of files.  Verifies that each file in the
     * list exists if desired, and uses a default {@link FileFilter}
     * which accepts only normal files.  This causes the search to
     * <b>not</b> be recursive.</p>
     */
    public static List normalizeFiles(List files, boolean verify)
        throws FileNotFoundException
    {
        return normalizeFiles(files,verify,FileFilters.NORMAL_FILES);
    }

    /**
     * <p>Normalizes a list of files.  This involves looking into any
     * directories, and adding the files in those directories to the
     * list.  It also ensures that each file exists, if desired.</p>
     *
     * <p>This method accepts a {@link FileFilter} which can be used
     * to restrict which files in are included from each directory in
     * the list.  The behavior of this filter determines whether the
     * search is recursive; any directories which are passed by the
     * filter will be searched just like any directories which were in
     * the original list.  Therefore, this method is recursive only if
     * the filter passes any directories.</p>
     *
     * <p><B>IMPORTANT:</b> The filter will <i>not</i> be applied to
     * any files which appear directly in the input list.  It is only
     * applied to the files found in any directories in the input
     * list.</p>
     */
    public static List normalizeFiles(List files,
                                      boolean verify,
                                      FileFilter filter)
        throws FileNotFoundException
    {
        // Create a result List that is about the right size
        List result = new ArrayList(files.size());

        // Create the search queue and fill it with the input list
        LinkedList queue = new LinkedList(files);

        // Search through the queue until it is empty.  We cannot use
        // an iterator, because we will be modifying the queue as we
        // go.

        while (!queue.isEmpty())
        {
            // Make sure the object is a File.  If not, create one out
            // of the object's String representation.
            Object next = queue.removeFirst();
            File file = (next instanceof File)?
                (File) next:
                new File(next.toString());

            // If asked, verify that the file exists.
            if (verify && !file.exists())
                throw new FileNotFoundException("Cannot find file "+file);

            if (file.isDirectory())
            {
                // This is a directory, so add the contents of the
                // directory to the list of files to check.

                File[] contents = file.listFiles(filter);
                for (int i = 0; i < contents.length; i++)
                    queue.addLast(contents[i]);
            } else {
                // Not a directory, just add the file to the result
                result.add(file);
            }
        }

        return result;
    }

    /**
     * <p>Uploads a list of files to an OME image server.  This list
     * should only contain regular files, specified as {@link File}
     * objects; any directories in the list will be skipped.  You can
     * use the {@link #normalizeFiles(List,boolean,FileFilter)} method
     * to normalize a list of files which might contain directories
     * and/or other objects (such as {@link String}s) into a list
     * which contains only normal {@link File}s.</p>
     * 
     * <p>This method returns a {@link Map} with {@link File} objects
     * as keys and the image server file ID's (specified as {@link
     * Long}s) as values.</p>
     *
     * <p>This method will upload as many files as possible, even if
     * exceptions are thrown while uploading some of them.  (This
     * includes local errors such as {@link FileNotFoundException} and
     * remote errors such as {@link ImageServerException}.)  All
     * exceptions will be masked, and the returned {@link Map} will
     * only contain entries for those {@link File}s which were
     * successfully uploaded.  The sizes of the input {@link List} and
     * output {@link Map} can be compared to test for an error
     * condition.</p>
     *
     * @param is the image server to upload to
     * @param files a normalized list of files
     * @param tracker optional; used to track the progress of the
     * upload if desired
     * @throws ClassCastException if the <code>files</code> list
     * contains objects which are not {@link File}s
     */
    public static Map uploadFiles(ImageServer is, List files,
                                  ProgressTracker tracker)
    {
        long totalLength = 0;

        // Calculate the total length of the files to upload, for the
        // purposes of the progress tracker.

        Iterator iter = files.iterator();
        while (iter.hasNext())
        {
            File file = (File) iter.next();
            totalLength += file.length();
        }

        // Initialize the progress tracker
        if (tracker != null) tracker.setRange(0,totalLength);
        
        Map result = new HashMap();
        long progress = 0;

        iter = files.iterator();
        while (iter.hasNext())
        {
            File file = (File) iter.next();

            // Update the progress tracker
            if (tracker != null)
                tracker.setMessage(file.toString());

            try
            {
                // Upload the file and save its ID in the result Map
                long fileID = is.uploadFile(file);
                result.put(file,new Long(fileID));

                // Update the progress tracker
                progress += file.length();
                if (tracker != null)
                    tracker.setProgress(progress);
            } catch (ImageServerException e) {
                // Couldn't upload the file
                e.printStackTrace();
            } catch (FileNotFoundException e) {
                // Couldn't upload the file
                e.printStackTrace();
            }
        }

        return result;
    }
}