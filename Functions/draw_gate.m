function gate_out = draw_gate(channels_to_gate, channels_to_scale)

% [GATEOUT] = DRAW_GATE(CHANNELS_TO_GATE,CHANNELS_TO_SCALE) allows one to
% draw gates on the channel pairs stored in CHANNELS_TO_GATE using the
% scales (linear/log) set in CHANNELS_TO_SCALE. Any arbitrary number of
% channel pairs can be used for gating. The .fcs file used to define the
% gates is selected by UI prompt. The gates stored in the cell array
% GATE_OUT, which is also exported as a .mat file for easy reuse. This
% function does not apply the gate to your measurements. That must be done
% later using the function add_gate.m

% EXAMPLE: 
% channels_to_gate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'}
% channels_to_scale = {'linear','linear';'log','linear'};
% gate_out = draw_gate(channels_to_gate,channels_to_scale) 

% The above code will allow you to draw a gate first on a plot of FSCA-A vs
% SCC-A (with linear scaling) then on a plot of FSC-A vs FSC-H (where
% FSC-A, arbitrarily, is log scaled and FSC-H is linear scaled).

% Note: when drawing gates press ENTER to close a polygon. Once the polygon is
% closed you may edit the gate further by moving vertices or
% adding/deleting vertices via the right-click menu. Once you are happy
% with your gate, press enter to show the points within the gate and ENTER
% again to save the gate. Continue this process until all channel pairs are
% gated. 

% Select .fcs file on which to draw gate
[files, folder] = uigetfile('.fcs','Select a .fcs file to gate');

% Correct filename format if only one file loaded
if ischar(files)==1
    files = {files};
else
    files = files';
end

% Load data from .fcs file
[fcsdat, fcshdr] = fca_readfcs([folder files{1}]);

for n_gate = 1:size(channels_to_gate,1)
    
    % Get index of channels used to gate x and y axes from channel names
    cX = find(strcmp({fcshdr.par.name},channels_to_gate(n_gate,1))==1);
    cY = find(strcmp({fcshdr.par.name},channels_to_gate(n_gate,2))==1);
    
    % Get x measurments and scale if needed
    if strcmp(channels_to_scale(n_gate,1),'log')
        xdata = fcsdat(:,cX);
        xdata(xdata<=0) = nan;
        xdata = log10(xdata);
    else
        xdata = fcsdat(:,cX);
    end
    
    % Get y measurements and scale if needed
    if strcmp(channels_to_scale(n_gate,2),'log')
        ydata = fcsdat(:,cY);
        ydata(ydata<=0) = nan;
        ydata = log10(ydata);
    else
        ydata = fcsdat(:,cY);
    end
    
    % Exclude events removed by previous gate
    if n_gate>1
        idxp = gate{n_gate-1,4};
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
    g.no_legend();
    figure('Position',[100 100 800 800])
    g.set_names('x',channels_to_gate{1},'y',channels_to_gate{1});
    g.draw();
    
    % Set x and y limits
    xlim auto
    ylim auto
    
    % Delete unwanted GRAMM axis to enable drawing on top of plot
    ax = findall(gcf, 'type', 'axes');
    delete(ax(1))
    
    % Show events beyond plot edge
    hold on;
    scatter(xdata(edge_idx),ydata(edge_idx),'r.')
    xlabel([fcshdr.par(cX).name newline '(' num2str(100*sum(edge_idx)/numel(xdata)) '% of events beyond plot edges)']);
    ylabel(fcshdr.par(cY).name);
    
    % Draw gate over measurements
    gate_vertices = drawpolygon('Color',[255 94 105]./255);
    pause
    gate_vertices = gate_vertices.Position;
    gate_vertices = [gate_vertices; gate_vertices(1,:)];
    
    % Get index of events within gate
    idx = inpolygon(xdata, ydata, gate_vertices(:,1),gate_vertices(:,2));
    
    % Show events within gate on plot
    nf = length(xdata(idx));
    scatter(xdata(idx),ydata(idx),10,'filled','MarkerFaceColor',[255 94 105]./255) ;
    xlabel([fcshdr.par(cX).name newline '(' num2str(n0) ' events before gate, ' num2str(nf) ' events after gate)'])
    pause
    
    % Save gate
    gate{n_gate,1} = channels_to_gate(n_gate,:);
    gate{n_gate,2} = channels_to_scale(n_gate,:);
    gate{n_gate,3} = {gate_vertices};
    gate{n_gate,4} = idx;
    gate{n_gate,5} = {files(1)};
    
    close all
end

% Get all gates and discard per gate indices (unneeded)
gate_out = gate;
gate_out(:,4) = [];

% Save gate
[~, filename_out, ~] = fileparts(files{1});
save(['gate_' filename_out '.mat'],'gate_out')