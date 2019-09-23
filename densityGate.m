% function gateOut = densityGate(channels2gate, channels2scale, threshold)
clearvars
channels2gate = {'FSC-A', 'SSC-A'}%; 'FSC-A', 'FSC-H'; 'BL2-H', 'FSC-H'};
channels2scale = {'linear', 'linear'}%; 'linear', 'linear'; 'log', 'linear'};
threshhold = 0.5;

% Load fcs file
[files, folder] = uigetfile('.fcs','Select a .fcs file to gate');

if ischar(files)==1
    files = {files};
else
    files = files';
end

[fcsdat, fcshdr] = fca_readfcs([folder files{1}]);

for nGate = 1:size(channels2gate,1)
    
    % Get index of channels for gating
    cX = find(strcmp({fcshdr.par.name},channels2gate(nGate,1))==1);
    cY = find(strcmp({fcshdr.par.name},channels2gate(nGate,2))==1);
    
    xdata = fcsdat(:,cX);
    xdata(xdata<=0)=nan;
    xdata(xdata==max(xdata))=nan;    
    ydata = fcsdat(:,cY);
    ydata(ydata<=0)=nan;
    ydata(ydata==max(ydata))=nan;
    
    % Scale data if necessary
    if strcmp(channels2scale(nGate,1),'log')
        xdata = log(xdata);
    end
    
    if strcmp(channels2scale(nGate,2),'log')
        ydata = log(ydata);
    end
    
    if nGate>1
        idxp = gate{nGate-1,3};
        xdata = xdata(idxp);
        ydata = ydata(idxp);
    end
            
    [n, xedge, yedge, xbin, ybin] = histcounts2(xdata,ydata,100,'normalization','probability');
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
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1))
    pause
    hold on
    scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 105]./255);
%     pause
%     close all
end
