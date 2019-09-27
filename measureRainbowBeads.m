% function [gate ]  = measureRainbowBeads(varargin)
%
% % Instantiate inputParser
% p = inputParser;
% addRequired(p, 'gateParams', @isstruct);
% addRequired(p, 'channels2mefl', @iscell);
% parse(p, varargin{:});

% gateParams = p.Results.gateParams;
% channels2mefl =  p.Results.channels2mefl;

data = loadfcs();
inputfilename = [data.fcshdr.filepath data.fcshdr.filename];

gate = densityGate(gateParams,'File',inputfilename);
data = addGate(data, gate);
data = formatfcsdat(data);
%%
channels = regexprep(channels2mefl,'-','');
channel2gate= data(:, contains(data.Properties.VariableNames,{'Gate'}));
channel2gate = channel2gate(:,any(channel2gate{:,:}>1,1));
channel2gate_name = channel2gate.Properties.VariableNames{:};
data.au2mefls_idx = data.Gate_net.*data.(channel2gate_name);

grpstats(data,'au2mefls_idx',{'median'},'DataVars',channels);



