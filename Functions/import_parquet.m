function data_out = import_parquet(filenames,variable_names)
data_out = {};

if exist('variable_names','var')
    data_store = datastore(filenames,'SelectedVariableNames',variable_names);
else
    data_store = datastore(filenames);
end

data_store.ReadSize='file';
idx = 1;

while hasdata(data_store)
    data_temp = read(data_store);
    stringvar_idx = ismember(varfun(@class,data_temp,'OutputFormat','cell'),'string');
    stringvar_names = data_temp.Properties.VariableNames(stringvar_idx);
    data_temp = convertvars(data_temp,stringvar_names,'categorical');
    data_out{idx,1} = data_temp;
    idx = idx + 1;
end
data_out = vertcat(data_out{:});



