function dataOut = addGate(data, gate)

% This function adds gating information to your flow cytometry data set. It
% does not apply these gates but simply appends columns for each gate with
% the values of 1 (indicating that an event falls within a gate) or 0
% (indicating an event is excluded by the gate). It also appends the column
% Gate_net where a value of 1 indicates and event that is within all gates
% or 0 indicates an event that is excluded by at least one gate.

%%%%%%%%%%%% testing
dataOut = data;

for f = 1:numel(data)
    
    fcsdat = dataOut(f).fcsdat;
    fcshdr = dataOut(f).fcshdr;
    
    for nGate=1:size(gate,1)
        xdata = [];
        ydata = [];
        idx = [];
        idx0=[];
        
        channels2gate = gate{nGate,1};
        gatename = strrep(channels2gate,'-','');
        gatename = strcat('Gate_',gatename{1},'_',gatename{2});
        cX = find(strcmp({fcshdr.par.name},channels2gate(1))==1);
        cY = find(strcmp({fcshdr.par.name},channels2gate(2))==1);
        
        channels2scale = gate{nGate,2};
        if strcmp(channels2scale(1),'log')
            xdata = fcsdat{:,cX};
            xdata(xdata<=0) = nan;
            xdata = log10(xdata);
        else
            xdata = fcsdat{:,cX};
        end
        
        if strcmp(channels2scale(2),'log')
            ydata = fcsdat{:,cY};
            ydata(ydata<=0) = nan;
            ydata = log10(ydata);
        else
            ydata = fcsdat{:,cY};
        end        
        
        for i = 1:numel(gate{nGate,3})            
            gatePts = gate{nGate,3}{1,i};           
            idx0(:,i) = i*double(inpolygon(xdata, ydata, gatePts(:,1), gatePts(:,2)));
        end
        
        idx = max(idx0,[],2);         
        
        gatenamelist{nGate} = gatename;
        gateidxlist{nGate} = idx;
        dataOut(f).fcsdat.(gatename) = idx;
    end
    
    idxnet = all([gateidxlist{:,:}],2);
    dataOut(f).fcsdat.Gate_net = idxnet;
end


