clearvars; clc; close all
%% Set channels for gating
channels2gate = {'BL1-H','YL1-H';'FSC-A','FSC-H';};
channels2scale = {'log','log'; 'linear','linear'; };
channels2thresh = [0.9, 0.9, 1];
channels2gmm = [2, 2; 1, 1; 0, 0];

%% Load data
gate = densityGate(channels2gate,channels2scale,channels2thresh,channels2gmm);
% data = loadfcs3();
% data = addGate(data,gate);
% data = formatfcsdat(data);

%%
% clear g
% figure
% g = gramm('x',log(data.BL1H),'subset',data.BL1H>=0 & data.BL1H<inf & data.Gate_net==1);
% g.stat_bin('geom','line','normalization','probability','nbins',100);
% g.draw()