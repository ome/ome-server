/*
 * org.openmicroscopy.is.PixelsFactory
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

package org.openmicroscopy.is;

import java.io.File;
import java.io.FileNotFoundException;

import java.awt.image.BufferedImage;

import java.util.Map;
import java.util.HashMap;

import org.openmicroscopy.ds.DataServices;
import org.openmicroscopy.ds.AbstractService;
import org.openmicroscopy.ds.DataFactory;
import org.openmicroscopy.ds.DataException;
import org.openmicroscopy.ds.Criteria;
import org.openmicroscopy.ds.dto.Image;
import org.openmicroscopy.ds.dto.ModuleExecution;
import org.openmicroscopy.ds.st.Pixels;
import org.openmicroscopy.ds.st.OriginalFile;
import org.openmicroscopy.ds.st.Repository;

/**
 * Contains methods for accessing an image server via a {@link Pixels}
 * attribute.  The methods defined in {@link ImageServer} provide
 * low-level access to the image server; pixels files must be
 * specified by their image server ID.  This class provides the same
 * pixels-based methods as the {@link ImageServer} interface, but in
 * terms of a {@link Pixels} instance instead of an image server ID.
 * It also handles creating the appropriate instances of the {@link
 * ImageServer} interface, since all of the necessary connection
 * information is provided by the <code>Pixels</code>'s {@link
 * Repository} attribute.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision$ $Date$)</i>
 * @since OME2.2
 */

public class PixelsFactory
    extends AbstractService
{
    /**
     * Stores all of the previously seen image servers.  It is
     * possible, though currently unlikely, that there will be
     * multiple Repositories in the system, each pointing to a
     * different image server.  To handle this case, we maintain a
     * map, with Repository ID's for the keys, and ImageServer objects
     * for the values.
     */
    private Map imageServers;

    /**
     * The {@link DataFactory} object used to authenticate with the
     * image servers.
     */
    private DataFactory factory;

    public PixelsFactory() { super(); }

    /**
     * Creates a new <code>PixelsFactory</code> which uses the
     * connection information in the given {@link DataFactory} to
     * authenticate with each image server.
     */
    public PixelsFactory(DataFactory factory)
    {
        super();
        initializeService(DataServices.
                          getInstance(factory.getRemoteCaller()));
    }

    public void initializeService(DataServices services)
    {
        super.initializeService(services);
        this.factory = (DataFactory)
            services.getService(DataFactory.class);
        this.imageServers = new HashMap();
    }

    /**
     * Retrieves or creates an {@link ImageServer} object for
     * retrieving pixels for the given Repository attribute.
     */

    private ImageServer activateRepository(Repository rep)
        throws ImageServerException
    {
        Integer id = new Integer(rep.getID());
        ImageServer is = (ImageServer) imageServers.get(id);

        if (is == null)
        {
            String url = rep.getImageServerURL();
            if (url == null || url.equals(""))
                throw new ImageServerException("Repository contains a null image server URL");

            is = ImageServer.
                getHTTPImageServer(url,factory.getSessionKey());
            imageServers.put(id,is);
        }

        return is;
    }

    /**
     * Retrieves or creates an {@link ImageServer} object for
     * retrieving pixels for the given Pixels attribute.
     */

    private ImageServer activatePixels(Pixels pix)
        throws ImageServerException
    {
        try
        {
            Number pixelsID = pix.getImageServerID();
            if (pixelsID == null)
                throw new ImageServerException("Pixels contains a null pixels ID");

            Repository rep = pix.getRepository();
            return activateRepository(rep);
        } catch (DataException e) {
            throw new ImageServerException("Pixels did not contain enough connection information to connect to image server");
        }
    }

    /**
     * Retrieves or creates an {@link ImageServer} object for
     * retrieving information about the given OriginalFile attribute.
     */

    private ImageServer activateOriginalFile(OriginalFile file)
        throws ImageServerException
    {
        try
        {
            Number fileID = file.getFileID();
            if (fileID == null)
                throw new ImageServerException("OriginalFile contains a null file ID");

            Repository rep = file.getRepository();
            return activateRepository(rep);
        } catch (DataException e) {
            throw new ImageServerException("OriginalFile did not contain enough connection information to connect to image server");
        }
    }

    /**
     * <p>Creates a new pixels file on the image server.  The
     * dimensions of the pixels must be known beforehand, and must be
     * specified to this method.  All of the dimensions must be
     * positive integers.</p>
     *
     * <p>Each pixel in the new file must have the same storage type.
     * This type is specified by the <code>bytesPerPixel</code>,
     * <code>isSigned</code>, and <code>isFloat</code> parameters.</p>
     *
     * <p>This method returns the pixels ID generated by the image
     * server.  Note that this is not the same as the attribute ID of
     * a Pixels attribute.  The pixels ID can be used in the
     * <code>get*</code>, <code>set*</code>, and <code>convert*</code>
     * methods (among others) to perform pixel I/O with the image
     * server.</p>
     *
     * <p>The new pixels file will be created in write-only mode.  The
     * <code>set*</code> and <code>convert*</code> methods should be
     * used to populate the pixel array.  Once the array is fully
     * populated, the <code>finishPixels</code> method should be used
     * to place the file in read-only mode.  At this point, the
     * <code>get*</code> methods can be called to retrieve the
     * pixels.</p>
     *
     * @param sizeX the size (in pixels) of the image's X dimension
     * @param sizeY the size (in pixels) of the image's Y dimension
     * @param sizeZ the size (in pixels) of the image's Z dimension
     * @param sizeC the size (in pixels) of the image's C dimension
     * @param sizeT the size (in pixels) of the image's T dimension
     * @param bytesPerPixel the number of bytes used to store a single
     * pixel
     * @param isSigned whether the value of each pixel is signed or
     * not
     * @param isFloat whether the value of each pixel is a float or an
     * integer
     * @return the pixel ID of the new pixels file
     * @throws ImageServerException if there was an error connecting
     * to the image server or creating the pixels file
     */
    public Pixels newPixels(Repository repository,
                            Image image,
                            ModuleExecution mex,
                            int sizeX,
                            int sizeY,
                            int sizeZ,
                            int sizeC,
                            int sizeT,
                            int bytesPerPixel,
                            boolean isSigned,
                            boolean isFloat)
        throws ImageServerException
    {
        if (repository == null)
            throw new IllegalArgumentException("Repository cannot be null");
        if (image == null)
            throw new IllegalArgumentException("Image cannot be null");
        if (mex == null)
            throw new IllegalArgumentException("MEX cannot be null");

        ImageServer is = activateRepository(repository);
        long pixelsID = is.newPixels(sizeX,sizeY,sizeZ,sizeC,sizeT,
                                     bytesPerPixel,isSigned,isFloat);

        Pixels pixels = (Pixels) factory.createNew("Pixels");
        pixels.setRepository(repository);
        pixels.setImage(image);
        pixels.setModuleExecution(mex);
        pixels.setImageServerID(new Long(pixelsID));
        pixels.setSizeX(new Integer(sizeX));
        pixels.setSizeY(new Integer(sizeY));
        pixels.setSizeZ(new Integer(sizeZ));
        pixels.setSizeC(new Integer(sizeC));
        pixels.setSizeT(new Integer(sizeT));
        pixels.setBitsPerPixel(new Integer(bytesPerPixel/8));
        pixels.setPixelType(PixelTypes.getPixelType(bytesPerPixel,
                                                    isSigned,
                                                    isFloat));
        factory.markForUpdate(pixels);

        return pixels;
    }

    /**
     * <p>Creates a new pixels file on the image server.  The
     * dimensions of the pixels must be known beforehand, and must be
     * specified to this method.  All of the dimensions must be
     * positive integers.  Each pixel in the new file must have the
     * same storage type.  This information is specified by the
     * <code>pixelsFileFormat</code> parameter.</p>
     *
     * <p>This method returns the pixels ID generated by the image
     * server.  Note that this is not the same as the attribute ID of
     * a Pixels attribute.  The pixels ID can be used in the
     * <code>get*</code>, <code>set*</code>, and <code>convert*</code>
     * methods (among others) to perform pixel I/O with the image
     * server.</p>
     *
     * <p>The new pixels file will be created in write-only mode.  The
     * <code>set*</code> and <code>convert*</code> methods should be
     * used to populate the pixel array.  Once the array is fully
     * populated, the <code>finishPixels</code> method should be used
     * to place the file in read-only mode.  At this point, the
     * <code>get*</code> methods can be called to retrieve the
     * pixels.</p>
     *
     * @param format the format of the new pixels file
     * @return the pixel ID of the new pixels file
     * @throws ImageServerException if there was an error connecting
     * to the image server or creating the pixels file
     */
    public Pixels newPixels(Repository repository,
                            Image image,
                            ModuleExecution mex,
                            PixelsFileFormat format)
        throws ImageServerException
    {
        return newPixels(repository,
                         image,
                         mex,
                         format.getSizeX(),
                         format.getSizeY(),
                         format.getSizeZ(),
                         format.getSizeC(),
                         format.getSizeT(),
                         format.getBytesPerPixel(),
                         format.isSigned(),
                         format.isFloat());
    }

    /**
     * Returns the properties of a previously created pixels file.
     * @param pixels a {@link Pixels} attribute
     * @return a {@link PixelsFileFormat} object encoding the
     * properties of the pixels file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist
     */
    public PixelsFileFormat getPixelsInfo(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPixelsInfo(pixels.getImageServerID().longValue());
    }

    /**
     * Returns the SHA-1 digest of a previously created pixels file.
     * @param pixels a {@link Pixels} attribute
     * @return the SHA-1 digest of the pixels file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist
     */
    public String getPixelsSHA1(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPixelsSHA1(pixels.getImageServerID().longValue());
    }

    /**
     * Returns the location of the specified pixels file in the image
     * server's filesystem.
     * @param pixels a {@link Pixels} attribute
     * @return the image-server-local path to the pixels file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist
     */
    public String getPixelsServerPath(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPixelsServerPath(pixels.getImageServerID().longValue());
    }

    /**
     * Returns whether the <code>finishPixels</code> method has been
     * called on the specified pixels file.
     * @param pixels a {@link Pixels} attribute
     * @return whether the <code>finishPixels</code> method has been
     * called on the specified pixels file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist
     */
    public boolean isPixelsFinished(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.isPixelsFinished(pixels.getImageServerID().longValue());
    }

    /**
     * <p>This method returns the entire pixel file for the given
     * pixel ID.  Be very careful, these can easily be friggin-huge in
     * size.  You probably don't ever want to call this method, unless
     * you've made the appropriate checks on the dimensions of the
     * pixels to ensure that it won't be too large.</p>
     *
     * <p>You must also specify whether you want to receive a
     * big-endian or little-endian pixel array.  The image server will
     * take care of performing the appropriate conversion for you.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @return an array of pixels for the specified file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * readable
     */
    public byte[] getPixels(Pixels pixels,
                            boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPixels(pixels.getImageServerID().longValue(),bigEndian);
    }

    /**
     * <p>This method returns a pixel array of the specified stack.
     * The stack is specified by its C and T coordinates, which have
     * 0-based indices.  While this method is less likely to be a
     * memory hog as the {@link #getPixels} method, it is still
     * possible for large images with few timepoints to cause
     * problems.  As usual when dealing with large images, care must
     * be taken to use your computational resources appropriately.</p>
     *
     * <p>You must also specify whether you want to receive a
     * big-endian or little-endian pixel array.  The image server will
     * take care of performing the appropriate conversion for you.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theC the C parameter of the desired stack
     * @param theT the T parameter of the desired stack
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @return an array of pixels for the specified stack
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * readable
     */
    public byte[] getStack(Pixels pixels,
                           int theC, int theT,
                           boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getStack(pixels.getImageServerID().longValue(),theC,theT,bigEndian);
    }

    /**
     * <p>This method returns a pixel array of the specified plane.
     * The plane is specified by its Z, C and T coordinates, which
     * have 0-based indices.  While this method is the least likely to
     * be a memory hog, care must still be taken to use your
     * computational resources appropriately.</p>
     *
     * <p>You must also specify whether you want to receive a
     * big-endian or little-endian pixel array.  The image server will
     * take care of performing the appropriate conversion for you.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the C parameter of the desired plane
     * @param theC the C parameter of the desired plane
     * @param theT the T parameter of the desired plane
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @return an array of pixels for the specified plane
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * readable
     */
    public byte[] getPlane(Pixels pixels,
                           int theZ, int theC, int theT,
                           boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPlane(pixels.getImageServerID().longValue(),theZ,theC,theT,bigEndian);
    }

    /**
     * <p>This method returns a pixel array of an arbitrary
     * hyper-rectangular region of an image.  The region is specified
     * by two coordinate vectors, which have 0-based indices.  The
     * region boundaries must be well formed, and are inclusive.
     * (Each coordinate must be within the range of valid values for
     * that dimension, and each "0" coordinate must be less than or
     * equal to the respective "1" coordinate.)</p>
     *
     * <p>You must also specify whether you want to receive a
     * big-endian or little-endian pixel array.  The image server will
     * take care of performing the appropriate conversion for you.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @return an array of pixels for the specified region
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * readable
     */
    public byte[] getROI(Pixels pixels,
                         int x0,int y0,int z0,int c0,int t0,
                         int x1,int y1,int z1,int c1,int t1,
                         boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getROI(pixels.getImageServerID().longValue(),
                         x0,y0,z0,c0,t0,x1,y1,z1,c1,t1,
                         bigEndian);
    }

    /**
     * <p>This method sends an entire array of pixels for the given
     * pixels ID.  The pixels are specified by a byte array, which
     * should be a raw pixel dump.  The endian-ness of the pixels
     * should be specified.</p>
     *
     * <p>It is up to the caller to ensure that the byte array is of
     * the correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param buf an array of pixels
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     */
    public void setPixels(Pixels pixels,
                          byte[] buf,
                          boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        is.setPixels(pixels.getImageServerID().longValue(),buf,bigEndian);
    }

    /**
     * <p>This method sends an entire array of pixels for the given
     * pixels ID.  The pixels are specified by a local file, which
     * should be a raw pixel dump.  The endian-ness of the pixels
     * should be specified.</p>
     *
     * <p>It is up to the caller to ensure that the file is of the
     * correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param file a file containing a pixel dump
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public void setPixels(Pixels pixels,
                          File file,
                          boolean bigEndian)
        throws ImageServerException, FileNotFoundException
    {
        ImageServer is = activatePixels(pixels);
        is.setPixels(pixels.getImageServerID().longValue(),file,bigEndian);
    }

    /**
     * <p>This method sends a stack of pixels for the given pixels ID.
     * The pixels are specified by a byte array, which should be a raw
     * pixel dump.  The endian-ness of the pixels should be
     * specified.</p>
     *
     * <p>It is up to the caller to ensure that the byte array is of
     * the correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theC the C parameter of the desired stack
     * @param theT the T parameter of the desired stack
     * @param buf an array of pixels
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     */
    public void setStack(Pixels pixels,
                         int theC, int theT,
                         byte[] buf,
                         boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        is.setStack(pixels.getImageServerID().longValue(),
                    theC,theT,buf,bigEndian);
    }

    /**
     * <p>This method sends a stack of pixels for the given pixels ID.
     * The pixels are specified by a local file, which should be a raw
     * pixel dump.  The endian-ness of the pixels should be
     * specified.</p>
     *
     * <p>It is up to the caller to ensure that the file is of the
     * correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theC the C parameter of the desired stack
     * @param theT the T parameter of the desired stack
     * @param file a file containing a pixel dump
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public void setStack(Pixels pixels,
                         int theC, int theT,
                         File file,
                         boolean bigEndian)
        throws ImageServerException, FileNotFoundException
    {
        ImageServer is = activatePixels(pixels);
        is.setStack(pixels.getImageServerID().longValue(),
                    theC,theT,file,bigEndian);
    }

    /**
     * <p>This method sends a plane of pixels for the given pixels ID.
     * The pixels are specified by a byte array, which should be a raw
     * pixel dump.  The endian-ness of the pixels should be
     * specified.</p>
     *
     * <p>It is up to the caller to ensure that the byte array is of
     * the correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the Z parameter of the desired plane
     * @param theC the C parameter of the desired plane
     * @param theT the T parameter of the desired plane
     * @param buf an array of pixels
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     */
    public void setPlane(Pixels pixels,
                         int theZ, int theC, int theT,
                         byte[] buf,
                         boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        is.setPlane(pixels.getImageServerID().longValue(),
                    theZ,theC,theT,buf,bigEndian);
    }

    /**
     * <p>This method sends a plane of pixels for the given pixels ID.
     * The pixels are specified by a local file, which should be a raw
     * pixel dump.  The endian-ness of the pixels should be
     * specified.</p>
     *
     * <p>It is up to the caller to ensure that the file is of the
     * correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the Z parameter of the desired plane
     * @param theC the C parameter of the desired plane
     * @param theT the T parameter of the desired plane
     * @param file a file containing a pixel dump
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public void setPlane(Pixels pixels,
                         int theZ, int theC, int theT,
                         File file,
                         boolean bigEndian)
        throws ImageServerException, FileNotFoundException
    {
        ImageServer is = activatePixels(pixels);
        is.setPlane(pixels.getImageServerID().longValue(),
                    theZ,theC,theT,file,bigEndian);
    }

    /**
     * <p>This method sends an arbitrary region of pixels for the
     * given pixels ID.  The pixels are specified by a byte array,
     * which should be a raw pixel dump.  The endian-ness of the
     * pixels should be specified.</p>
     *
     * <p>It is up to the caller to ensure that the byte array is of
     * the correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param buf an array of pixels
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     */
    public void setROI(Pixels pixels,
                       int x0,int y0,int z0,int c0,int t0,
                       int x1,int y1,int z1,int c1,int t1,
                       byte[] buf,
                       boolean bigEndian)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        is.setROI(pixels.getImageServerID().longValue(),
                  x0,y0,z0,c0,t0,x1,y1,z1,c1,t1,
                  buf,bigEndian);
    }

    /**
     * <p>This method sends an arbitrary region of pixels for the
     * given pixels ID.  The pixels are specified by a local file,
     * which should be a raw pixel dump.  The endian-ness of the
     * pixels should be specified.</p>
     *
     * <p>It is up to the caller to ensure that the file is of the
     * correct size.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param file a file containing a pixel dump
     * @param bigEndian whether the returns pixels should be in
     * big-endian order
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public void setROI(Pixels pixels,
                       int x0,int y0,int z0,int c0,int t0,
                       int x1,int y1,int z1,int c1,int t1,
                       File file,
                       boolean bigEndian)
        throws ImageServerException, FileNotFoundException
    {
        ImageServer is = activatePixels(pixels);
        is.setROI(pixels.getImageServerID().longValue(),
                  x0,y0,z0,c0,t0,x1,y1,z1,c1,t1,
                  file,bigEndian);
    }

    /**
     * <p>This method ends the writable phase of the life of a pixels
     * file in the image server.</p>
     *
     * <p>Pixels files in the image server can only be written to
     * immediately after they are created.  Once the pixels file is
     * fully populated, it is marked as being completed (via this
     * method).  As this point, all of the writing methods
     * (<code>set*</code>, <code>convert*</code>) become unavailable
     * for the pixels file, and the reading methods
     * (<code>get*</code>) become available.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @throws ImageServerException if there was an error contacting
     * the image server or if the pixels ID does not exist or is not
     * writeable
     */
    public void finishPixels(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        long oldID = pixels.getImageServerID().longValue();
        long newID = is.finishPixels(oldID);
        if (oldID != newID)
            pixels.setImageServerID(new Long(newID));
        String sha1 = is.getPixelsSHA1(newID);
        pixels.setFileSHA1(sha1);
    }

    /**
     * Returns a {@link PlaneStatistics} object containing basic pixel
     * statistics for each plane in the specified pixels file.
     *
     * @param pixels a {@link Pixels} attribute
     */
    public PlaneStatistics getPlaneStatistics(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getPlaneStatistics(pixels.getImageServerID().longValue());
    }

    /**
     * Returns a {@link StackStatistics} object containing basic pixel
     * statistics for each stack in the specified pixels file.
     *
     * @param pixels a {@link Pixels} attribute
     */
    public StackStatistics getStackStatistics(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getStackStatistics(pixels.getImageServerID().longValue());
    }

    /**
     * Composites a single plane of a multi-channel image into a
     * grayscale or RGB image, according to the state of the
     * <code>settings</code> parameter.
     *
     * @param pixels a {@link Pixels} attribute
     * @param settings a {@link CompositingSettings} object describing
     * the compositing which should be performed
     * @return an AWT {@link BufferedImage} suitable for display
     */
    public BufferedImage getComposite(Pixels pixels,
                                      CompositingSettings settings)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getComposite(pixels.getImageServerID().longValue(),settings);
    }


    /**
     * Saves the specified compositing settings as a default.  This
     * allows the {@link #getThumbnail} method to be used to quickly
     * retrieve a standard compositing for an image.
     *
     * @param pixels a {@link Pixels} attribute
     * @param settings a {@link CompositingSettings} object describing
     * the compositing which should be saved
     */
    public void setThumbnail(Pixels pixels,
                             CompositingSettings settings)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        is.setThumbnail(pixels.getImageServerID().longValue(),settings);
    }

    /**
     * Returns a thumbnail for the specified image.  This thumbnail
     * must have been previously set by the {@link #setThumbnail}
     * method.
     *
     * @param pixels a {@link Pixels} attribute
     */
    public BufferedImage getThumbnail(Pixels pixels)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getThumbnail(pixels.getImageServerID().longValue());
    }

    /**
     * Returns a thumbnail for the specified image of the requested
     * size.  This thumbnail must have been previously set by the
     * {@link #setThumbnail} method.  The thumbnail will be no larger
     * than the specified dimensions; its aspect ratio will match that
     * of the XY plane of the pixels file.
     *
     * @param pixels a {@link Pixels} attribute
     * @param sizeX the width of the desired thumbnail
     * @param sizeY the height of the desired thumbnail
     */
    public BufferedImage getThumbnail(Pixels pixels, int sizeX, int sizeY)
        throws ImageServerException
    {
        ImageServer is = activatePixels(pixels);
        return is.getThumbnail(pixels.getImageServerID().longValue(),
                               sizeX,sizeY);
    }

    /**
     */
    public Repository findRepository(long fileSize)
        throws ImageServerException
    {
        Criteria crit = new Criteria();
        crit.addWantedField("id");
        crit.addWantedField("ImageServerURL");
        crit.addFilter("IsLocal",Boolean.FALSE);

        Repository result = (Repository) factory.retrieve("Repository",crit);
        if (result == null)
            throw new ImageServerException("Could not find a repository");
        return result;
    }

    /**
     * <p>Transfers the specified file to the image server, returning
     * an image server ID.  This method does not create an
     * OriginalFile attribute for the uploaded file.  For this, call
     * the {@link #uploadFile(Repository,ModuleExecution,File)}
     * method.</p>
     *
     * @param repository the repository to upload to
     * @param file the file to upload
     * @return the image server ID of the file
     * @throws ImageServerException if there was an error contacting
     * the image server or uploading the file
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public long uploadFile(Repository repository,
                           File file)
        throws ImageServerException, FileNotFoundException
    {
        if (repository == null)
            throw new IllegalArgumentException("Repository cannot be null");

        ImageServer is = activateRepository(repository);
        long fileID = is.uploadFile(file);

        return fileID;
    }

    /**
     * <p>Transfers the specified file to the image server, returning
     * an {@link OriginalFile} attribute.  This object can then be
     * used in calls to the <code>convert*</code> methods, allowing a
     * new pixels file to be created from the contents of the original
     * file.</p>
     *
     * @param repository the repository to upload to
     * @param file the file to upload
     * @return an {@link OriginalFile} attribute
     * @throws ImageServerException if there was an error contacting
     * the image server or uploading the file
     * @throws FileNotFoundException if the specified file cannot be
     * read
     */
    public OriginalFile uploadFile(Repository repository,
                                   ModuleExecution mex,
                                   File file)
        throws ImageServerException, FileNotFoundException
    {
        if (repository == null)
            throw new IllegalArgumentException("Repository cannot be null");

        ImageServer is = activateRepository(repository);
        long fileID = is.uploadFile(file);
        String sha1 = is.getFileSHA1(fileID);

        OriginalFile fileAttr = (OriginalFile) factory.createNew("OriginalFile");
        fileAttr.setRepository(repository);
        fileAttr.setModuleExecution(mex);
        fileAttr.setFileID(new Long(fileID));
        fileAttr.setSHA1(sha1);
        factory.markForUpdate(fileAttr);

        return fileAttr;
    }

    /**
     * Returns the original filename and length of a previously
     * uploaded file.
     *
     * @param file an {@link OriginalFile} attribute
     * @return a {@link FileInfo} object describing the file
     * @throws ImageServerException if there was an error contacting
     * the image server or retrieving the file
     */
    public FileInfo getFileInfo(OriginalFile file)
        throws ImageServerException
    {
        ImageServer is = activateOriginalFile(file);
        return is.getFileInfo(file.getFileID().longValue());
    }

    /**
     * Returns the SHA-1 digest of a previously uploaded file.  This
     * SHA-1 is also cached in the <code>SHA1</code> element of the
     * OriginalFile attribute, so this method will rarely need to be
     * called.
     *
     * @param file an {@link OriginalFile} attribute
     * @return the SHA-1 digest of the pixels file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the file ID does not exist
     */
    public String getFileSHA1(OriginalFile file)
        throws ImageServerException
    {
        ImageServer is = activateOriginalFile(file);
        return is.getFileSHA1(file.getFileID().longValue());
    }

    /**
     * Returns the location of the specified file in the image
     * server's filesystem.
     * @param file an {@link OriginalFile} attribute
     * @return the image-server-local path to the file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the file ID does not exist
     */
    public String getFileServerPath(OriginalFile file)
        throws ImageServerException
    {
        ImageServer is = activateOriginalFile(file);
        return is.getFileServerPath(file.getFileID().longValue());
    }

    /**
     * Reads a portion of an uploaded file, without using any caching.
     * This is usually not the method you should use to read from an
     * image server file; the {@link #readFile} method implements a
     * limited form of caching and can be much more efficient.
     *
     * @see #readFile
     * @param file an {@link OriginalFile} attribute
     * @param offset the offset into the file to start reading from
     * @param length the number of bytes to read from the file
     * @return the data read from the file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the file ID does not exist
     */
    public byte[] readFileWithoutCaching(OriginalFile file,
                                         long offset,
                                         int  length)
        throws ImageServerException
    {
        ImageServer is = activateOriginalFile(file);
        return is.readFileWithoutCaching(file.getFileID().longValue(),
                                         offset,length);
    }

    /**
     * <p>Reads a portion of an uploaded file.  The method implements
     * a limited form of caching, so that client code can read small,
     * spatially related portions of the file without generating too
     * many I/O calls to the image server.</p>
     *
     * <p>The caching is implemented entirely by the {@link
     * ImageServer} instance of the OriginalFile's repository.  Please
     * see the {@link ImageServer#readFile} method for more
     * information.</p>
     *
     * <p><b>This method is not thread-safe</b>; it is up to the
     * caller to perform any necessary synchronization.  If multiple
     * threads try to call this method simultaneously, Bad Things
     * could happen.</p>
     *
     * @see ImageServer#readFile
     * @param file an {@link OriginalFile} attribute
     * @param offset the offset into the file to start reading from
     * @param length the number of bytes to read from the file
     * @return the data read from the file
     * @throws ImageServerException if there was an error contacting
     * the image server or if the file ID does not exist
     */
    public byte[] readFile(OriginalFile file,
                           long offset, int length)
        throws ImageServerException
    {
        ImageServer is = activateOriginalFile(file);
        return is.readFile(file.getFileID().longValue(),
                           offset,length);
    }

    /**
     * <p>Copies pixels from an original file into a new pixels file.
     * The original file should have been previously uploaded via the
     * {@link #uploadFile} method.  The pixels file should have been
     * previously created via the {@link #newPixels} method.  The
     * server will start reading the pixels from the specified offset,
     * which should be expressed as bytes from the beginning of the
     * file.</p>
     *
     * <p>This method copies a single XYZ stack of pixels.  The pixels
     * in the original file should be in XYZ order, and should match
     * the storage type declared for the new pixels file.  The stack
     * is specified by its C and T coordinates, which have 0-based
     * indices.  The endian-ness of the uploaded file should be
     * specified; if this differs from the endian-ness of the new
     * pixels file, byte swapping will be performed by the server.</p>
     *
     * <p>If the specified pixel file isn't in write-only mode on the
     * image server, an error will be thrown.</p>
     *
     * <p>The number of pixels successfully written by the image
     * server will be returned.  This value can be used as an
     * additional error check by client code.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theC the C index of the desired stack
     * @param theT the T index of the desired stack
     * @param file an {@link OriginalFile} attribute
     * @param offset the offset into the file to start reading from
     * @param bigEndian the endianness of the pixels in the uploaded
     * file
     */
    public long convertStack(Pixels pixels,
                             int theC, int theT,
                             OriginalFile file, long offset,
                             boolean bigEndian)
        throws ImageServerException
    {
        ImageServer pis = activatePixels(pixels);
        ImageServer fis = activateOriginalFile(file);

        if (!pis.equals(fis))
            throw new ImageServerException("Original file and pixels file must be on same image server");

        return pis.convertStack(pixels.getImageServerID().longValue(),
                                theC,theT,
                                file.getFileID().longValue(),
                                offset,bigEndian);
    }

    /**
     * <p>Copies pixels from an original file into a new pixels file.
     * The original file should have been previously uploaded via the
     * {@link #uploadFile} method.  The pixels file should have been
     * previously created via the {@link #newPixels} method.  The
     * server will start reading the pixels from the specified offset,
     * which should be expressed as bytes from the beginning of the
     * file.</p>
     *
     * <p>This method copies a single XY plane of pixels.  The pixels
     * in the original file should be in XY order, and should match
     * the storage type declared for the new pixels file.  The plane
     * is specified by its Z, C and T coordinates, which have 0-based
     * indices.  The endian-ness of the uploaded file should be
     * specified; if this differs from the endian-ness of the new
     * pixels file, byte swapping will be performed by the server.</p>
     *
     * <p>If the specified pixel file isn't in write-only mode on the
     * image server, an error will be thrown.</p>
     *
     * <p>The number of pixels successfully written by the image
     * server will be returned.  This value can be used as an
     * additional error check by client code.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the Z index of the desired plane
     * @param theC the C index of the desired plane
     * @param theT the T index of the desired plane
     * @param file an {@link OriginalFile} attribute
     * @param offset the offset into the file to start reading from
     * @param bigEndian the endianness of the pixels in the uploaded
     * file
     */
    public long convertPlane(Pixels pixels,
                             int theZ, int theC, int theT,
                             OriginalFile file, long offset,
                             boolean bigEndian)
        throws ImageServerException
    {
        ImageServer pis = activatePixels(pixels);
        ImageServer fis = activateOriginalFile(file);

        if (!pis.equals(fis))
            throw new ImageServerException("Original file and pixels file must be on same image server");

        return pis.convertPlane(pixels.getImageServerID().longValue(),
                                theZ,theC,theT,
                                file.getFileID().longValue(),
                                offset,bigEndian);
    }

    /**
     * <p>Copies pixels from an original file into a new pixels file.
     * The original file should have been previously uploaded via the
     * {@link #uploadFile} method.  The pixels file should have been
     * previously created via the {@link #newPixels} method.  The
     * original file should be in the TIFF format, and should contain
     * exactly one plane of pixel data.  This plane should have the
     * same size as an XY plane in the pixels file.</p>
     *
     * <p>This method copies a single XY plane of pixels.  The plane
     * is specified by its Z, C and T coordinates, which have 0-based
     * indices.  The endian-ness of the uploaded file is encoded in
     * the TIFF header, and does not need to be specified.  If this
     * differs from the endian-ness of the new pixels file, byte
     * swapping will be performed by the server.</p>
     *
     * <p>If the specified pixel file isn't in write-only mode on the
     * image server, an error will be thrown.</p>
     *
     * <p>The number of pixels successfully written by the image
     * server will be returned.  This value can be used as an
     * additional error check by client code.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the Z index of the desired plane
     * @param theC the C index of the desired plane
     * @param theT the T index of the desired plane
     * @param file an {@link OriginalFile} attribute
     */
    public long convertPlaneFromTIFF(Pixels pixels,
                                     int theZ, int theC, int theT,
                                     OriginalFile file)
        throws ImageServerException
    {
        ImageServer pis = activatePixels(pixels);
        ImageServer fis = activateOriginalFile(file);

        if (!pis.equals(fis))
            throw new ImageServerException("Original file and pixels file must be on same image server");

        return pis.convertPlaneFromTIFF(pixels.getImageServerID().longValue(),
                                        theZ,theC,theT,
                                        file.getFileID().longValue());
    }

    /**
     * <p>Copies pixels from an original file into a new pixels file.
     * The original file should have been previously uploaded via the
     * {@link #uploadFile} method.  The pixels file should have been
     * previously created via the {@link #newPixels} method.  The
     * original file should be in the TIFF format, and can contain
     * multiple planes of pixel data.  These planes should be stored
     * as separate entries in the TIFF file's directory.  The plane to
     * be copied is specified by the <code>directory</code> parameter,
     * which is a 0-based index into the TIFF directory.  The plane
     * should have the same size as an XY plane in the pixels
     * file.</p>
     *
     * <p>This method copies a single XY plane of pixels.  The plane
     * is specified by its Z, C and T coordinates, which have 0-based
     * indices.  The endian-ness of the uploaded file is encoded in
     * the TIFF header, and does not need to be specified.  If this
     * differs from the endian-ness of the new pixels file, byte
     * swapping will be performed by the server.</p>
     *
     * <p>If the specified pixel file isn't in write-only mode on the
     * image server, an error will be thrown.</p>
     *
     * <p>The number of pixels successfully written by the image
     * server will be returned.  This value can be used as an
     * additional error check by client code.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theZ the Z index of the desired plane
     * @param theC the C index of the desired plane
     * @param theT the T index of the desired plane
     * @param file an {@link OriginalFile} attribute
     * @param directory the index into the TIFF directory of the plane
     * to copy
     */
    public long convertPlaneFromTIFF(Pixels pixels,
                                     int theZ, int theC, int theT,
                                     OriginalFile file,
                                     int directory)
        throws ImageServerException
    {
        ImageServer pis = activatePixels(pixels);
        ImageServer fis = activateOriginalFile(file);

        if (!pis.equals(fis))
            throw new ImageServerException("Original file and pixels file must be on same image server");

        return pis.convertPlaneFromTIFF(pixels.getImageServerID().longValue(),
                                        theZ,theC,theT,
                                        file.getFileID().longValue(),
                                        directory);
    }

    /**
     * <p>Copies pixels from an original file into a new pixels file.
     * The original file should have been previously uploaded via the
     * {@link #uploadFile} method.  The pixels file should have been
     * previously created via the {@link #newPixels} method.  The
     * server will start reading the pixels from the specified offset,
     * which should be expressed as bytes from the beginning of the
     * file.</p>
     *
     * <p>This method copies a subset of rows of a single plane of
     * pixels.  The pixels in the original file should be in XY order,
     * and should match the storage type declared for the new pixels
     * file.  The rows are specified by their Z, C and T coordinates,
     * and by an initial Y coordinate and number of rows to copy.  All
     * of the coordinates have 0-based indices.  The endian-ness of
     * the uploaded file should be specified; if this differs from the
     * endian-ness of the new pixels file, byte swapping will be
     * performed by the server.</p>
     *
     * <p>If the specified pixel file isn't in write-only mode on the
     * image server, an error will be thrown.</p>
     *
     * <p>The number of pixels successfully written by the image
     * server will be returned.  This value can be used as an
     * additional error check by client code.</p>
     *
     * @param pixels a {@link Pixels} attribute
     * @param theY the first row of the desired region
     * @param numRows the number of rows in the desired region
     * @param theZ the Z index of the desired region
     * @param theC the C index of the desired region
     * @param theT the T index of the desired region
     * @param file an {@link OriginalFile} attribute
     * @param offset the offset into the file to start reading from
     * @param bigEndian the endianness of the pixels in the uploaded
     * file
     */
    public long convertRows(Pixels pixels,
                            int theY, int numRows,
                            int theZ, int theC, int theT,
                            OriginalFile file, long offset,
                            boolean bigEndian)
        throws ImageServerException
    {
        ImageServer pis = activatePixels(pixels);
        ImageServer fis = activateOriginalFile(file);

        if (!pis.equals(fis))
            throw new ImageServerException("Original file and pixels file must be on same image server");

        return pis.convertRows(pixels.getImageServerID().longValue(),
                               theY,numRows,theZ,theC,theT,
                               file.getFileID().longValue(),
                               offset,bigEndian);
    }

}