function gateOut = densityGate(channels2gate, channels2scale, fraction2keep, channels2gmm)

warning('off','stats:gmdistribution:cluster:MissingData');
warning('off','stats:gmdistribution:posterior:MissingData');
warning('off','stats:gmdistribution:MissingData');

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
    thresh = fraction2keep(nGate);
    
    xdata = fcsdat(:,cX);
    ydata = fcsdat(:,cY);
    idx = any([xdata<=0 | xdata==max(xdata), ydata<=0 | ydata==max(ydata)],2);
    xdata(idx)=nan;
    ydata(idx)=nan;
    
    % Scale data if necessary
    if strcmp(channels2scale(nGate,1),'log')
        xdata = log(xdata);
    end
    
    if strcmp(channels2scale(nGate,2),'log')
        ydata = log(ydata);
    end
    
    % Remove data previously gated out
    if nGate>1
        idxp = gate{nGate-1,4};
        %         xdata = xdata(idxp);
        %         ydata = ydata(idxp);
        xdata(idxp)=nan;
        ydata(idxp)=nan;
    end
    
    % Select high-density data
    idxhist = all(~isnan([xdata,ydata]),2); % Index to exclude nans from histcounts
    [n, xedge, yedge] = histcounts2(xdata(idxhist),ydata(idxhist),nbins,'normalization','probability');
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
    
    ngmm = channels2gmm(nGate,1);
    cgmm = channels2gmm(nGate,2);
    if ngmm~=0
        xdata(~idx)=nan;
        ydata(~idx)=nan;
        options = statset('MaxIter',1000);
        gm = fitgmdist([xdata,ydata],ngmm,'Options',options);
        gmthresh = [0.4 0.6];
        P = posterior(gm,[xdata,ydata]);
        idxgm = cluster(gm,[xdata,ydata]);
        idxboth = find(P(:,1)>=gmthresh(1) & P(:,1)<=gmthresh(2));
        xdata(idxboth)=nan;
        ydata(idxboth)=nan;
        
        d = [norm(nanmean([xdata(idxgm==1),ydata(idxgm==1)])),1;norm(nanmean([xdata(idxgm==2),ydata(idxgm==2)])),2];
        d = sortrows(d,1,'ascend');
        if cgmm==0
            idx = any([~isnan(idxgm) & ~isinf(idxgm)],2);
        elseif cgmm==1
            idx = idxgm==d(1,2);
        elseif cgmm==2
            idx = idxgm==d(2,2);
        end
    else
        gm = {};
    end
    
    if cgmm~=0
        xpoly = xdata(idx);
        xpoly = xpoly(~any(isnan(xpoly) | isinf(xpoly),2),:);
        ypoly = ydata(idx);
        ypoly = ypoly(~any(isnan(ypoly) | isinf(ypoly),2),:);
        gatePts = boundary(xpoly,ypoly,0);
        gatePts = [xpoly(gatePts), ypoly(gatePts)];
        idx = inpolygon(xdata, ydata, gatePts(:,1),gatePts(:,2));
        pgon = polyshape(gatePts);
        plot(pgon,'EdgeColor',[255 94 105]./255,'FaceAlpha',0,'LineWidth',1.5);
    else
        scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 105]./255);
    end
    pause
    close all
    
    gate{nGate,1} = channels2gate(nGate,:);
    gate{nGate,2} = channels2scale(nGate,:);
    gate{nGate,3} = gatePts;
    gate{nGate,4} = idx;
    gate{nGate,5} = gm;
    
end

gateOut = gate;