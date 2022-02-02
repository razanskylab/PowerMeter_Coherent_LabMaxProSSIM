% File: Stop_Stream.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

% Description: Stops datastream of powermeter

function [] = Stop_Stream(Obj)
  tic;
  fprintf('[LabMaxProSSIM] Stoping power meter data stream... ');
  writeline(Obj.serialObj, 'STOP');
  % Obj.Acknowledge();
  Obj.Done();
end
