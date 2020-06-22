% File: Reset.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

% Description: Resets the power meter to its original settings.

function Reset(pm)
  % Clears all error records in the error queue
  writeline(pm.serialObj, '*RST');
  pm.Acknowledge();

end
