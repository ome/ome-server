/*
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

package org.openmicroscopy.ds.tests;

import java.io.*;
import java.util.*;
import org.openmicroscopy.ds.*;
import org.openmicroscopy.ds.managers.*;
import org.openmicroscopy.ds.dto.*;
import org.openmicroscopy.ds.st.*;
import org.openmicroscopy.is.*;

public class TestImport
{
    public static void main(String[] args)
    {
        try
        {
            String urlString = "http://localhost:8002/";
            String filePath = null;

            if (args.length > 1)
            {
                urlString = args[0];
                filePath = args[1];
            } else if (args.length > 0) {
                filePath = args[0];
            } else {
                throw new IllegalArgumentException("Need a filename");
            }

            // Login to OME.  Note the new DataServices class --
            // this is quite useful if you're going to be using
            // several of the helper classes on the remote interface.
            DataServices rs = DataServer.getDefaultServices(urlString);
            RemoteCaller rc = rs.getRemoteCaller();

            BufferedReader in =
                new BufferedReader(new InputStreamReader(System.in));

            System.out.print("Username? ");
            String username = in.readLine();
        
            System.out.print("Password? ");
            String password = in.readLine();

            System.out.println("Logging in...");
            rc.login(username,password);

            // Retrieve all of the helper classes that we need for
            // importing.

            DataFactory df = (DataFactory)
                rs.getService(DataFactory.class);
            ImportManager im = (ImportManager)
                rs.getService(ImportManager.class);
            PixelsFactory pf = (PixelsFactory)
                rs.getService(PixelsFactory.class);
            DatasetManager dm = (DatasetManager)
                rs.getService(DatasetManager.class);
            ConfigurationManager cm = (ConfigurationManager)
                rs.getService(ConfigurationManager.class);
            AnalysisEngineManager aem = (AnalysisEngineManager)
                rs.getService(AnalysisEngineManager.class);

            // Grab the Experimenter object for the logged in user.
            // (This is so that we can assign ownership to the images
            // we create.)

            System.out.println("Retrieving user...");
            FieldsSpecification fs = new FieldsSpecification();
            fs.addWantedField("id");
            fs.addWantedField("experimenter");
            fs.addWantedField("experimenter","id");
            UserState userState = df.getUserState(fs);
            Experimenter user = userState.getExperimenter();

            // Create a File object for the file we want to upload.

            File file = new File(filePath);

            // Start the import process

            System.out.println("Starting import...");
            im.startImport();

            // Create a dataset to contain the images that create.
            // This requires maintaining a list of the new image
            // objects.

            System.out.println("Creating dataset...");
            Dataset importDataset = (Dataset) df.createNew(Dataset.class);
            List images = new ArrayList();
            importDataset.setName("ImportSet");
            importDataset.setDescription("Images uploaded from Java");
            importDataset.setOwner(user);
            df.markForUpdate(importDataset);

            // Locate a repository object to contain the original file
            // and new pixels file.

            System.out.println("Finding repository...");
            Repository r = pf.findRepository(file.length());

            // Ask the ImportManager for a MEX for the original files.

            System.out.println("Uploading file "+filePath+"...");
            ModuleExecution of = im.getOriginalFilesMEX();

            // Upload each original file into the repository that we
            // found, using the MEX that the import manager returned.

            OriginalFile fileAttr = pf.uploadFile(r,of,file);

            // Once all of the files are uploaded, mark the original
            // file MEX as having completed executing.

            of.setStatus("FINISHED");
            df.markForUpdate(of);

            /*---------------------------------------------------------*
             * At this point, you could use the pf.readData method to
             * parse the originalFile to retrieve metadata from it,
             * unless you already have the metadata in memory.  It is
             * also possible to parse the file using standard Java
             * file access routines on the file variable.  However,
             * you're most likely going to be using the pf.convert*
             * methods later to copy pixels from the original file to
             * the pixels file, so it's better to use the pf methods
             * for reading the metadata, too.
             *---------------------------------------------------------*/

            // Create a new Image object for this image.

            System.out.println("Creating image entry...");
            Image image = (Image) df.createNew(Image.class);
            image.setName("Java-upload test image");
            image.setOwner(user);
            image.setInserted("now");
            image.setCreated("now");
            image.setDescription("This image was uploaded from Java");
            df.markForUpdate(image);
            images.add(image);

            // The size of the dummy image we're uploading.
            // (Obviously, this would usually come from parsing the
            // original file as described above.)

            int SIZE_X = 64;
            int SIZE_Y = 64;
            int SIZE_Z = 3;
            int SIZE_C = 1;
            int SIZE_T = 1;
            int BYTES_PER_PIX = 1;

            // Ask the ImportManager for a MEX for this image's
            // metadata.

            System.out.println("Creating pixels file...");
            ModuleExecution ii = im.getImageImportMEX(image);

            // Create a new pixels file on the image server to contain
            // the image's pixels.

            Pixels pix = pf.newPixels(r,image,ii,
                                      SIZE_X,SIZE_Y,SIZE_Z,SIZE_C,SIZE_T,
                                      BYTES_PER_PIX,false,false);

            /*---------------------------------------------------------*
             * Normally, you would use the pf.convert* methods to fill
             * in the pixels file.  However, this test is creating a
             * dummy image, so we are instead going to fill in the
             * pixels using a byte array.             
             *---------------------------------------------------------*/

            byte[] buf = new byte[SIZE_X*SIZE_Y*BYTES_PER_PIX];

            // Use the Arrays class to fill in the byte array with a
            // different pixel value for each Z-section, then use the
            // pf.setPlane method to fill in the pixels.

            System.out.println("  0,0,0");
            Arrays.fill(buf,(byte) 0x00);
            pf.setPlane(pix,0,0,0,buf,true);

            System.out.println("  1,0,0");
            Arrays.fill(buf,(byte) 0x7F);
            pf.setPlane(pix,1,0,0,buf,true);

            System.out.println("  2,0,0");
            Arrays.fill(buf,(byte) 0xFF);
            pf.setPlane(pix,2,0,0,buf,true);

            // Once the pixels file is completely filled in, the
            // finishPixels method should be called to close it on the
            // image server and make it ready for reading.

            System.out.println("Closing pixels file...");
            pf.finishPixels(pix);

            // Have the image server create a default thumbnail for
            // the image.  We use a helper method in the
            // CompositingSettings class to create a standard set of
            // PGI compositing settings based on the size of the
            // image.  (These settings display the plane at the middle
            // timepoint and Z-section, and create display channels
            // out of the first three channel indices in the pixels
            // file.)

            System.out.println("Creating PGI thumbnail...");
            pf.setThumbnail(pix,CompositingSettings.
                            createDefaultPGISettings(SIZE_Z,SIZE_C,SIZE_T));

            // This next piece of metadata is necessary for all
            // images; otherwise, the standard OME viewers will not be
            // able to display the image.  The PixelChannelComponent
            // attribute represents one channel index in the pixels
            // file; there should be at least one of these for each
            // channel in the image.  The LogicalChannel attribute
            // describes a logical channel, which might comprise more
            // than one channel index in the pixels file.  (Usually it
            // doesn't.)  The mutators listed below are the minimum
            // necessary to fully represents the image's channels;
            // there are others which might be populated if the
            // metadata exists in the original file.  As with the
            // Pixels attribute, the channel attributes should use the
            // image import MEX received earlier from the
            // ImportManager.

            System.out.println("Recording wavelengths...");

            LogicalChannel logical = (LogicalChannel)
                df.createNew("LogicalChannel");
            logical.setImage(image);
            logical.setModuleExecution(ii);
            logical.setFluor("Gray 00");
            logical.setPhotometricInterpretation("monochrome");
            df.markForUpdate(logical);

            PixelChannelComponent physical = (PixelChannelComponent)
                df.createNew("PixelChannelComponent");
            physical.setImage(image);
            physical.setPixels(pix);
            physical.setIndex(new Integer(0));
            physical.setLogicalChannel(logical);
            df.markForUpdate(physical);

            // Once all of the image's metadata has been created, the
            // image import MEX as having completed executing.

            ii.setStatus("FINISHED");
            df.markForUpdate(ii);

            // Have the DataFactory commit and objects which have
            // created or modified (as indicated by the calls to
            // markForUpdate).  Note that many of the ImportManager
            // and PixelsFactory calls implicitly mark objects for
            // updating (such as the newly created MEX's).

            System.out.println("Committing changes...");
            df.updateMarked();

            // Now that we have saved the image and pixels to the DB,
            // set the image's default pixel entry to this new pixels
            // file.

            image.setDefaultPixels(pix);
            df.update(image);

            // Once all of the images (and the dataset) are committed,
            // we can add the images to the dataset.

            System.out.println("Adding images to dataset...");
            dm.addImagesToDataset(importDataset,images);
            images.clear();

            // And once the images are in the dataset, we can execute
            // the import analysis chain.

            System.out.println("Executing import chain...");
            AnalysisChain chain = cm.getImportChain();
            aem.executeAnalysisChain(chain,importDataset);

            // And log out.

            System.out.println("Logging out...");
            rc.logout();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}