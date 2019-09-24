clearvars; clc; close all
%% Set channels for gating
channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'};
channels2scale = {'linear','linear'; 'linear','linear'};
fraction2keep = [0.5, 0.9];
channels2gmm = [2, 2; 2, 1];

%% Set channels for gating
% channels2gate = {'FSC-A','SSC-A'; 'BL2-H','FSC-A', };
% channels2scale = {'linear','linear'; 'log','linear'};
% fraction2keep = [0.9, 0.5];
% channels2gmm = [2, 2; 2, 0];
%% Load data
gate = densityGate(channels2gate,channels2scale,fraction2keep,channels2gmm);
data = loadfcs3();
data = addGate(data,gate);
data = formatfcsdat(data);

%%
clear g
% x = 
g = gramm('x',log(data.BL2H),'subset', data.BL2H>0 & ~isinf(data.BL2H));
% g.stat_bin('geom','line','normalization','probability','nbins',50);
g.stat_density()
g.draw()