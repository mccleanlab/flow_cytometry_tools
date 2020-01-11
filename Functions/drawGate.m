function gateOut = drawGate(channels2gate, channels2scale)
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
    
    % Scale data if necessary
    if strcmp(channels2scale(nGate,1),'log')
        xdata = fcsdat(:,cX);
        xdata(xdata<=0) = nan;
        xdata = log10(xdata);
    else
        xdata = fcsdat(:,cX);
    end
    
    if strcmp(channels2scale(nGate,2),'log')
        ydata = fcsdat(:,cY);
        ydata(ydata<=0) = nan;
        ydata = log10(ydata);
    else
        ydata = fcsdat(:,cY);
    end
    
    if nGate>1
        idxp = gate{nGate-1,4};
        xdata = xdata(idxp);
        ydata = ydata(idxp);
    end
    
    n0 = length(xdata);
    edgeidx = any([xdata==max(xdata), ydata==max(ydata)],2);
    nbins = round(n0/100);
    
    clear g
    g = gramm('x',xdata(~edgeidx),'y',ydata(~edgeidx));
    g.stat_bin2d('nbins',[nbins nbins],'geom','image');
    g.no_legend();
    figure('Position',[100 100 800 800])
    g.set_names('x',channels2gate{1},'y',channels2gate{1});
    g.draw();
    xlim auto
    ylim auto
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1))
    
    % Show points beyond plot edge
    hold on;
    scatter(xdata(edgeidx),ydata(edgeidx),'r.')
    xlabel([fcshdr.par(cX).name newline '(' num2str(100*sum(edgeidx)/numel(xdata)) '% of points beyond plot edges)']);
    ylabel(fcshdr.par(cY).name);
    
    % Draw gate
    gatePts = drawpolygon('Color',[255 94 105]./255);
    pause
    gatePts = gatePts.Position;
    gatePts = [gatePts; gatePts(1,:)];
    idx = inpolygon(xdata, ydata, gatePts(:,1),gatePts(:,2));
    
    % Show points within gate
    nf = length(xdata(idx));
    scatter(xdata(idx),ydata(idx),10,'filled','MarkerFaceColor',[255 94 105]./255) ;
    xlabel([fcshdr.par(cX).name newline '(' num2str(n0) ' cells before gate, ' num2str(nf) ' cells after gate)'])
    pause
    
    gate{nGate,1} = channels2gate(nGate,:);
    gate{nGate,2} = channels2scale(nGate,:);
    gate{nGate,3} = {gatePts};
    gate{nGate,4} = idx;
    
    gateOut = gate(:,1:3);
    close all
end

save(['gate_' files{1} '.mat'],'gateOut')