% File: Start_Stream.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

% Description: Starts recording using powermeter

function Start_Stream(pm, nPoints)
  pm.VPrintf('Starting power meter data stream... ', 1);

  flush(pm.serialObj);
  
  switch nargin
  	case 1
    	command = 'STARt';
  	case 2
    	command = ['STARt ' num2str(round(nPoints))];
    otherwise
    	error('Invalid number of input arguments');
  end
  
  writeline(pm.serialObj, command);

  pm.VPrintf('done!\n', 0);
end
