% File: Open_Connection.m @ LabMaxProSSIM
% Author: Johannes Rebling
% Mail: johannesrebling@gmail.com
% Date: unknown

% Changelog:
%     hofmannu - move to serialport instead of unstable serial class

function Open_Connection(pm)

  % open serial connection to pm on COM_PORT, creates serial obj
  % also displays pm status
  pm.VPrintf('Establishing serial connection... ', 1);

  pm.serialObj = serialport(pm.COM_PORT, pm.BAUD_RATE, ...
    'StopBits', pm.STOP_BITS, ...
    'DataBits', pm.DATA_BITS, ...
    'Timeout', pm.TIME_OUT, ...
    'FlowControl', pm.FLOW_CONTROL, ...
    'Parity', pm.PARITY);


  configureTerminator(pm.serialObj, pm.READTERMINATOR, pm.WRITETERMINATOR);
  % setup serial connection correctly
  % set(pm.serialObj, 'InputBufferSize', pm.INPUT_BUFFER_SIZE);

  % check if we connected the correct thing
  pause(0.1);
  id = pm.Query('*IDN?'); % request identification from powermeter

  isCorrectMeter = strcmp(id(1:27), pm.METER_ID);
  pm.connectionStatus = 'Connected';
  pm.isConnected = 1;
  
  if ~isCorrectMeter
    error('Does not look like a valid powermeter broh!');
  end

  pm.VPrintf('done!\n', 0);
  
end
