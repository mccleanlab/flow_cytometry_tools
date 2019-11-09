clearvars; clc; close all
%% Set channels for gating
channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'};
channels2scale = {'linear', 'linear'; 'linear', 'linear'};
gate = autoGate(gateParams,'ClusterMethod','kmeans');
%% Load data
data = loadfcs();
% data02 = loadfcs();
% data = [data01, data02];
gate = drawGate(channels2gate, channels2scale);
data = addGate(data,gate);
% data = formatfcsdat(data);
return
%% Add labels to data for plotting
data.label01 = strcat(data.sample,'_',data.replicate);
data.label02 = strcat(data.sample,'_',data.time);
data.nesnls = string(regexp(data.mutant,'(\w*\|\w*)','match','once'));
data.zf = string(regexp(data.mutant,'(?<=\w*\|\w*\|)\w*','match','once'));

% regexp(x,'(?<NES>\w*)\|(?<NLS>\w*)\|(?<ZF>\w*)','names','ignorecase')
%% Remove samples with very low cell counts
% cellcountfinal = varfun(@sum,dataPlot,'InputVariables','Gate_net','GroupingVariables','label');
% deletelist = cellcountfinal(cellcountfinal.sum_Gate_net<1000,:).label;
% idx = find(contains(dataPlot.label,deletelist));
% dataPlot(idx,:) = [];


