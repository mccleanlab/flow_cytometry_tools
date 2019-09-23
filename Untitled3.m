%%
clc
clearvars -except data
threshhold = 0.5;

xdata = data.SSCH;
xdata(xdata<=0)=nan;
xdata(xdata==max(xdata))=nan;
xdata = log(xdata);
ydata = data.FSCH;
ydata(ydata<=0)=nan;
ydata(ydata==max(ydata))=nan;

[n, xedge, yedge, xbin, ybin] = histcounts2(xdata,ydata,256,'normalization','probability');
n = imgaussfilt(n,1.5);
nlist = sort(n(:),'descend');
nkeep = cumsum(nlist);
nkeep = 1:find(nkeep>threshhold,1 );
nkeep = nlist(nkeep);
nkeep = ismember(n,nkeep);

[i,j] = find(nkeep~=0);
xbounds = [xedge(i);xedge(i+1)]';
ybounds = [yedge(j);yedge(j+1)]';

idx = any(xdata >= xbounds(:,1)' & xdata <= xbounds(:,2)' & ydata >= ybounds(:,1)' & ydata <= ybounds(:,2)', 2);

% Plot
clear g
g = gramm('x',xdata,'y',ydata);
nbins = 1024;
g.stat_bin2d('nbins',[nbins nbins]);
g.draw();
xlim auto
ylim auto
ax = findall(gcf, 'type', 'axes')
delete(ax(1))
pause
hold on
scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 105]./255) ;