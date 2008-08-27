/*
 * org.openmicroscopy.is.CompositingSettings
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

/**
 * Encapsulates the settings required to composite an image on the
 * image server into a visible image.  This does not yet incorporate
 * the new display options provided by Jean-Marie's viewer, nor does
 * it work in terms of a DisplayOptions attribute from the OME
 * database.  This class deals strictly with the values that the image
 * server knows how to handle.  The Data Management service in the
 * Shoola client is an example of constructing one of these objects
 * from a DisplayOptions attribute.
 *
 * @author Douglas Creager (dcreager@alum.mit.edu)
 * @version 2.2 <i>(Internal: $Revision $ $Date $)</i>
 * @since OME2.2
 */

public class CompositingSettings
{
    /**
     * Specifies that the black and white levels are expressed in
     * absolute pixel values.
     */
    public static final int ABSOLUTE = 0;

    /**
     * Specifies that the black and white levels are expressed in
     * standard deviations from the arithmetic mean.
     */
    public static final int MEAN = 1;

    /**
     * Specifies that the black and white levels are expressed in
     * geometric standard deviations from the geometric mean.
     */
    public static final int GEOMETRIC_MEAN = 2;

    private static final String[] LEVEL_BASES =
    { "fixed","mean","geomean" };

    private static final float MIN_PGI = -4.0F;
    private static final float MAX_PGI =  4.0F;

    /**
     * The index of the Z-slice to view.
     */
    private int theZ;

    /**
     * The index of the time-slice to view.
     */
    private int theT;

    /**
     * Whether to scale the image.  The default of false causes the
     * image plane to be returned full-size.
     */
    private boolean resize = false;

    /**
     * If scaling is on, specifies the desired X size of the image.
     */
    private int sizeX;

    /**
     * If scaling is on, specifies the desired Y size of the image.
     */
    private int sizeY;

    /**
     * Specifies whether the black and white levels for each channel
     * are expressed as absolute or relative values.
     * @see #ABSOLUTE
     * @see #MEAN
     * @see #GEOMETRIC_MEAN
     */
    private int levelBasis = ABSOLUTE;

    /**
     * Whether the gray channel is active.  If the gray channel is on,
     * then the red, green, and blue channels must be off.
     */
    private boolean grayChannelOn = false;

    /**
     * Specifies which channel is displayed in gray.
     */
    private int grayChannel;

    /**
     * Specifies the black level for the gray channel.
     */
    private float grayBlackLevel;

    /**
     * Specifies the white level for the gray channel.
     */
    private float grayWhiteLevel;

    /**
     * Specifies the gamma value for the gray channel.
     */
    private float grayGamma;

    /**
     * Whether the red channel is active.  If the red channel is on,
     * then the gray channel must be off.
     */
    private boolean redChannelOn = false;

    /**
     * Specifies which channel is displayed in gray.
     */
    private int redChannel;

    /**
     * Specifies the black level for the red channel.
     */
    private float redBlackLevel;

    /**
     * Specifies the white level for the red channel.
     */
    private float redWhiteLevel;

    /**
     * Specifies the gamma value for the red channel.
     */
    private float redGamma;

    /**
     * Whether the green channel is active.  If the green channel is on,
     * then the gray channel must be off.
     */
    private boolean greenChannelOn = false;

    /**
     * Specifies which channel is displayed in gray.
     */
    private int greenChannel;

    /**
     * Specifies the black level for the green channel.
     */
    private float greenBlackLevel;

    /**
     * Specifies the white level for the green channel.
     */
    private float greenWhiteLevel;

    /**
     * Specifies the gamma value for the green channel.
     */
    private float greenGamma;

    /**
     * Whether the blue channel is active.  If the blue channel is on,
     * then the gray channel must be off.
     */
    private boolean blueChannelOn = false;

    /**
     * Specifies which channel is displayed in gray.
     */
    private int blueChannel;

    /**
     * Specifies the black level for the blue channel.
     */
    private float blueBlackLevel;

    /**
     * Specifies the white level for the blue channel.
     */
    private float blueWhiteLevel;

    /**
     * Specifies the gamma value for the blue channel.
     */
    private float blueGamma;

    /**
     * Creates a default <code>CompositingSettings</code> instance,
     * which would display Z-index 0 and time-index 0.
     */
    public CompositingSettings()
    {
        super();
        this.theZ = 0;
        this.theT = 0;
    }

    /**
     * Creates a <code>CompositingSettings</code> instance which would
     * display the specified Z and time indices.
     */
    public CompositingSettings(int theZ, int theT)
    {
        super();
        this.theZ = theZ;
        this.theT = theT;
    }

    public static CompositingSettings
    createDefaultPGISettings(int sizeZ, int sizeC, int sizeT)
    {
        if (sizeZ <= 0)
            throw new IllegalArgumentException("Z size must be positive");
        if (sizeC <= 0)
            throw new IllegalArgumentException("C size must be positive");
        if (sizeT <= 0)
            throw new IllegalArgumentException("T size must be positive");

        CompositingSettings cs = new CompositingSettings(sizeZ/2,sizeT/2);

        cs.setLevelBasis(GEOMETRIC_MEAN);

        if (sizeC == 1)
        {
            cs.activateGrayChannel(0,MIN_PGI,MAX_PGI,1.0F);
        } else {
            if (sizeC > 0)
                cs.activateRedChannel(0,MIN_PGI,MAX_PGI,1.0F);
            if (sizeC > 1)
                cs.activateGreenChannel(0,MIN_PGI,MAX_PGI,1.0F);
            if (sizeC > 2)
                cs.activateBlueChannel(0,MIN_PGI,MAX_PGI,1.0F);
        }

        return cs;
    }

    /**
     * Returns the level basis, which specifies whether the black and
     * white levels for each channel are specified as absolute or
     * relative values.  The level basis can be {@link #ABSOLUTE} (the
     * default), {@link #MEAN}, or {@link #GEOMETRIC_MEAN}.
     */
    public int getLevelBasis() { return levelBasis; }

    /**
     * Sets the level basis.
     * @see #getLevelBasis
     */
    public void setLevelBasis(int levelBasis)
    {
        if (levelBasis != ABSOLUTE &&
            levelBasis != MEAN &&
            levelBasis != GEOMETRIC_MEAN)
        {
            throw new IllegalArgumentException("Invalid level basis");
        }

        this.levelBasis = levelBasis;
    }

    public String getLevelBasisSpec() { return LEVEL_BASES[levelBasis]; }

    public int getTheZ() { return theZ; }

    public void setTheZ(int theZ) { this.theZ = theZ; }

    public int getTheT() { return theT; }

    public void setTheT(int theT) { this.theT = theT; }

    public void useFullSize() { resize = false; }

    public void resizeImage(int sizeX, int sizeY)
    {
        this.resize = true;
        this.sizeX = sizeX;
        this.sizeY = sizeY;
    }

    public boolean isResized() { return resize; }

    public String getSizeSpec()
    {
        return
            Integer.toString(sizeX)+","+
            Integer.toString(sizeY);
    }

    /**
     * Activates the gray channel for these compositing settings.
     * This automatically deactivates the red, green, and blue
     * channels if they were previously on.
     */
    public void activateGrayChannel(int channel,
                                    float black, float white,
                                    float gamma)
    {
        redChannelOn = false;
        greenChannelOn = false;
        blueChannelOn = false;

        grayChannelOn = true;
        grayChannel = channel;
        grayBlackLevel = black;
        grayWhiteLevel = white;
        grayGamma = gamma;
    }

    /**
     * Activates the red channel for these compositing settings.  This
     * automatically deactivates the gray channel if it was previously
     * on.
     */
    public void activateRedChannel(int channel,
                                   float black, float white,
                                   float gamma)
    {
        grayChannelOn = false;

        redChannelOn = true;
        redChannel = channel;
        redBlackLevel = black;
        redWhiteLevel = white;
        redGamma = gamma;
    }

    /**
     * Activates the green channel for these compositing settings.  This
     * automatically deactivates the gray channel if it was previously
     * on.
     */
    public void activateGreenChannel(int channel,
                                     float black, float white,
                                     float gamma)
    {
        grayChannelOn = false;

        greenChannelOn = true;
        greenChannel = channel;
        greenBlackLevel = black;
        greenWhiteLevel = white;
        greenGamma = gamma;
    }

    /**
     * Activates the blue channel for these compositing settings.  This
     * automatically deactivates the gray channel if it was previously
     * on.
     */
    public void activateBlueChannel(int channel,
                                    float black, float white,
                                    float gamma)
    {
        grayChannelOn = false;

        blueChannelOn = true;
        blueChannel = channel;
        blueBlackLevel = black;
        blueWhiteLevel = white;
        blueGamma = gamma;
    }

    public boolean isGrayChannelOn() { return grayChannelOn; }
    public boolean isRedChannelOn() { return redChannelOn; }
    public boolean isGreenChannelOn() { return greenChannelOn; }
    public boolean isBlueChannelOn() { return blueChannelOn; }

    public String getGrayChannelSpec()
    {
        return
            Integer.toString(grayChannel)+","+
            Float.toString(grayBlackLevel)+","+
            Float.toString(grayWhiteLevel)+","+
            Float.toString(grayGamma);
    }

    public String getRedChannelSpec()
    {
        return
            Integer.toString(redChannel)+","+
            Float.toString(redBlackLevel)+","+
            Float.toString(redWhiteLevel)+","+
            Float.toString(redGamma);
    }

    public String getGreenChannelSpec()
    {
        return
            Integer.toString(greenChannel)+","+
            Float.toString(greenBlackLevel)+","+
            Float.toString(greenWhiteLevel)+","+
            Float.toString(greenGamma);
    }

    public String getBlueChannelSpec()
    {
        return
            Integer.toString(blueChannel)+","+
            Float.toString(blueBlackLevel)+","+
            Float.toString(blueWhiteLevel)+","+
            Float.toString(blueGamma);
    }
}
