function h = plotGate(gate)

[files, folder] = uigetfile('.fcs','Select a .fcs file to gate');

if ischar(files)==1
    files = {files};
else
    files = files';
end

[fcsdat, fcshdr] = fca_readfcs([folder files{1}]);

close all

for nGate=1:size(gate,1)
    xdata = [];
    ydata = [];
    
    channels2gate = gate{nGate,1};
    gatename = strrep(channels2gate,'-','');
    gatename = strcat('Gate_',gatename{1},'_',gatename{2});
    cX = find(strcmp({fcshdr.par.name},channels2gate(1))==1);
    cY = find(strcmp({fcshdr.par.name},channels2gate(2))==1);
    
    channels2scale = gate{nGate,2};
    if strcmp(channels2scale(1),'log')
        xdata = fcsdat(:,cX);
        xdata(xdata<=0) = nan;
        xdata = log(xdata);
    else
        xdata = fcsdat(:,cX);
    end
    
    if strcmp(channels2scale(2),'log')
        ydata = fcsdat(:,cY);
        ydata(ydata<=0) = nan;
        ydata = log(ydata);
    else
        ydata = fcsdat(:,cY);
    end
    
    gatePts = gate{nGate,3};
    idx{nGate} = inpolygon(xdata, ydata, gatePts(:,1),gatePts(:,2));    
    if nGate>1
        idxp = idx{nGate-1};
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
    figure('Position',[100 100 800 800]);
    g.draw();
    xlim auto
    ylim auto
    
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1));
    
    hold on;    
    pgon = polyshape(gatePts(:,1),gatePts(:,2));
    plot(pgon,'EdgeColor',[255 94 105]./255,'FaceAlpha',0,'LineWidth',1.5);

end
