function data_out = clean_grpstats(data,remove_groupcount)
data_out = data;
data_out.Properties.RowNames = {};
if ~exist('remove_groupcount','var') || (exist('remove_groupcount','var') && remove_groupcount==true)
    data_out.GroupCount = [];
end
