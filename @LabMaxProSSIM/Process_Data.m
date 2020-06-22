% File: Process_Data.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

%^ Description: Processes response from power meter.

function [signal, flag, freq] = Process_Data(pm, response)

  rawData = pm.Process_Msg(response);
  
  rawSignal = rawData(1:3:end);
  signal = str2double(rawSignal); % * 1e-3;
  
  rawFlag = rawData(2:3:end);
  flag = str2double(rawFlag);
  
  rawFreq = rawData(3:3:end);
  freq = 1 ./ (str2double(rawFreq) * 1e-6);


end