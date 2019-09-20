%%
clc
clearvars -except data

x = data.BL2H;
x(x<=0)=nan;
x = log(x);

y = data.FSCH;
y(y<=0)=nan;

nevents = length(x);
fevents = 0.3;

h = histogram2(x,y,100);
xbins = h.XBinEdges;
ybins = h.YBinEdges;
cts = h.Values;

ctlist = cts(:);

% n2 = imgaussfilt(n,3);
% surf(n2,'edgecolor','none')

ctlist = sort(ctlist,'descend');
ctlist = unique(ctlist,'stable');

data.densitygate(:,1) = 0;

for i = 1%:numel(ctlist)
    val = ctlist(i);
    [xloc, yloc] = find(cts>=val);
    xval = min(xbins(xloc));
    yval = min(ybins(yloc));
    xx = x>xval & ~isnan(x);
    yy = y>yval & ~isnan(y);
    idx = any([xx,yy],2);
end

data.idx = idx;
histogram2(x,y,100);


return
%% Add labels to data for plotting
g = gramm('x',x,'y',y,'color', idx, 'subset', data.FSCH>0 & data.BL2H>0);
nbins = 1000;
g.stat_bin2d('nbins',[nbins nbins]);
g.geom_point();
g.draw();
xlim auto
ylim auto