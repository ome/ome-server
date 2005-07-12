/*
 * org.openmicroscopy.ds.managers.ImportManager
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

import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.RemoteServerErrorException;
import org.openmicroscopy.ds.dto.Module;
import org.openmicroscopy.ds.dto.ModuleExecution;
import org.openmicroscopy.ds.dto.Dataset;
import org.openmicroscopy.ds.dto.Image;
import org.openmicroscopy.ds.st.Experimenter;


/**
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <small><i>(Internal: $Revision$ $Date$)</i></small>
 * @since OME2.2
 */

public class ImportManager
    extends AbstractService
{
    protected DataFactory factory = null;
    protected ModuleExecutionManager mem = null;
    protected ConfigurationManager config = null;

    public ImportManager() { super(); }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        factory = (DataFactory) services.getService(DataFactory.class);
        mem = (ModuleExecutionManager) services.
            getService(ModuleExecutionManager.class);
        config = (ConfigurationManager) services.
            getService(ConfigurationManager.class);
    }

    private boolean importing = false;
    private ModuleExecution originalFiles = null;
    private ModuleExecution globalImport = null;
    private Map datasetImport = null;
    private Map imageImport = null;

    public void startImport(Experimenter user)
    {
        if (importing)
            throw new IllegalStateException("Import has already started");

        importing = true;
        Module module = config.getOriginalFilesModule();
        originalFiles = mem.createMEX(module,null,null);
	originalFiles.setExperimenter(user);
        mem.createNEX(originalFiles,null,null);
        datasetImport = new HashMap();
        imageImport = new HashMap();
    }

    public ModuleExecution getOriginalFilesMEX()
    {
        if (!importing)
            throw new IllegalStateException("Import has not started");

        return originalFiles;
    }

    public ModuleExecution getGlobalImportMEX()
    {
        if (!importing)
            throw new IllegalStateException("Import has not started");

        if (globalImport == null)
        {
            Module module = config.getGlobalImportModule();
            globalImport = mem.createMEX(module,null,null);
            if (globalImport == null)
                throw new RemoteServerErrorException("Error creating global import MEX");
            mem.addActualInput(originalFiles,globalImport,"Files");
            mem.createNEX(globalImport,null,null);
        }

        return globalImport;
    }

    public ModuleExecution getDatasetImportMEX(Dataset dataset)
    {
        if (!importing)
            throw new IllegalStateException("Import has not started");

        if (dataset == null)
            throw new IllegalArgumentException("Dataset cannot be null");

        ModuleExecution mex = (ModuleExecution) datasetImport.get(dataset);
        if (mex == null)
        {
            Module module = config.getDatasetImportModule();
            mex = mem.createMEX(module,dataset,null,null);
            if (mex == null)
                throw new RemoteServerErrorException("Error creating dataset import MEX");
            mem.addActualInput(originalFiles,mex,"Files");
            mem.createNEX(mex,null,null);
            datasetImport.put(dataset,mex);
        }

        return mex;
    }

    public ModuleExecution getImageImportMEX(Image image)
    {
        if (!importing)
            throw new IllegalStateException("Import has not started");

        if (image == null)
            throw new IllegalArgumentException("Image cannot be null");

        ModuleExecution mex = (ModuleExecution) imageImport.get(image);
        if (mex == null)
        {
            Module module = config.getImageImportModule();
            mex = mem.createMEX(module,image,null,null);
            if (mex == null)
                throw new RemoteServerErrorException("Error creating image import MEX");
            mem.addActualInput(originalFiles,mex,"Files");
            mem.createNEX(mex,null,null);
            imageImport.put(image,mex);
        }

        return mex;
    }

    public void finishImport()
    {
        importing = false;
        originalFiles = null;
        globalImport = null;
        datasetImport = null;
        imageImport = null;
    }

}