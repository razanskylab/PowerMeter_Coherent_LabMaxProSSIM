% File: Close_Connection.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 05.05.2020

% Description: closes the connection to the power meter.

function [] = Close_Connection(pm)
  % close serial connection to pm, delete serialObj
  % fclose(pm.serialObj);  % always, always want to close serial connection
  delete(pm.serialObj);
  pm.connectionStatus = 'Power Meter Connection Closed';
  pm.isConnected = 0;
  fprintf('[PowerMeter] Connection closed.\n');
end
