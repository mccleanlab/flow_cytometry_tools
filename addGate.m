function dataOut = addGate2(data, gate)
dataOut = data;

for f = 1:numel(data)  
    
    fcsdat = dataOut(f).fcsdat;
    fcshdr = dataOut(f).fcshdr;
    
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
            xdata = fcsdat{:,cX};
            xdata(xdata<=0) = nan;
            xdata = log(xdata);
        else
            xdata = fcsdat{:,cX};
        end
        
        if strcmp(channels2scale(2),'log')
            ydata = fcsdat{:,cY};
            ydata(ydata<=0) = nan;
            ydata = log(ydata);
        else
            ydata = fcsdat{:,cY};
        end
        
        gatePts = gate{nGate,3};
        idx = inpolygon(xdata, ydata, gatePts(:,1), gatePts(:,2));
        
        gatenamelist{nGate} = gatename;
        gateidxlist{nGate} = idx;
        dataOut(f).fcsdat.(gatename) = idx;
    end   

    idxnet = all([gateidxlist{:,:}],2);
    dataOut(f).fcsdat.Gate_net = idxnet;
end


