/*
 * org.openmicroscopy.is.tests.Blackguard
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




package org.openmicroscopy.is.tests;

import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import org.openmicroscopy.is.*;

public class Blackguard
    implements ActionListener
{
    public static void main(String[] args)
    {
        Blackguard bg = new Blackguard();
    }

    BlackguardControlFrame bcf = null;
    BlackguardImageFrame bif = null;
    ImageServer is = null;

    private Blackguard()
    {
        super();

        is = ImageServer.getDefaultImageServer();

        bcf = new BlackguardControlFrame(this);
        bcf.pack();
        bcf.setVisible(true);

        bif = new BlackguardImageFrame();
        bif.setSize(400,400);
        bif.setLocation(bcf.getWidth()+10,0);
        bif.setVisible(true);
    }

    public void actionPerformed(ActionEvent e)
    {
        String cmd = e.getActionCommand();

        if (cmd.equals("quit"))
            System.exit(0);

        if (cmd.equals("update"))
        {
            CompositingSettings cs = null;
            long pixelsID = 0;
            Image image = null;

            try
            {
                cs = createCompositingSettings();
                pixelsID = Long.parseLong(bcf.tfPixelsID.getText());
                image = is.getComposite(pixelsID,cs);
            } catch (Exception ex) {
                ex.printStackTrace();
                return;
            }

            if (image != null)
                bif.setImage(image);
        }
    }

    private CompositingSettings createCompositingSettings()
        throws NumberFormatException
    {
        CompositingSettings cs = new CompositingSettings();
        cs.setLevelBasis(bcf.cbLevelBasis.getSelectedIndex());

        if (bcf.jTabbedPane1.getSelectedIndex() == 0)
        {
            // Grayscale
            cs.activateGrayChannel
                (Integer.parseInt(bcf.tfGrayChannel.getText()),
                 Float.parseFloat(bcf.tfGrayBlackLevel.getText()),
                 Float.parseFloat(bcf.tfGrayWhiteLevel.getText()),
                 1.0F);
        } else {
            if (bcf.cbRedOn.isSelected())
            {
                cs.activateRedChannel
                    (Integer.parseInt(bcf.tfRedChannel.getText()),
                     Float.parseFloat(bcf.tfRedBlackLevel.getText()),
                     Float.parseFloat(bcf.tfRedWhiteLevel.getText()),
                     1.0F);
            }

            if (bcf.cbGreenOn.isSelected())
            {
                cs.activateGreenChannel
                    (Integer.parseInt(bcf.tfGreenChannel.getText()),
                     Float.parseFloat(bcf.tfGreenBlackLevel.getText()),
                     Float.parseFloat(bcf.tfGreenWhiteLevel.getText()),
                     1.0F);
            }

            if (bcf.cbBlueOn.isSelected())
            {
                cs.activateBlueChannel
                    (Integer.parseInt(bcf.tfBlueChannel.getText()),
                     Float.parseFloat(bcf.tfBlueBlackLevel.getText()),
                     Float.parseFloat(bcf.tfBlueWhiteLevel.getText()),
                     1.0F);
            }
        }

        return cs;
    }
}
