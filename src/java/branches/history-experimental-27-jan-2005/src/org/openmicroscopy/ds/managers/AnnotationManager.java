/*
 * org.openmicroscopy.ds.managers.AnnotationManager
 *
 *------------------------------------------------------------------------------
 *
 *  Copyright (C) 2004 Open Microscopy Environment
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
 * Written by:    Douglas Creager <dcreager@alum.mit.edu>
 *------------------------------------------------------------------------------
 */


package org.openmicroscopy.ds.managers;

import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;
import java.util.List;
import java.util.ArrayList;

import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.Instantiator;
import org.openmicroscopy.ds.InstantiatingCaller;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.RemoteServerErrorException;
import org.openmicroscopy.ds.dto.MappedDTO;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Image;
import org.openmicroscopy.ds.dto.Feature;
import org.openmicroscopy.ds.dto.Attribute;
import org.openmicroscopy.ds.dto.SemanticType;
import org.openmicroscopy.ds.dto.ModuleExecution;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class AnnotationManager
    extends AbstractService
{
    protected InstantiatingCaller icaller = null;

    protected Instantiator  instantiator = null;

    public AnnotationManager() { super(); }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        icaller = (InstantiatingCaller)
            services.getService(InstantiatingCaller.class);
        instantiator = icaller.getInstantiator();
    }

    /**
     * <p>Creates a list of annotation attributes.  Annotation
     * attributes are just like standard attributes, except that they
     * are created by a MEX of the <i>Annotation</i> module.  This
     * Annotation module is one of the black-box modules used to bring
     * outside data into the OME MEX-based data history system.  It
     * signifies that the data in question was provided by the user,
     * and not by any automated process such as image import or
     * microscope acquisition.</p>
     *
     * <p>The constraints on the contents of a ModuleExecution imply
     * constraints on the list of attributes that this method can
     * accept.  Each attribute in the list must have the same
     * granularity.  Further, the target of each of the attributes
     * must be the same.  If either of these two conditions is not
     * met, this method will throw an {@link
     * IllegalArgumentException}.</p>
     *
     * <p>All of the attribute objects in the list must be new; i.e.,
     * created with the {@link DataFactory#createNew} method.  They
     * cannot be attributes which were loaded in from the data server
     * via a {@link DataFactory#load} or {@link DataFactory#retrieve}
     * call.</p>
     *
     * <p>After this method returns, the attributes in the list will
     * no longer be new, and the primary key ID field will be replaced
     * with the actual primary key from the database.  The return
     * value of the method is the annotation MEX which encapsulates
     * all of the annotation attributes.  This MEX can then be used,
     * if necessary, with an ActualInput for another MEX.</p>
     *
     * @param attributes the {@link List} of attributes to save as
     * annotations
     *
     */
    public ModuleExecution annotateAttributes(List attributes)
    {
        if (attributes == null)
            throw new IllegalArgumentException("Attributes list is null");

        String granularity = null;
        Dataset dataset = null;
        Image image = null;
        Feature feature = null;

        List params = new ArrayList(3+attributes.size()*2);
        Map newIDs = new HashMap();

        // Fields specification
        params.add(null);

        int nextNew = 1;

        for (Iterator it = attributes.iterator(); it.hasNext(); )
        {
            Object o = it.next();

            if (!(o instanceof Attribute))
                throw new IllegalArgumentException("List can only contain Attributes");
            Attribute a = (Attribute) o;

            if (!(o instanceof MappedDTO))
                throw new IllegalArgumentException("Unknown Attribute implementation");
            MappedDTO ma = (MappedDTO) o;

            if (!ma.isNew())
                throw new IllegalArgumentException("Each Attribute must be new");

            SemanticType st = a.getSemanticType();

            String thisGranularity = st.getGranularity();
            if (granularity == null)
            {
                granularity = thisGranularity;
                params.add(granularity);
            } else if (!granularity.equals(thisGranularity)) {
                throw new IllegalArgumentException("Granularities don't match!");
            }

            if (granularity.equals("D"))
            {
                Dataset thisDataset = a.getDataset();
                if (dataset == null)
                {
                    dataset = thisDataset;
                    params.add(new Integer(dataset.getID()));
                } else if (!dataset.equals(thisDataset)) {
                    throw new IllegalArgumentException("Targets don't match!");
                }
            } else if (granularity.equals("I")) {
                Image thisImage = a.getImage();
                if (image == null)
                {
                    image = thisImage;
                    params.add(new Integer(image.getID()));
                } else if (!image.equals(thisImage)) {
                    throw new IllegalArgumentException("Targets don't match!");
                }
            } else if (granularity.equals("F")) {
                Feature thisFeature = a.getFeature();
                if (feature == null)
                {
                    feature = thisFeature;
                    params.add(new Integer(feature.getID()));
                } else if (!feature.equals(thisFeature)) {
                    throw new IllegalArgumentException("Targets don't match!");
                }
            }

            params.add(new Integer(st.getID()));
            newIDs.put(ma,"NEW:"+(nextNew++));
            params.add(instantiator.serializeForUpdate(ma,newIDs));
        }

        Object result = caller.dispatch("annotateAttributes",
                                        params.toArray());

        // We should get back a map of the primary key ID's for each
        // of the objects which was new.

        Map realIDs;

        if (result == null)
        {
            realIDs = new HashMap();
        } else if (result instanceof Map) {
            realIDs = (Map) result;
        } else {
            throw new RemoteServerErrorException("Server returned an invalid type "+
                                                 result.getClass());
        }

        // Go through each of the new objects, and populate it with
        // its actual primary key ID.

        for (Iterator it = newIDs.keySet().iterator(); it.hasNext(); )
        {
            MappedDTO newObject = (MappedDTO) it.next();
            String newID = (String) newIDs.get(newObject);
            Object realID = realIDs.get(newID);

            if (realID == null)
                throw new RemoteServerErrorException("Server did not return an ID for the new object "+newID);

            newObject.setNew(false);
            newObject.getMap().put("id",realID);
        }

        // The new MEX for the attributes should also be in the hash,
        // with a key of "MEX"

        Map mexMap = (Map) realIDs.get("MEX");
        if (mexMap == null)
            throw new RemoteServerErrorException("Server did not return a module execution");

        return (ModuleExecution)
            instantiator.instantiateDTO(ModuleExecution.class,mexMap);
    }

}