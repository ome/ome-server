/*
 * org.openmicroscopy.imageviewer.LocalRepositoryFinder
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
 * Written by:    Jeff Mellen <jeffm@alum.mit.edu>
 *
 *------------------------------------------------------------------------------
 */
package org.openmicroscopy.imageviewer;

import java.io.File;
import java.util.HashSet;
import java.util.Set;

import org.openmicroscopy.*;
import org.openmicroscopy.remote.*;

/**
 * Loads a local repository (using addRepositoryPath) if one exists, so that
 * image pixels can be culled from the right location (not from the remote
 * framework).  This would be a good replacement for isRepositoryLocal() in
 * LocalImagePixels, but I'll ask about that later.  Call before getting
 * image pixels.
 * 
 * @author Jeff Mellen, <a href="mailto:jeffm@alum.mit.edu">jeffm@alum.mit.edu</a>
 * @version $Revision$ $Date$
 */
public final class LocalRepositoryFinder
{
  public static Set notLocalRepositories = new HashSet();
  
  /**
   * Stores a record of this repository in LocalImagePixels if an OME
   * repository is local.  (May need to search for an appropriate image too, later)
   * 
   * @param repository The repository record to look for.
   * @return True if the repository is local, false if it is not.
   */
  public static boolean findAndStore(Attribute repository)
  {
    if(LocalImagePixels.isRepositoryLocal(repository))
    {
      return true;
    }
    else if(notLocalRepositories.contains(new Integer(repository.getID())))
    {
      return false;
    }
    else
    {
      // gotta get this element
      String path = repository.getStringElement("Path");
      
      // check the file path
      File file = new File(path);
      if(file.exists() && file.isDirectory())
      {
        // first test in module will return true after this.
        LocalImagePixels.addRepositoryPath(repository,file);
        return true;
      }
      
      // cache negative response so we don't have to ask again if not
      else
      {
        notLocalRepositories.add(new Integer(repository.getID()));
        return false;
      }
    }
  }
}
