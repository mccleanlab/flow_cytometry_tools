function [idxGate,gate]= fcsGate(fcsdat, fcshdr, cX, cY, s, varargin)
% Based on Megan McClean's findGate.m script

numarg=length(varargin);

figure; hold;
scatter_kde_fast(fcsdat(:,cX), fcsdat(:,cY),s,'filled', 'MarkerSize', 1);
nUngated = length(fcsdat(:,cX));
xlabel(fcshdr.par(cX).name); ylabel(fcshdr.par(cY).name); title([fcshdr.filename newline 'Draw gate'],'Interpreter','none');
legend(['n ungated = ' num2str(nUngated)],'Location','northwest');

if strcmp(fcshdr.par(cX).name,'SSC-A') || strcmp(fcshdr.par(cX).name,'BL2-H') || strcmp(fcshdr.par(cX).name,'YL2-H')
    set(gca,'xscale','log')
end

if strcmp(fcshdr.par(cY).name,'SSC-A') || strcmp(fcshdr.par(cY).name,'BL2-H') || strcmp(fcshdr.par(cY).name,'YL2-H')
    set(gca,'yscale','log')
end

%Get user input for the vertices of polygon surrounding the region of
%interest
[x,y] = ginput();

% Set up the polygon surrounding the points you want:
x = [x; x(1)];
y = [y; y(1)];
gate = [x, y];
idxGate = inpolygon(fcsdat(:,cX), fcsdat(:,cY), x,y);
nGated = length(fcsdat(idxGate,cX));

%display what points are in the polygon
if numarg>0
    if varargin{1}==1
        plot(fcsdat(idxGate,cX), fcsdat(idxGate,cY),'r.')
        legend(['n ungated = ' num2str(nUngated)],['n gated = ' num2str(nGated)],'Location','northwest')
        pause; close all;
    else
        close all;
    end
else
    close all;
end

close all;


