clearvars; clc; close all

%% Gating rainbow beads
gateParams.channels2gate = {'FSC-A', 'SSC-A'; 'BL1-H', 'FSC-A'};
gateParams.channelsscale = {'linear','linear'; 'log','log'};
gateParams.fraction2keep = [0.75; 0.45];
gateParams.channels2gmm = [0, 0; 5, 0];
gate = autoGate(gateParams,'ClusterMethod','kmeans');

%% Load data
data = loadfcs();
data = addGate(data,gate);
data = formatfcsdat(data);

%% Plot
% data2plot = data;
% n = 256;
% xvar = 'BL1H';
% yvar = 'BL3H';
%     
% g= gramm('x',log10(data2plot.(xvar)),'y',log10(data2plot.(yvar)),'subset',...
%     data2plot.Gate_net==1 & data2plot.(xvar)>0 & data2plot.(yvar)>0);
% g.stat_bin2d('nbins',[n n]);
% g.stat_glm('disp_fit',true);
% g.set_names('x',xvar,'y',yvar);
% 
% g.draw()
%%
channel = 'YL3';
data2mef = grpstats(data,'Gate_BL1H_FSCA',{'median'},'DataVars',{'BL1H','YL1H','YL3H','RL1H'});
data2mef(data2mef.Gate_BL1H_FSCA==0,:) = [];
data2mef = sortrows(data2mef,{'median_BL1H'},'ascend');
x = data2mef.(['median_' channel 'H']);

BD556286 = 'C:\Users\McCleanLab\Documents\MATLAB\nomoflowjo\BD556286_meflspeaks.xlsx';
BD556286 = readtable(BD556286);
y = BD556286.(channel);

close all; clear g
g= gramm('x',log10(x),'y',log10(y));
g.stat_glm('disp_fit',true);
g.geom_point();
g.draw()

