% File: Acknoledge.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: unknown

% Description: Checks if last command received is ok.

function Acknowledge(pm)
  acknowledge = readline(pm.serialObj);
  % if we did not receive ok, throw error
  if ~strcmp(acknowledge, 'OK')
    txtMsg = ['Did not recieved OK, but: ', char(acknowledge)];
    error(txtMsg);
  end
end
