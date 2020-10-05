clearvars; clc; close all
%% Draw and save gate (comment out if loading previously saved gate)
channels_to_gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'}; % Specify pairs of channels for gating
channels_scale = {'linear','linear'; 'log','log'}; % Specify scale for each pair of channels
gate = draw_gate(channels_to_gate, channels_scale); % Draw and save gate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The above code will allow you to draw a gate on an .fcs file selected by
% UI prompt, first on a plot of FSCA-A vs SCC-A (with linear scaling) then
% on a plot of FSC-A vs FSC-H (with log scaling). It will automatically
% save the gate as a .mat file to the current folder. I recommend that you
% run this block of code once to draw gates on whatever .fcs file you
% choose and after that just comment out this section and load the saved
% gate, as shown below.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Load previously saved gate (comment out if running for first time)
gate = load('gate_20200818_KS_Msn2_CLASP_dark_experiment_dark_controls_yMM1608_pMM0832.mat');
gate = gate.gate_out;

%% Load measurments and labels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here each folder contains all .fcs files for a given plate (keep
% other .fcs files, eg, those used for calibration, in another fodler).
% You can easily add folder paths as new lines or comment out folders as
% shown above. I apply labels to the measurements as they are imported by
% placing a .xlsx plate map in each of the above folders and using the
% function load_fcs('map','plate') below. Each plate map contains labels
% for each well of a 96 well plate(though you can leave empty wells blank).
% You can add an arbitray number of labels to the plate map so long as they
% include the map_* label flag and follow the 96 well format shown in the
% example plate map.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify folders from which to load .fcs files
folder_list = {
    %     'D:\GoogleDrive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200818_KS_yMM1606_yMM1608_Msn2_CLASP_light\dark'...
    %     'D:\GoogleDrive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200818_KS_yMM1606_yMM1608_Msn2_CLASP_light\light'...
    'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200820_KS_yMM1603_yMM1605_Msn2_CLASP_light\dark'...
    'D:\Google Drive\yMM1603_yMM1608_Msn2_CLASP_flow_cytometry\20200820_KS_yMM1603_yMM1605_Msn2_CLASP_light\light'...
    };

% Loop through folders and load labelled measurements from .fcs files
for f = 1:numel(folder_list)
    data_temp = load_fcs('map','plate','folder',folder_list{f}); % Load and label measurements
    data_temp = add_gate(data_temp,gate); % Apply gate to measurements
    data_temp = format_fcsdat(data_temp); % Convert measurements to table
    data{f} = data_temp; % Collect table
end

% Convert collected tables into single big table
data = vertcat(data{:});

%% Process data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Process the data as you like but here's a useful trick. Use grpstats() to
% do a calculation on some subset of your data. You can merge the resulting
% table back in to the primary data table so long as your keywords match
% up. Here I calculate basal expression for each strain (and replicate)
% then merge that number back into the main table and use it to calculate
% fold change. This avoids lots of complicated looping.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get rid of nonsense measurements
data(data.BL2A<=0,:) = [];
data(data.YL2A<=0,:) = [];

% Calculate fold change mCitrine
data_fc = grpstats(data(data.condition=='dark',:),{'replicate','plasmid','reporter'},'nanmedian','DataVars',{'BL2A','YL2A'});
data_fc = clean_grpstats(data_fc);
data_fc.Properties.VariableNames(end-1:end) = {'BL2A_fc','YL2A_fc'};
data = join(data,data_fc);
data.BL2A_fc = data.BL2A./data.BL2A_fc;
data.YL2A_fc = data.YL2A./data.YL2A_fc;

%% Plot measurements

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% You can plot the measurements however you like, but I believe that using
% GRAMM (which is required for gating anyway) to plot the tabular data
% generated in the above steps is what makes this flow cytometry pipeline
% useful.

% Note: it is at this stage that I make use of the gates applied to the
% measurements earlier. I just include the subset data.gate_net==1 when
% defining my GRAMM object. If needed, you could also use the gates to mask
% the data, for example, by using data(data.gate_net==1,:) to select only
% events that are within all gates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Loop through reporters and plot expression for each mutant strain
close all; clc
reporter_list = unique(data.reporter,'stable');
for n = 1%:numel(reporter_list)
    reporter = string(reporter_list(n));
    
    % Get x limits
    x_lim = data.BL2A(data.gate_net==1 & data.reporter==reporter & (data.CLASP=="CLASP" | data.CLASP=="dCLASP"));
    x_lim = prctile(log(x_lim),[0.5,99.99]);
    x_lim = [floor(x_lim(1)),ceil(x_lim(2))];
    
    % Plot histogram of mCitrine expression
    clear g; close all
    figure('units','normalized','outerposition',[0 0 1 1])
    g = gramm('x',log(data.BL2A),'color',cellstr(data.condition),'linestyle',cellstr(data.CLASP),'group',cellstr(data.replicate),...
        'subset',data.gate_net==1 & data.reporter==reporter & ismember(data.CLASP,{'CLASP','dCLASP'}));
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

% Plot a 2D histogram
clear g; close all; clc
figure('units','normalized','outerposition',[0 0 1 1]);
g = gramm('x',log(data.SSCH),'y',log(data.SSCA),'subset',data.gate_net==1 & data.Msn2=='Msn2' & data.CLASP=='CLASP');
g.facet_grid(cellstr(data.condition),cellstr(data.reporter),'scale','independent');
g.stat_bin2d('nbins',[255 255]);
g.set_names('x','SSCH','y','SSCA','row','','column','','color','');
g.no_legend();
g.draw();

