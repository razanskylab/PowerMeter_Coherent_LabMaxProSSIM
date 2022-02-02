% File: Close_Connection.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 05.05.2020

% Description: closes the connection to the power meter.

function [] = Close_Connection(Obj)
  % close serial connection to pm, delete serialObj
  tic;
  Obj.connectionStatus = 'Power Meter Connection Closed';
  Obj.isConnected = 0;
  
  fprintf('[LabMaxProSSIM] Closing connection...');
  if ~isempty(Obj.serialObj)
    % Obj.serialObj.close(); % no longer exists for serialport
    delete(Obj.serialObj);
    Obj.serialObj = [];
    Obj.Done();
  else
    Obj.VPrintF('was not open!\n');
  end
end
