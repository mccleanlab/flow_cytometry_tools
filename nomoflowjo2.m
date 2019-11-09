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
gateParams.fraction2keep = [0.5, 0.7];
gateParams.channels2gmm = [2, 2; 2, 1];
gate = autoGate(gateParams,'ClusterMethod','GMM');

%% Load data
data = loadfcs('Map','plate');
data = addGate(data,gate);
data = formatfcsdat(data);

%%
VOI = 'YL2H';
samplelist = string(unique(data.sample));
samplelist(samplelist=="")=[];
clear g; clf

for s = 1:numel(samplelist)
    sample = samplelist{s};    
    data2plot = data(data.Gate_net==1 & data.sample==sample,:);
    data2plot = data2plot(data2plot.(VOI)>0,:);
    data2plot.(VOI) = log10(data2plot.(VOI));
    
    g(s,1) = gramm('x',data2plot.(VOI),'color',cellstr(data2plot.light));
    g(s,1).stat_density();
    g(s,1).set_names('x','log10(YL2H)','row','Sample');
end

g.axe_property('XLim',[1 3.5]);
g.draw()
