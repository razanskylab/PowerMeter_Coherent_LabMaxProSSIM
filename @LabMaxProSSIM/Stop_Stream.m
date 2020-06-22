% File: Stop_+Stream.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

% Description: Stops datastream of powermeter

function [] = Stop_Stream(pm)
  pm.VPrintf('Stoping power meter data stream... ', 1);
  writeline(pm.serialObj, 'STOP');
  % readline(pm.serialObj); % we trash the first line because it should be just on
  if pm.flagHandshaking
  	pm.Acknowledge();
  end
  pm.VPrintf('done!\n', 0);
end
