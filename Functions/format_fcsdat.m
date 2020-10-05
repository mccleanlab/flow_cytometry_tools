function dataOut = format_fcsdata(dataIn)
% DATAOUT = FORMATFCSDATA(DATAIN) converts measurements loaded from .fcs
% stored in DATAIN into big table of measurements DATAOUT

dataOut = {dataIn.fcsdat};
dataOut = vertcat(dataOut{:});
