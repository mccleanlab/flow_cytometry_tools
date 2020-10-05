function [data, experiment_name] = load_fcs(varargin)

% This function loads .fcs files using fca_loadfcs.m by Laslo Balkay
% https://www.mathworks.com/matlabcentral/fileexchange/9608-fca_readfcs

% [DATA] = LOAD_FCS() loads fcs files via UI prompt and saves them to the
% struct DATA

% [DATA] = LOAD_FCS('folder',PATH) loads all .fcs files from the folder
% specified by PATH and saves them to the struct DATA

% [DATA] = LOAD_FCS('map','plate') loads fcs files via UI prompt and adds
% labels to each set of measurements based on the well specified in the
% .fcs filename and labels stored in a .xlsx plate map, which is also
% loaded by UI prompt. Any number of labels can be applied in this way so
% long as they follow the map_* 96 well format in the plate map . Unused
% wells can be left blank. The labeled fcs files are saved to DATA.

% [DATA] = LOAD_FCS('map','plate',folder',PATH) loads all .fcs files from
% the folder specified by PATH and adds labels to each set of measurements
% based on the well specified in the .fcs filename and labels stored in a
% .xlsx plate map, which is loaded automatically if it is in the same
% folder. Any number of labels can be applied in this way so long as they
% follow the map_* 96 well format in the plate map. Unused wells can be
% left blank. The labeled fcs files are saved to DATA.

% [DATA, EXPERIMENT_NAME] = LOAD_FCS(VARARGIN) works as described above but
% also outputs an experiment name based on the plate map. Useful if loading
% data from multiple experiments.

% Instantiate inputParser
p = inputParser;
addParameter(p, 'map', 'none', @(s) ismember(s, {'none','plate'}));
addParameter(p, 'folder', '', @isfolder);
parse(p, varargin{:});

% Parse inputs
parse(p, varargin{:});

% Select list of .fcs files to be loaded
if isfolder(p.Results.folder) % Select from specified folder
    fcs_files = dir(fullfile(p.Results.folder,'*.fcs'));
    fcs_files = struct2table(fcs_files);
else % Select via UI prompt
    [fcs_filenames, fcs_files_folder] = uigetfile('.fcs','Select .fcs files to analyze','multiselect','on');
    
    % Correct filename format if only loading one file
    if ~iscell(fcs_filenames)
        fcs_filenames = {fcs_filenames};
    end
    
    % Reorder filenames into vertical cell array if needed
    if size(fcs_filenames,2)>1
        fcs_filenames = fcs_filenames';
    end
    
    % Save list of .fcs files in table
    fcs_files = table();
    fcs_files.name = cellstr(fcs_filenames);
    fcs_files.folder(:,1) = string(fcs_files_folder);
end

% Load plate map if specified
if strcmp(p.Results.map, 'plate')
    
    if isfolder(p.Results.folder) % Load plate map from specified folder
        plate_map_file = dir(fullfile(p.Results.folder,'*.xlsx'));
        if isempty(plate_map_file) % Load plate map via UI prompt if no .xlsx file found in folder
            [plate_map_file.name, plate_map_file.folder] =  uigetfile('*.xlsx','Plate map not found, select manually','MultiSelect','on');
        end
    else % Load plate map via UI prompt
        [plate_map_file.name, plate_map_file.folder] =  uigetfile([fcs_files_folder '*.xlsx'],'Select plate map','MultiSelect','on');
    end
    
    % Get experiment name from plate map
    [~, experiment_name, ~] = fileparts(fullfile(plate_map_file.folder,plate_map_file.name));
    
    % Load labels from plate map
    opts = detectImportOptions(fullfile(plate_map_file.folder,plate_map_file.name));
    opts = setvartype(opts,'char');
    plate_map_raw = readtable(fullfile(plate_map_file.folder,plate_map_file.name),opts);
    
    % Creat list of well names in 96 well format
    row_names = {'A' 'B' 'C' 'D' 'E' 'F' 'G' 'H'};
    column_names = num2cell(1:12);
    column_names = cellfun(@(x) sprintf('%2d',x),column_names,'UniformOutput',false);
    column_names = string(column_names);
    [c, r] = ndgrid(1:numel(column_names),1:numel(row_names));
    
    well_list = [row_names(r(:)).' column_names(c(:)).'];
    well_list = join(well_list);
    well_list = strrep(well_list,' ','');
    well_list = reshape(well_list,12,8)';
    plate_map.well = well_list;
    
    % Extract labels from plate map
    label_list = regexp(plate_map_raw{:,:},'map_\w*','match');
    label_list = string(label_list(~cellfun('isempty',label_list)));
    for n = 1:numel(label_list)
        label = label_list{n};
        [i, j] = find(strcmp(label,plate_map_raw{:,:}));
        i = i+1:i+8;
        j = j+1:j+12;
        label = erase(label,'map_');
        plate_map.(label) = string(plate_map_raw{i,j});
    end
end

% Initialize error tracking variables
idx_error = 1;
f_error_list = [];

% Loop through list of .fcs files and load measurements
for f = 1:size(fcs_files,1)
    
    % Load measurements and metadata from .fcs files using Laslo Balkey's loader
    [fcsdat, fcshdr] = fca_readfcs(fullfile(fcs_files.folder{f},fcs_files.name{f}));
    
    try % Organize measurements into table with appropriate column names
        fcs_fields = {fcshdr.par.name};
        fcs_fields = strrep(fcs_fields,'-','');
        fcsdat = array2table(fcsdat,'VariableNames',fcs_fields);
        fcsdat.sourcefile(:,1) = categorical(string(fcs_files.name{f}));
        
        % Apply labels from plate map to loaded data (if applicable)
        if strcmp(p.Results.map, 'plate')
            well = regexp(fcs_files.name{f},'[A-H](1[0-2]|[1-9])','match');
            [i, j] = find(strcmp(plate_map.well,well));
            
            field_list = fieldnames(plate_map);
            for n = 1:numel(field_list)
                fname = field_list{n};
                fcsdat.(fname)(:,1) = categorical(string(plate_map.(fname){i,j}));
            end
        end
        
        data(f).fcsdat = fcsdat;
        data(f).fcshdr = fcshdr;
        
    catch % Log error if .fcs file empty
        disp(['Error loading ' fcs_files.name{f}])
        
        % Create placeholder
        data(f).fcsdat = table();
        data(f).fcshdr = struct();
        
        % Log error
        f_error_list(idx_error) = f;
        idx_error = idx_error + 1;
    end
end

% Loop through logged errors and backfill table for empty .fcs files
if ~isempty(f_error_list)
    % Get list of files without errors and select one good file
    f_good = 1:size(fcs_files,1);
    f_good = f_good(~ismember(f_good,f_error_list));
    f_good = f_good(1);
    
    % Go back though erronious files and add empty data with correct field names based on good file
    for f = 1:numel(f_error_list)
        f_error = f_error_list(f);
        
        % Get field names from good file
        [fcsdat, fcshdr] = fca_readfcs(fullfile(fcs_files.folder{f_good},fcs_files.name{f_good}));
        fcsdat = nan(1,size(fcsdat,2));
        
        fcs_fields = {fcshdr.par.name};
        fcs_fields = strrep(fcs_fields,'-','');
        fcsdat = array2table(fcsdat,'VariableNames',fcs_fields);
        fcsdat.sourcefile(:,1) = categorical(string(fcs_files.name{f_error}));
        
        % Apply labels from plate map to loaded data (if applicable)
        if strcmp(p.Results.map, 'plate')
            well = regexp(fcs_files.name{f_error},'[A-H](1[0-2]|[1-9])','match');
            [i, j] = find(strcmp(plate_map.well,well));
            
            field_list = fieldnames(plate_map);
            for n = 1:numel(field_list)
                fname = field_list{n};
                fcsdat.(fname)(:,1) = categorical(string(plate_map.(fname){i,j}));
            end
        end
        
        data(f_error).fcsdat = fcsdat;
        data(f_error).fcshdr = fcshdr;
    end
end

% Output non-empty data into big struct file
data = data(all(~cellfun(@isempty,struct2cell(data))));

