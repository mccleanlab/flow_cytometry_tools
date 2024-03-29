clearvars; clc; close all

%% Draw gate (comment out if loading previously saved data)
% gateParams.channels2gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'};
% gateParams.channelsscale = {'linear','linear'; 'log','log'};
% gate = draw_gate(gateParams.channels2gate, gateParams.channelsscale); %
% Use '20211129_0_Experiment_calibration_yMM1603_pMM0858_control.fcs' 

%% Load previously saved gate (comment
gate = load('gate_20211129_0_Experiment_calibration_yMM1603_pMM0858_control.mat');
gate = gate.gate_out;

%% Import measurements from .fcs files, label, and save to parquet files (comment out if loading previously saved data)
folder_list = {
    fullfile(pwd,'plate_1')...
    fullfile(pwd,'plate_2')...
    };

idx = 1;
for f = 1:numel(folder_list)
    [data_temp, experiment_name] = load_fcs('map','plate','folder',folder_list{f},'event_limit',25000,'plate_type','384_well');
    data_temp = add_gate(data_temp,gate); % Apply gates
    data_temp = format_fcsdat(data_temp); % Re-format data into table
    data{idx,1} = data_temp;
    idx = idx + 1;
end

data = vertcat(data{:});


%% Calculate population level statistics per sample

% Use only gated events with positive fluorescence for calculation
subset = data.gate_net==1 & data.BL2A>0 & data.YL2A>0;

grp_vars = {'experiment','plate_map','well','strain','reporter','plasmid','Msn2','CLASP','condition','replicate'};

% Calculate MFI (median fluoresence intensity) and cell count per sample
data_stats = grpstats(data(subset,:),grp_vars,...
    {'nanmedian','nanmean','nanstd'},'DataVars',{'BL2A','YL2A'});
data_stats = clean_grpstats(data_stats,false);
data_stats.Properties.VariableNames('GroupCount') = {'cell_count'};
data_stats.Properties.VariableNames = regexprep(data_stats.Properties.VariableNames,'nanmedian_','');


%% Plot single-cell mCitrine expression for hyperosmotic shock conditins
conditions_to_plot  = {'control','0.0625 M NaCl','0.125 M NaCl','0.25 M NaCl','0.5 M NaCl'};

clear g; clc
figure('units','normalized','outerposition',[0 0.25 0.3 0.5]);
g = gramm('x',log(data.BL2A),'color',data.condition,...
    'subset',data.gate_net==1 & data.BL2A>0 & ismember(data.condition,conditions_to_plot));
g.facet_grid(data.Msn2,[]);
g.stat_bin('normalization','pdf','geom','line');
g.set_names('x','log(mCitrine)','y','density','row','','column','','color','condition');
% g.set_order_options('column',condition_order)
g.set_text_options('interpreter','tex');
g.draw();

%% Plot summary of mCitrine expression for all conditions
condition_order  = {
    'control','0.5% glucose','0.1% glucose','0.01% glucose',...
    '0.0625 M NaCl','0.125 M NaCl','0.25 M NaCl','0.5 M NaCl'...
    };

clear g; clc
figure('units','normalized','outerposition',[0.35 0.25 0.5 0.5]);
g = gramm('x',(data_stats.condition),'y',log(data_stats.BL2A),'color',cellstr(data_stats.Msn2),...
    'subset',[]);
g.facet_wrap(cellstr(data_stats.reporter),'ncols',6,'scale','independent');
g.stat_summary('type','std','geom',{'bar','black_errorbar'},'setylim',true);
g.set_names('x','','y','log(mCitrine)','row','','column','','color','');
g.axe_property('XTickLabelRotation',45,'YLim',[5 7.5]);
g.set_order_options('x',condition_order)
g.set_text_options('interpreter','tex');
g.draw();

%% Plot measurements vs plate location
% Get x coordinates of well
data_stats.well_x = regexp(string(data_stats.well),'\d*','match');
data_stats.well_x = double(string(data_stats.well_x));

% Get y coordinates of well
data_stats.well_y = regexp(string(data_stats.well),'[A-P]','match');
data_stats.well_y = char(string(data_stats.well_y ));
data_stats.well_y = double(data_stats.well_y) - 64;

close all
clear g; figure('position',[50 50 900 900]);
g = gramm('x',data_stats.well_x,'y',data_stats.well_y,'color',data_stats.cell_count);
g.facet_grid(data_stats.plate_map,[]);
g.geom_point();
g.set_point_options('base_size',16);
g.set_names('color','','column','','row','');
g.axe_property('XLim',[0,25],'XTick',1:24,'YLim',[0,17],'YTick',1:16,'YTickLabel',['A':'P']','YDir','reverse'); % If 384 well
% g.axe_property('XLim',[0,13],'XTick',1:12,'YLim',[0,9],'YTick',1:8,'YTickLabel',['A':'H']','YDir','reverse'); % If 96 well
g.draw();



