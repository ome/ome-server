function ang = findOrientationAngle(input_img)

% INPUT         input_img   - image to be rotated
% OUTPUT        output_img  - rotated input img
% NOTES
%   This code looks for a 'center line of mass' and rotates the image so that this line is parallel
%   to the horizon.  This was tailored to work on fluoresent images of c.elegans (using the
%   sarcomeres to find central lines).  This rotation is critical for eigenface reconstruction of
%   worms.  If all of the worms are rotated all over the screen, you can't come up with a
%   representative mean image.  The output image is returned as a square whose dimension is equal in
%   length to the smallest side of the input image.  The rotated image is centered in this square.
% REVISIONS
%   (1) - v.1
%   (2) - fixing bug that causes images to be too off center to be returned as non-squares.
%   (3) - fixed rotational issues
%   (4) - don't actually do the rotation but return only a rotation angle.
%   This way certain preprocessing steps don't screw up orientation.
%   Lawrence David - 2003. lad2002@columbia.edu
%   Tom Macura - 2004 tm289@cam.ac.uk

input_img_doub  = double(input_img);      % matlab doesnt like singles
[hei len]       = size(input_img_doub);
smaller_dim     = min([hei len]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% making sure that only strong signals influence rotation       %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[junk junk treasure] = find(input_img_doub);                   % finding non-zeros
max_pow = mean(treasure) + std(treasure);                      % what's cutoff to be special
input_img_doub = input_img_doub.*(input_img_doub > max_pow);   % keeping only those above the threshold

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% finding the 'vertical' line and 'horizontal' line             %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hc = 1:hei;
lc = 1:len;
hv = 2:5:hei-1;                              % can skip a couple of points
lv = 2:5:len-1;

for i = 1:length(lv)                         % looking horizontally  
    denom = sum(input_img_doub(:,lv(i)));    % finding all of the centers of mass
    if denom == 0
        comh(i) = 0;
    else
        xcl = hc'.*input_img_doub(:,lv(i));
        comh(i) = sum(xcl)/denom;
    end
end

for i = 1:length(hv)                         % looking vertically
    denom = sum(input_img_doub(hv(i),:));    % more centers of mass
    if denom == 0
        coml(i) = 0;
    else
        xch = lc.*input_img_doub(hv(i),:);
        coml(i) = sum(xch)/denom;
    end
end

lv      = lv(find(comh));               % keeping only centers of mass that
comh    = comh(find(comh));             % weren't calculated over a bunch of zeros
hv      = hv(find(coml));
coml    = coml(find(coml));
nlvl    = length(lv);
nlhl    = length(hv);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure out the rotation angle                                 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
if nlvl*(hei/len) > nlhl                            % rotate depending on whether the 'horizontal' or 
    P = polyfit(lv,comh,1);                         % 'vertical' line was longer
    ang = atan(P(1))*180/pi;                        % Remember trig?
    if P(1) < .5
        ang = ang;
    else
        ang = -ang + 90;
    end
else
    P = polyfit(hv,coml,1);
    ang = atan(P(1))*180/pi;
    if P(1) < 0
        ang = -ang + 90;
    else
        ang = -ang + 90;
    end
end