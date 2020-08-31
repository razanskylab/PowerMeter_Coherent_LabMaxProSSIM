% File: Start_Stream.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

% Description: Starts recording using powermeter

function Start_Stream(Obj, nPoints)
  Obj.Clear_Serial_Buffer(); % just to be on the safe side... 

  % This command enables data streaming for a continuous or fixed
  % length transmission. An optional number of samples between 0 and
  % 2^32 -1 can be selected
  % The device will record data and send it over the serial port?

  tic;
  switch nargin
  case 1
    Obj.VPrintF_With_ID('Starting data stream...');
    command = 'STARt';
  case 2
    infoStr = sprintf('Starting %i-point data stream...',nPoints);
    Obj.VPrintF_With_ID(infoStr);
    command = sprintf('STARt %i',nPoints);
  otherwise
    error('Invalid number of input arguments');
  end
  
  writeline(Obj.serialObj, command);
  Obj.Acknowledge();
  Obj.Done();
end
