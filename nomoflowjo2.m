clearvars; clc; close all
%% Set channels for gating
% channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'};
% channels2scale = {'linear','linear'; 'linear','linear'};
% fraction2keep = [0.7, 0.9];
% channels2gmm = [0, 0; 0, 0];

%% Set channels for gating
% gateParams.channels2gate = {'FSC-A','SSC-A'; 'FSC-A', 'FSC-H'; 'BL2-H','FSC-A', };
% gateParams.channelsscale = {'linear','linear';  'linear','linear'; 'log','linear'};
% gateParams.fraction2keep = [0.5, 0.9, 0.9];
% gateParams.channels2gmm = [2, 2; 2, 1; 1, 0];

%% Set channels for gating rainbow beads
gateParams.channels2gate = {'FSC-A', 'SSC-A'; 'BL1-H', 'FSC-A'};
gateParams.channelsscale = {'linear','linear'; 'log','log'};
gateParams.fraction2keep = [0.7; 0.35];
gateParams.channels2gmm = [0, 0; 5, 0];
channels2mefl = {'BL2-H','YL2-H'};

%% Load data
gate = densityGate(gateParams,'ClusterMethod','kmeans');
% data = loadfcs();
% data = addGate(data,gate);
% data = formatfcsdat(data);

%%
clf
nbins = 256;
xvar = 'YL1H';
yvar = 'YL3H';

clear g
g = gramm('x',log(data.(xvar)), 'y', log(data.(yvar)), 'subset', data.Gate_net==1 & ...
    data.(xvar)>0 & ~isinf(data.(xvar)) & data.(yvar)>0 & ~isinf(data.(yvar)));

g.stat_bin2d('nbins',[nbins nbins]);
g.set_names('x',['log(' xvar ')'],'y',['log(' yvar ')']);
g.stat_glm('geom','area','disp_fit',true);
g.draw()
