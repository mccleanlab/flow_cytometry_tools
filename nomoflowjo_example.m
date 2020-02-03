close all; clearvars; clc
tic

%% Define and manually draw gates
channels2gate = {'FSC-A','SSC-A'; 'FSC-A', 'FSC-H' };
channelsscale = {'linear','linear'; 'linear','linear'};
fraction2keep = [0.5, 0.7];
gate = drawGate(channels2gate, channelsscale);

%% Alternatively, set gating params automatically 
gateParams.channels2gate = {'FSC-A','SSC-A'; 'FSC-A', 'FSC-H' };
gateParams.channelsscale = {'linear','linear'; 'linear','linear'};
gateParams.fraction2keep = [0.5, 0.7];
gateParams.channels2gmm = [2, 2; 2, 1];
gate = autoGate(gateParams,'ClusterMethod','GMM');

%% Load and process data
data_96WELL01 = loadfcs('Map','plate'); % Load 1st set of .fcs files (w/ plate map)
data_96WELL02 = loadfcs('Map','plate'); % Load 2nd set of .fcs files (w/ plate map)
data = [data_96WELL01, data_96WELL02]; % Combine data from both file sets
data = addGate(data,gate); % Add gate to data (this does NOT gate the samples, it simply adds the gating info for each event to be applied later with table logic or graphing rulse)
data = formatfcsdat(data); % Format data into table for plotting

%% Add labels to data for plotting
data2plot = data;
data2plot.zf = string(regexp(data2plot.mutant,'(?<=\w*\|\w*\|)\w*','match','once'));

%% Simple boxplot of mCitrine expression vs ZF variant per mutant
clear g;

% Defining data to plotted; note, specificy subset with Gate_net = 1 here to apply gating
g = gramm('x', cellstr(data2plot.mutant),'y',log10(data2plot.BL2H),'color',cellstr(data2plot.zf),...
    'subset', data2plot.BL2H>0 & data2plot.Gate_net==1 & data2plot.reporter=="pCTT1-mCitrine" & ...
    data2plot.linus=="-LINuS" & data2plot.time=="0" & (data2plot.zf=="A" | data2plot.zf=="WT")); 
g.stat_boxplot();
g.set_title('mCitrine expression vs ZF variant');
g.set_names('x','Mutant','y','log(mCitrine)','color','ZF');
figure('Position',[100 100 1200 600]);
g.draw();

%% Histogram mCitrine expression for each Msn2x-mScarlet�LINuS �light
mutantlist = unique(data2plot.mutant,'stable');
loc = reshape(1:15,5,3)';

clear g;
for n = 1:numel(mutantlist)
    mutant = mutantlist{n};
    data_hist= data2plot(data2plot.mutant==mutant,:);
    data_hist.light(data_hist.time== "0") = "-light";
    data_hist.light(data_hist.time== "2") = "+light";
    [i, j] = find(loc==n);
    
    g(i,j) = gramm('x',log(data_hist.BL2H),'color',cellstr(data_hist.light),'group',cellstr(data_hist.replicate),...
        'subset', data_hist.BL2H>0 & data_hist.Gate_net==1 & data_hist.reporter=="pCTT1-mCitrine");
    g(i,j).facet_grid(cellstr(data_hist.linus),[],'scale','free_y');
    g(i,j).stat_bin('geom','line','normalization','probability','nbins',100);
    g(i,j).set_title(mutant);
    
    if mutant~="None"
        g(i,j).no_legend();
    end
    
end

g.set_order_options('row',{'-LINuS','+LINuS'},'color',{'-light','+light'});
g.set_text_options('facet_scaling',0.75,'title_scaling',0.75);
g.set_names('x','log(mCitrine)','y','%','row','');
g.set_title('mCitrine expression')
g.axe_property('XLim',[4 12]);
figure('Position',[100 100 1200 1200]);
g.draw();

%% Single-cell mCitrine vs mScarlet expression per mutant (scatter plot)
samplelist = unique(data2plot.sample,'stable');
gidx = reshape(1:30,6,5)';

clear g
for s = 1:numel(samplelist)
    [i, j] = find(gidx==s);
    sample = samplelist{s};
    dataScatter = data2plot(data2plot.sample==sample,:);
    g(i,j) = gramm('x',log(dataScatter.YL2H),'y',log(dataScatter.BL2H),'color',cellstr(dataScatter.replicate),...
        'subset',dataScatter.Gate_net==1 & dataScatter.YL2H>0 & dataScatter.BL2H>0 & dataScatter.time=='0');
    g(i,j).set_title(sample,'FontSize',7);
    g(i,j).geom_point();
    
end

g.set_names('x','log(mScarlet)','y','log(mCigtrine)','color','Replicate');
g.set_text_options('base_size',6,'label_scaling',1.5,'title_scaling',2,'legend_scaling',1);
g.set_point_options('base_size',1);
g.set_title('mScarlet vs mCitrine expression per cell');
figure('Position',[100 100 1200 600]);
g.draw();

%%
toc