tic;
clearvars;

%% Set parameters

bins = 1024;
displayHist = 1;
removeEmptyBins = 1;
fsparse = 4;

% Designate channel to be fitted and plotted
channel = 'YL2-H';

% Designate pairs of channels for gating. Each row contains a channel pair,
% can add more indefinitely. Leave empty for no gating.
channelsGate = {'FSC-A', 'SSC-A'; 'FSC-A', 'FSC-H'};

%% Select file for gating (gate will apply to all samples selected later)

if ~isempty(channelsGate)
    [files, folder] = uigetfile('.fcs','Select a single .fcs file to gate');
    
    if ischar(files)==1
        files = {files};
    else
        files = files';
    end
    
    [fcsdat, fcshdr] = fca_readfcs([folder files{1}]);
    
    return
    
    
    for g = 1:size(channelsGate,1)
        clearvars gate cX cY
        if ischar(channelsGate{g,1})
            cX = find(strcmp({fcshdr.par.name},channelsGate(g,1))==1);
            cY = find(strcmp({fcshdr.par.name},channelsGate(g,2))==1);
        end
        
        [~,gate] = fcsGate(fcsdat,fcshdr,cX,cY,fsparse,1);
        ROI{g} = gate;
        idxGate = inpolygon(fcsdat(:,cX), fcsdat(:,cY), ROI{g}(:,1),ROI{g}(:,2));
        fcsdat = fcsdat(idxGate~=0,:);
    end
end

%% Select .fcs files

clearvars files folder
[files, folder] =  uigetfile('.fcs','Select .fcs files','MultiSelect','on');
outputFolder = [folder 'output\'];

if ~exist(outputFolder, 'dir')
    mkdir(outputFolder)
end

if ischar(files)==1
    files = {files};
else
    files = files';
end





return
%% Analyze .fcs files

for f = 1:length(files)
    % Reset variables
    clearvars fcsdat fcshdr nGated nUngated gate data counts centers edges dataOut0 fitdata gof output
    
    % Load FCS data
    [fcsdat, fcshdr] = fca_readfcs([folder files{f}]);
    nUngated = size(fcsdat,1);
    
    % Convert channel name to number (if applicable)
    if ischar(channel)
        channel = find(strcmp({fcshdr.par.name},channel)==1);
    end
    
    % Gate each .fcs file (if applicable)
    if ~isempty(channelsGate)
        for g = 1:size(channelsGate,1)
            clearvars gate cX cY
            % Convert channelsGate names to numbers (if applicable)
            if ischar(channelsGate{g,1})
                cX = find(strcmp({fcshdr.par.name},channelsGate(g,1))==1);
                cY = find(strcmp({fcshdr.par.name},channelsGate(g,2))==1);
            end
            idxGate = inpolygon(fcsdat(:,cX), fcsdat(:,cY), ROI{g}(:,1),ROI{g}(:,2));
            fcsdat = fcsdat(idxGate~=0,:);
        end
    end
    nGated = size(fcsdat,1);
    
    data = fcsdat(:,channel);
    data(data<0) = nan;
    
    % Bin data
    [counts, edges] = histcounts(log10(data),bins);
    %     centers = (edges(1:end-1) + edges(2:end))/2;
    centers = edges(1:end-1) + diff(edges)/2;
    
    % Remove bins with no counts.
    % Is this okay? Seems to make the goodness of fit numbers worse
    % Am I throwing away good data at some point?
    if removeEmptyBins==1
        d0 = [counts', centers'];
        d0 = d0(any(d0(:,1),2),:);
        counts = d0(:,1);
        centers = d0(:,2);
    else
        counts = counts';
        centers = centers';
    end
    
    % Normalize data for probability distribution
    counts = counts./sum(counts);
    
    % Fit data
    opts = fitoptions('Method', 'NonlinearLeastSquares');
    [fitData, gof, output] = fit(centers, counts, 'gauss2', opts);
    
    % Set export data
    dataOut0.sourceFile = [folder files{f}];
    dataOut0.sample = extractBetween(files{f},'Plate_','.fcs'); % Change to get desired sample name from filename
    dataOut0.nUngated = nUngated;
    dataOut0.nGated = nGated;
    dataOut0.fitEqn = formula(fitData);
    fitParams = coeffnames(fitData)';
    fitParamValues = coeffvalues(fitData);
    for i = 1:length(fitParams)
        dataOut0.(fitParams{i}) = fitParamValues(i);
    end
    dataOut0.sse = gof.sse;
    dataOut0.rsquare = gof.rsquare;
    dataOut0.adjrsquare = gof.adjrsquare;
    dataOut0.dfe = gof.dfe;
    dataOut0.rmse = gof.rmse;
    
    % Collect data into single struct
    if f==1
        dataOut = dataOut0;
    else
        dataOut = [dataOut, dataOut0];
    end
    
    % Display and save histograms
    if displayHist==1
        figure; hold on
        %Plot data
        scatter(centers, counts,'filled');hold on;
        plot(fitData)
        title(dataOut0.sample, 'Interpreter', 'none');
        xlabel('Intensity (AU)');
        ylabel('Probability');
        legend(['n ungated = ' num2str(nUngated) newline 'n gated = ' num2str(nGated)],['R^2 = ' num2str(dataOut0.rsquare)],'Location','northeast');
        legend('boxoff');
        saveas(gcf,[outputFolder date '_fitHist_' dataOut0.sample{:} '.tif']);
        close all
    end
end

%% Convert data to table and save

dataOut = struct2table(dataOut);
writetable(dataOut, [outputFolder date '_flowDataFit_' dataOut.sample{1} '-' dataOut.sample{end} '.xls']);

%%

fclose all;
toc
