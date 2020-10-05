function h = plot_gate(gate,save_plot)

% This function plots previously defined gates on .fcs files loaded by UI prompt

% PLOT_GATE(GATE) plots the gates stored in GATE on top of .fcs files
% selected by UI prompt

% PLOT_GATE(GATE,true) plots the gates stored in GATE on top of .fcs files
% selected by UI prompt and saves an image of the plotted gates in a new
% folder ...\gate_plots


% Select .fcs files on which to plot gates
[files, folder] = uigetfile('.fcs','Select .fcs files on which to plot gate','multiselect','on');

% Correct filename format if only one file loaded
if ischar(files)==1
    files = {files};
else
    files = files';
end

% Loop through .fcs files and plot gate
for f = 1:numel(files)
    
    % Load the .fcs file
    file = files{f};
    [fcsdat, fcshdr] = fca_readfcs([folder file]);
    
    close all
    
    % Loop through channel pairs used for gating
    for n_gate=1:size(gate,1)
        
        % Reset data
        xdata = [];
        ydata = [];
        
        % Get channel info from gate variable
        channels_to_gate = gate{n_gate,1};
        gatename = strrep(channels_to_gate,'-','');
        gatename = strcat('Gate_',gatename{1},'_',gatename{2});
        cX = find(strcmp({fcshdr.par.name},channels_to_gate(1))==1);
        cY = find(strcmp({fcshdr.par.name},channels_to_gate(2))==1);
        
        % Load x-data and log scale if applicable
        channels_to_scale = gate{n_gate,2};
        if strcmp(channels_to_scale(1),'log')
            xdata = fcsdat(:,cX);
            xdata(xdata<=0) = nan;
            xdata = log10(xdata);
        else
            xdata = fcsdat(:,cX);
        end
        
        % Load y-data and log scale if applicable
        if strcmp(channels_to_scale(2),'log')
            ydata = fcsdat(:,cY);
            ydata(ydata<=0) = nan;
            ydata = log10(ydata);
        else
            ydata = fcsdat(:,cY);
        end
        
        % Get gate vertices from gate
        gate_vertices = gate{n_gate,3}{:};
        idx{n_gate} = inpolygon(xdata, ydata, gate_vertices(:,1),gate_vertices(:,2));
        if n_gate>1
            idxp = idx{n_gate-1};
            xdata = xdata(idxp);
            ydata = ydata(idxp);
        end
        
        % Set number of bins based on data and flag events on edge
        n0 = length(xdata);
        edge_idx = any([xdata==max(xdata), ydata==max(ydata)],2);
        nbins = round(n0/100);
        
        % Plot measurements to be gated
        clear g
        g = gramm('x',xdata(~edge_idx),'y',ydata(~edge_idx));
        g.stat_bin2d('nbins',[nbins nbins],'geom','image');
        g.set_names('x',[ gate{n_gate,1}{1} newline '(' gate{n_gate,2}{1} ')'],'y',[gate{n_gate,1}{2} newline '(' gate{n_gate,2}{2} ')']);
        g.no_legend();
        figure('Position',[100 100 800 800]);
        g.draw();
        
        % Set x and y limits
        xlim auto
        ylim auto
        
        % Delete unwanted GRAMM axis to enable drawing on top of plot
        ax = findall(gcf, 'type', 'axes');
        delete(ax(1));
        
        % Draw the gate over measurements
        hold on;
        pgon = polyshape(gate_vertices(:,1),gate_vertices(:,2));
        plot(pgon,'EdgeColor',[255 94 105]./255,'FaceAlpha',0,'LineWidth',1.5);
        title(file,'Interpreter','none','FontSize',8);
        
        % Save image of the gated measurments in new folder (if applicable)
        if exist('save_plot','var') == 1
            if save_plot==true
                file_out = erase(file,'.fcs');
                [~,~,~] = mkdir([pwd, '\gate_plots']);
                saveas(gcf,[pwd,'\gate_plots\',file_out,'_',gate{n_gate,1}{1},'_',gate{n_gate,1}{2}, '.jpg'])
            end
        end
    end
end