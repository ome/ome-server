/*
 * org.openmicroscopy.ds.managers.RemoteImportManager
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

import java.util.List;
import java.util.ArrayList;

import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.PrimitiveConverters;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.FieldsSpecification;
import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.RemoteServerErrorException;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.ActualInput;
import org.openmicroscopy.ds.dto.ModuleExecution;
import org.openmicroscopy.ds.dto.Image;

/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class RemoteImportManager
    extends AbstractService
{
    protected DataFactory factory = null;
    protected ConfigurationManager config = null;

    protected static FieldsSpecification MEX_STATUS_SPEC;
    static
    {
        MEX_STATUS_SPEC = new FieldsSpecification();
        MEX_STATUS_SPEC.addWantedField("status");
    }

    public RemoteImportManager() { super(); }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        factory = (DataFactory) services.getService(DataFactory.class);
        config = (ConfigurationManager) services.
            getService(ConfigurationManager.class);
    }

    public int startRemoteImport(List fileIDs)
    {
        if (fileIDs == null)
            throw new IllegalArgumentException("List of file ID's cannot be null");

        for (int i = 0; i < fileIDs.size(); i++)
            if (!(fileIDs.get(i) instanceof Long))
                throw new IllegalArgumentException("Each file ID must be a Long");

        Object result = caller.dispatch("startImport",
                                        new Object[] { fileIDs });

        try
        {
            Integer iresult = PrimitiveConverters.convertToInteger(result);
            return iresult.intValue();
        } catch (NumberFormatException e) {
            throw new RemoteServerErrorException("Did not get an Integer back from the server");
        }
    }

    public int startRemoteImport(Dataset dataset, List fileIDs)
    {
        if (fileIDs == null)
            throw new IllegalArgumentException("List of file ID's cannot be null");

        for (int i = 0; i < fileIDs.size(); i++)
            if (!(fileIDs.get(i) instanceof Long))
                throw new IllegalArgumentException("Each file ID must be a Long");

        Object result = caller.dispatch("startImport",
                                        new Object[] {
                                            new Integer(dataset.getID()),
                                            fileIDs
                                        });

        try
        {
            Integer iresult = PrimitiveConverters.convertToInteger(result);
            return iresult.intValue();
        } catch (NumberFormatException e) {
            throw new RemoteServerErrorException("Did not get an Integer back from the server");
        }
    }

    public boolean isRemoteImportFinished(int mexID)
    {
        ModuleExecution mex = (ModuleExecution)
            factory.load(ModuleExecution.class,mexID,MEX_STATUS_SPEC);

        String status = mex.getStatus();
        return status.equals("FINISHED");
    }

    public List getImportedImageIDs(int mexID)
    {
        Criteria crit = new Criteria();
        crit.addFilter("formal_input.semantic_type.name","OriginalFile");
        crit.addFilter("input_module_execution",new Integer(mexID));
        crit.addFilter("module_execution.module",config.getImageImportModule());
        crit.addWantedField("module_execution");
        crit.addWantedField("module_execution","image");
        crit.addWantedField("module_execution.image","id");

        List result = factory.retrieveList(ActualInput.class,crit);
        if (result == null)
            return new ArrayList();

        List ids = new ArrayList(result.size());

        for (int i = 0; i < result.size(); i++)
        {
            ActualInput input = (ActualInput) result.get(i);
            ModuleExecution mex = input.getModuleExecution();
            Image image = mex.getImage();
            ids.add(new Integer(image.getID()));
        }

        return ids;
    }

    public List getImportedImages(int mexID, FieldsSpecification imageSpec)
    {
        Criteria crit = new Criteria();
        crit.addFilter("formal_input.semantic_type.name","OriginalFile");
        crit.addFilter("input_module_execution",new Integer(mexID));
        crit.addFilter("module_execution.module",config.getImageImportModule());
        crit.addWantedField("module_execution");
        crit.addWantedField("module_execution","image");
        crit.addWantedFields("module_execution.image",imageSpec);

        List result = factory.retrieveList(ActualInput.class,crit);
        if (result == null)
            return new ArrayList();

        List images = new ArrayList(result.size());

        for (int i = 0; i < result.size(); i++)
        {
            ActualInput input = (ActualInput) result.get(i);
            ModuleExecution mex = input.getModuleExecution();
            Image image = mex.getImage();
            images.add(image);
        }

        return images;
    }

}