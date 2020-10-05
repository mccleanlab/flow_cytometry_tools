clearvars; clc; close all
%% Draw and save gate (comment out if loading previously saved gate)
gateParams.channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'}; % Specify pairs of channels for gating
gateParams.channelsscale = {'linear','linear'; 'log','log'}; % Specify scale for each pair of channels
gate = draw_gate(gateParams.channels2gate, gateParams.channelsscale);

%% Load previously saved gate (comment out if running for first time)
% gate = load('gate_20200818_KS_Msn2_CLASP_dark_experiment_dark_controls_yMM1608_pMM0832.mat');
% gate = gate.gateOut;

%% Designate folders from which to load .fcs files and plate maps (can easily comment out folders as shown below)
folder_list = {
    %     'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200818_KS_yMM1606_yMM1608_Msn2_CLASP_light\dark'...
    %     'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200818_KS_yMM1606_yMM1608_Msn2_CLASP_light\light'...
    'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200820_KS_yMM1603_yMM1605_Msn2_CLASP_light\dark'...
    'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200820_KS_yMM1603_yMM1605_Msn2_CLASP_light\light'...
    };

% Loop through folders and load labelled measurements from .fcs files
for f = 1:numel(folder_list)
    data_temp = load_fcs('map','plate','folder',folder_list{f});
    data_temp = add_gate(data_temp,gate);
    data_temp = format_fcsdat(data_temp);
    data{f} = data_temp;
end

% Combine all loaded data into big table
data = vertcat(data{:});

%% Process data as you like
% Get rid of nonsense measurements
data(data.BL2A<=0,:) = [];
data(data.YL2A<=0,:) = [];

% Calculate BL2A threshold (optional mCitrine gate)
data_BL2A_thresh = grpstats(data(data.plasmid=="pMM0832",:),{'replicate','reporter','condition'},@(x) prctile(x,95),'DataVars',{'BL2A','YL2A'});
data_BL2A_thresh = clean_grpstats(data_BL2A_thresh);
data_BL2A_thresh.Properties.VariableNames(end-1:end) = {'BL2A_thresh' 'YL2A_thresh'};
data = join(data,data_BL2A_thresh);

% Calculate fold change mCitrine
data_fc = grpstats(data(data.condition=='dark',:),{'replicate','plasmid','reporter'},'nanmedian','DataVars',{'BL2A','YL2A'});
data_fc = clean_grpstats(data_fc);
data_fc.Properties.VariableNames(end-1:end) = {'BL2A_fc','YL2A_fc'};
data = join(data,data_fc);
data.BL2A_fc = data.BL2A./data.BL2A_fc;
data.YL2A_fc = data.YL2A./data.YL2A_fc;

%% Plot data as you like
%%% NOTE: actually apply gates by using the logical gate variables as subsets
close all; clc

% Loop through reporters and plot mCitrine expression for Msn2 ± CLASP mutants
for n = 1:numel(reporter_list)
    reporter = string(reporter_list(n));
    
    % Get x limits
    x_lim = data.BL2A(data.gate_net==1 & data.reporter==reporter & (data.CLASP=="CLASP" | data.CLASP=="dCLASP"));
    x_lim = prctile(log(x_lim),[0.5,99.99]);
    x_lim = [floor(x_lim(1)),ceil(x_lim(2))];
    
    % Plot histogram of mCitrine expression
    clear g; close all
    figure('units','normalized','outerposition',[0 0 1 1])
    g = gramm('x',log(data.BL2A),'color',cellstr(data.condition),'linestyle',cellstr(data.CLASP),...
        'group',cellstr(data.replicate),'subset',data.gate_net==1 & data.reporter==reporter & (data.CLASP=="CLASP" | data.CLASP=="dCLASP"));
    g.facet_wrap(cellstr(data.Msn2),'ncols',4,'scale','independent');
    g.stat_bin('geom','line','normalization','probability','nbins',50);
    g.axe_property('XLim',x_lim);
    g.set_names('x','log(mCitrine)','y','pdf','row','','column','');
    g.set_title([reporter ' (absolute)']);
    g.set_layout_options('title_centering','plot','redraw',true);
    g.set_text_options('interpreter','tex');
    g.set_order_options('x',0);
    g.draw();
%     g.export('file_name',strcat(reporter,'_hist'),'file_type','png');
end

% Plot summary of mCitrine expression
clear g; close all; clc
figure('units','normalized','outerposition',[0 0 1 1]);
g = gramm('x',cellstr(data.Msn2),'y',(data.BL2A),'color',cellstr(data.condition),'marker',cellstr(data.CLASP),...
    'group',cellstr(data.replicate),'subset',data.gate_net==1 & (data.CLASP=='CLASP' | data.CLASP=='dCLASP'));
g.facet_wrap(cellstr(data.reporter),'ncols',3,'scale','independent');
g.stat_summary('type','quartile','geom','point','setylim',true);
g.set_names('x','','y','mCitrine','row','','column','');
g.set_point_options('markers',{'o','^'},'base_size',7)
g.axe_property('XTickLabelRotation',45,'TickLabelInterpreter','tex');
g.set_order_options('x',0);
g.set_title('reporter expression (absolute)');
g.draw();
% g.export('file_name','mCitrine','file_type','png');

%% Plot a 2D histogram
clear g; close all; clc
g = gramm('x',log(data.SSCH),'y',log(data.SSCA),'subset',data.gate_net==1 & data.Msn2=='Msn2' & data.CLASP=='CLASP');
g.facet_grid(cellstr(data.condition),cellstr(data.reporter),'scale','independent');
g.stat_bin2d('nbins',[255 255]);
g.set_names('x','SSCH','y','SSCA','row','','column','','color','');
g.no_legend();
g.draw();

