clearvars; clc; close all
%% Set channels for gating
channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'; 'BL2-H', 'FSC-H'};
channels2scale = {'linear', 'linear'; 'linear', 'linear'; 'log', 'linear'};

%% Load data
data = loadfcs3();
% gate = drawGate(channels2gate, channels2scale);
% data = addGate(data,gate);
data = formatfcsdat(data);
return
