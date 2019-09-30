clearvars; clc; close all

%% Gating rainbow beads
% gateParams.channels2gate = {'FSC-A', 'SSC-A'; 'BL1-H', 'FSC-A'};
% gateParams.channelsscale = {'linear','linear'; 'log','log'};
% gateParams.fraction2keep = [0.75; 0.45];
% gateParams.channels2gmm = [0, 0; 5, 0];
% gate = densityGate(gateParams,'ClusterMethod','kmeans');

%% Gating yeast
gateParams.channels2gate = {'FSC-A','SSC-A'; 'FSC-A', 'FSC-H' };
gateParams.channelsscale = {'linear','linear'; 'linear','linear'};
gateParams.fraction2keep = [0.7, 0.9];
gateParams.channels2gmm = [2, 2; 2, 1];
gate = densityGate(gateParams,'ClusterMethod','GMM');

%% Load data
data01 = loadfcs('Map','plate');
data02 = loadfcs('Map','plate');
data = [data01; data02];
data = addGate(data,gate);
data = formatfcsdat(data);
return
%%
clf
nbins = 256;
xvar = 'FSCH';
yvar = 'BL2H';

clear g
g = gramm('x',log10(data.(xvar)), 'y', log10(data.(yvar)), 'subset', data.Gate_net==1 & ...
    data.(xvar)>0 & ~isinf(data.(xvar)) & data.(yvar)>0 & ~isinf(data.(yvar)));
g.stat_bin2d('nbins',[nbins nbins]);

g.set_names('x',['log10(' xvar ')'],'y',['log10(' yvar ')']);
g.stat_glm('geom','area','disp_fit',true);
g.draw()
