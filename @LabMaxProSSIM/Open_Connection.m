% File: Open_Connection.m @ LabMaxProSSIM
% Author: Johannes Rebling
% Mail: johannesrebling@gmail.com
% Date: unknown

% Changelog:
%     hofmannu - move to serialport instead of unstable serial class

function Open_Connection(Obj)
  tic;
  Obj.VPrintF_With_ID('Establishing serial connection... ');

  Obj.serialObj = serialport(Obj.COM_PORT, Obj.BAUD_RATE, ...
    'StopBits', Obj.STOP_BITS, ...
    'DataBits', Obj.DATA_BITS, ...
    'Timeout', Obj.TIME_OUT, ...
    'FlowControl', Obj.FLOW_CONTROL, ...
    'Parity', Obj.PARITY);

  configureTerminator(Obj.serialObj, Obj.READTERMINATOR, Obj.WRITETERMINATOR);

  % check if we connected the correct thing
  id = Obj.Query('*IDN?'); % request identification from powermeter

  isCorrectMeter = strcmp(id(1:27), Obj.METER_ID);
  if ~isCorrectMeter
    error('Does not look like a valid powermeter broh!');
  else
    Obj.connectionStatus = 'Connected';
    Obj.isConnected = 1;
  end

  Obj.Done();
  
end
