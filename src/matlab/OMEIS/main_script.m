% Example script showing off the libraries features

im = uint8(255*sin(meshgrid(1:512,1:512)));
head = MATLABtoOMEISDatatype(class(im));
head.dx = 512; head.dy = 512; head.dz = 1; head.dc=1; head.dt = 1;

is = openConnectionOMEIS('http://localhost/cgi-bin/omeis');
id = newPixels(is, head)
pixelsInfo(is, id)

setPixels (is, id, im)
setROI (is, id, 0, 0, 0, 0, 0, 255, 255, 0, 0, 0, uint8(zeros(256, 256)) );
n_id = finishPixels(is, id)
am = getPixels (is, n_id);
sum(sum(abs(am)-abs(im)))

% type n_id below instead of 78
%http://localhost/cgi-bin/omeis?Method=Composite&PixelsID=78&theZ=0&theT=0&LevelBasis=mean&GrayChannel=0,0,4.5,1.0
