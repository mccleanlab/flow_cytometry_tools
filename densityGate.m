function gateOut = densityGate(varargin)

% Instantiate inputParser
p = inputParser;
addRequired(p, 'gateParams', @isstruct)
addParameter(p, 'Folder', '', @isfolder)
addParameter(p, 'File', '', @isfile)
addParameter(p, 'showDensityGatedEvents', false, @islogical);
addParameter(p, 'ClusterMethod', 'GMM', @(s) ismember(s, {'GMM','Agglomerative','kmeans'}));
parse(p, varargin{:});

gateParams = p.Results.gateParams;
channels2gate = gateParams.channels2gate;
channels2scale = gateParams.channelsscale;
fraction2keep = gateParams.fraction2keep;
channels2gmm = gateParams.channels2gmm;
showDensityGatedEvents = p.Results.showDensityGatedEvents;
clusterMethod = p.Results.ClusterMethod;

nbins = 512;

tic
warning('off','stats:gmdistribution:cluster:MissingData');
warning('off','stats:gmdistribution:posterior:MissingData');
warning('off','stats:gmdistribution:MissingData');
warning('off','MATLAB:polyshape:repairedBySimplify')

% Load files
if isfile(p.Results.File)
    [fcsdat, fcshdr] = fca_readfcs(p.Results.File);
else  
    if isfolder(p.Results.Folder)
        [files, folder] = uigetfile([p.Results.Folder '*.fcs'],'Select a .fcs file to gate');
    else
        [files, folder] = uigetfile('.fcs','Select a .fcs file to gate');
    end
    
    if ischar(files)==1
        files = {files};
    else
        files = files';
    end
    [fcsdat, fcshdr] = fca_readfcs([folder files{1}]);
end

% Step through channel pairs and gate
for nGate = 1:size(channels2gate,1)
    
    % Get index of channels for gating
    cX = find(strcmp({fcshdr.par.name},channels2gate(nGate,1))==1);
    cY = find(strcmp({fcshdr.par.name},channels2gate(nGate,2))==1);
    thresh = fraction2keep(nGate);
    
    % Exclude saturated events
    xdata = fcsdat(:,cX);
    ydata = fcsdat(:,cY);
    idx_exclude = any([xdata<=0 | xdata==max(xdata), ydata<=0 | ydata==max(ydata)],2);
    xdata(idx_exclude)=nan;
    ydata(idx_exclude)=nan;
    
    % Scale data if necessary
    if strcmp(channels2scale(nGate,1),'log')
        xdata = log10(xdata);
        xlabelname = ['log(' fcshdr.par(cX).name ')'];
    else
        xlabelname = fcshdr.par(cX).name;
    end
    
    if strcmp(channels2scale(nGate,2),'log')
        ydata = log10(ydata);
        ylabelname = ['log(' fcshdr.par(cY).name ')'];
    else
        ylabelname = fcshdr.par(cY).name;
    end
     
    % Remove data gated out by previous channel pair (if applicable)
    if nGate>1        
        idxp = gate{nGate-1,4};
         assignin('base','testoutput',{idxp,xdata,ydata});  
        xdata(idxp) = nan;
        ydata(idxp) = nan;
    end
    
    % Plot 2d histogram
    clear g
    g = gramm('x',xdata,'y',ydata);
    g.stat_bin2d('nbins',[nbins nbins]);
    g.no_legend();
    figure('Position',[100 100 800 800])
    g.draw();
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1))
    
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
    whos idx
    xdata(~idx)=nan;
    ydata(~idx)=nan;
    
    % Show excluded events
    hold on
    scatter(fcsdat(idx_exclude,cX),fcsdat(idx_exclude,cY),'r.')
    xlabel([xlabelname newline '(' num2str(100*sum(idx_exclude)/numel(xdata)) '% of events beyond plot edges)']);
    ylabel(ylabelname);
    
    % Show density gated events (optional)
    if showDensityGatedEvents==true
        scatter(xdata(idx),ydata(idx),2,'filled','MarkerFaceColor',[255 94 255]./255,'MarkerFaceAlpha',1);
        pause
    end
    
    % Cluster events
    nClusters = channels2gmm(nGate,1);
    event2keep = channels2gmm(nGate,2);
    
    if nClusters~=0
        if strcmp(clusterMethod, 'GMM')
            options = statset('MaxIter',1000);
            %             gm = fitgmdist([xdata,ydata],nClusters,'Options',options,'Replicates',10);
            %             P = posterior(gm,[xdata,ydata]);
            %             idx_cluster = cluster(gm,[xdata,ydata]);
            %             idx_omit = max(P,[],2)<0.75;
            %             xdata(idx_omit) = nan;
            %             ydata(idx_omit) = nan;
            
            gm = fitgmdist(xdata,nClusters,'Options',options,'Replicates',10);
            P = posterior(gm,[xdata]);
            idx_cluster = cluster(gm,[xdata]);
            idx_omit = max(P,[],2)<0.75;
            xdata(idx_omit) = nan;
            ydata(idx_omit) = nan;
        elseif strcmp(clusterMethod, 'Agglomerative')
            idx_cluster = clusterdata([xdata,ydata],'Maxclust',nClusters);
            assignin('base','testoutput',{xdata, ydata, idx_cluster});
        elseif strcmp(clusterMethod, 'kmeans')
            idx_cluster = kmeans([xdata,ydata],5);
                     
        end
        
        % Sort clusters by distance from origin
        d = zeros(3,2);
        for n = 1:nClusters
            d(n,:) = [norm(nanmean([xdata(idx_cluster==n),ydata(idx_cluster==n)])),n];
        end
        d = sortrows(d,1,'ascend');
        
        % Filter out unwanted clusters (if applicable)
        if event2keep==0
            idx = idx_cluster;
        else
            idx = idx_cluster==d(event2keep,2);
        end
        
    elseif nClusters==0
        nClusters = 1;
        gm = {};
    end
    
    % Gate based on clusters
    for n = 1:nClusters
        xpoly = xdata(idx==n);
        xpoly = xpoly(~any(isnan(xpoly) | isinf(xpoly),2),:);
        ypoly = ydata(idx==n);
        ypoly = ypoly(~any(isnan(ypoly) | isinf(ypoly),2),:);
        %         idx_boundary = convhull(xpoly,ypoly);
        idx_boundary = boundary(xpoly,ypoly,0.25);
        gatePts = [xpoly(idx_boundary), ypoly(idx_boundary)];
        idx_poly(:,n) = inpolygon(xdata, ydata, gatePts(:,1),gatePts(:,2));
        pgon(n) = polyshape(gatePts(:,1),gatePts(:,2));
        gatePtsOut{n} = gatePts;
        
    end
    
    idxOut = any(idx_poly,2);
    plot(pgon,'EdgeColor',[255 94 105]./255,'FaceAlpha',0,'LineWidth',1.5);
    xlabel([xlabelname newline '(' num2str(100*sum(idx)/numel(xdata)) '% of events retained)']);
    pause
    
    gate{nGate,1} = channels2gate(nGate,:);
    gate{nGate,2} = channels2scale(nGate,:);
    gate{nGate,3} = gatePtsOut;
    gate{nGate,4} = idxOut;
    gate{nGate,5} = gm;
    
    close all
    
end

gateOut = gate;
toc