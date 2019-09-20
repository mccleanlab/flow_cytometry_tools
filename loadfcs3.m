function [data] = loadfcs3(varargin)

% Instantiate inputParser
p = inputParser;
addParameter(p, 'Map', 'none', @(s) ismember(s, {'none','plate'}))
addParameter(p, 'Folder', '', @isfolder)

% Parse inputs
parse(p, varargin{:});

if strcmp(p.Results.Map, 'plate')
    % Load plate map
    if isfolder(p.Results.Folder)
        [filepath, folder] =  uigetfile([p.Results.Folder '*.xlsx'],'Select plate map','MultiSelect','on');
    else
        [filepath, folder] =  uigetfile('*.xlsx','Select plate map','MultiSelect','on');
    end
    
    opts = detectImportOptions([folder filepath]);
    samplemap = readtable([folder filepath],opts);
    
    % Create map of samples/condtions from platemap and labels
    R = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'};
    C = num2cell(1:12);
    C = cellfun(@(x) sprintf('%2d',x),C,'UniformOutput',false);
    C = string(C);
    [c, r] = ndgrid(1:numel(C),1:numel(R));
    
    welllist = [R(r(:)).' C(c(:)).'];
    welllist = join(welllist);
    welllist = strrep(welllist,' ','');
    welllist = reshape(welllist,12,8)';
    map.well = welllist;
    
    % Extract sample labels from platemap
    labellist = regexp(samplemap{:,:},'map_\w*','match');
    labellist = string(labellist(~cellfun('isempty',labellist)));
    for n = 1:numel(labellist)
        label = labellist{n};
        [i, j] = find(strcmp(label,samplemap{:,:}));
        i = i+1:i+8;
        j = j+1:j+12;
        label = erase(label,'map_');
        map.(label) = string(samplemap{i,j});
    end
end

% Select fcs files (prompt)
if strcmp(p.Results.Map, 'none') && ~isfolder(p.Results.Folder)
    [filepath, folder] = uigetfile('.fcs','Select .fcs files to analyze','multiselect','on');    
elseif strcmp(p.Results.Map, 'none') && isfolder(p.Results.Folder)
    p.Results.Folder
    [filepath, folder] = uigetfile([p.Results.Folder '\*.fcs'],'Select .fcs files to analyze','multiselect','on');
elseif strcmp(p.Results.Map, 'plate')
    [filepath, folder] = uigetfile([folder '*.fcs'],'Select .fcs files to analyze','multiselect','on');
end

if ischar(filepath)==1
    filepath = {filepath};
else
    filepath = filepath';
end

for f = 1:numel(filepath)
    fcslist{f} = [folder filepath{f}];
end

fcslist = fcslist';

% Load fcs data
for f = 1:numel(fcslist)
    file = fcslist{f};
    [~, path, ~] = fileparts(file);
    
    [fcsdat, fcshdr] = fca_readfcs(file);
    
    fcsfields = {fcshdr.par.name};
    fcsfields = strrep(fcsfields,'-','');
    fcsdat = array2table(fcsdat,'VariableNames',fcsfields);
    
    if strcmp(p.Results.Map, 'plate')
        well = regexp(path,'[A-H](1[0-2]|[1-9])','match');
        [i, j] = find(strcmp(map.well,well));
        
        fieldlist = fieldnames(map);
        for n = 1:numel(fieldlist)
            fname = fieldlist{n};
            fcsdat.(fname)(:,1) = string(map.(fname){i,j});
        end
    end
    
    data(f).fcsdat = fcsdat;
    data(f).fcshdr = fcshdr;
    
end