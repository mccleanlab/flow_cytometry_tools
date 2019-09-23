function gateOut = measureRainbowBeads(channels2gate, channels2scale, channels2thresh)

% channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'; 'BL2-H', 'FSC-H'};
% channels2scale = {'linear', 'linear'; 'linear', 'linear'; 'log', 'linear'};
% channels2thresh = [0.7, 0.7, 0.5];
nbins = 256;

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
    thresh = channels2thresh(nGate);
    
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
        %         xdata = xdata(idxp);
        %         ydata = ydata(idxp);
        xdata(idxp)=nan;
        ydata(idxp)=nan;
    end
    
    idxhist = all(~isnan([xdata,ydata]),2); % Index to exclude nans from histcounts
    
    [n, xedge, yedge, xbin, ybin] = histcounts2(xdata(idxhist),ydata(idxhist),nbins,'normalization','probability');
    n = imgaussfilt(n,1.5);
    nlist = sort(n(:),'descend');
    nkeep = cumsum(nlist);
    nkeep = 1:find(nkeep>thresh,1 );
    nkeep = nlist(nkeep);
    nkeep = ismember(n,nkeep);
    
    [i,j] = find(nkeep~=0);
    xbounds = [xedge(i);xedge(i+1)]';
    ybounds = [yedge(j);yedge(j+1)]';
    idx = any(xdata >= xbounds(:,1)' & xdata <= xbounds(:,2)' & ydata >= ybounds(:,1)' & ydata <= ybounds(:,2)', 2);
    
    % Plot
    clear g
    g = gramm('x',xdata,'y',ydata);
    g.stat_bin2d('nbins',[nbins nbins]);
    g.draw();
    xlim auto
    ylim auto
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1))
    pause
    hold on
        
%     scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 255]./255);
%     pause    
    
%     xdata(~idx)=nan;
%     ydata(~idx)=nan;
%     options = statset('MaxIter',10000);
%     gm = fitgmdist([xdata,ydata],2,'Options',options);
%     gmthresh = [0.4 0.6];
%     P = posterior(gm,[xdata,ydata]);
%     idxgm = cluster(gm,[xdata,ydata]);
%     idxboth = find(P(:,1)>=gmthresh(1) & P(:,1)<=gmthresh(2)); 
%     xdata(idxboth)=nan;
%     ydata(idxboth)=nan;
%     
%     d = [norm(nanmean([xdata(idxgm==1),ydata(idxgm==1)])),1;norm(nanmean([xdata(idxgm==2),ydata(idxgm==2)])),2];
%     d = sortrows(d,1,'ascend');    
%     if nGate==1 || nGate==3
%         idx = idxgm==d(2,2);
%     elseif nGate==2
%         idx = idxgm==d(1,2);
%     end
    
    scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 105]./255);
    pause
    close all
    
    gate{nGate,1} = channels2gate(nGate,:);
    gate{nGate,2} = channels2scale(nGate,:);
    gate{nGate,3} = idx;   
    
end

gateOut = gate;