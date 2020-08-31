% File: Reset.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

% This command resets all operational parameters to their power-on
% states. Reset does not affect calibration settings or user persistent
% settings.
% this affects settings like wavelength, trigger levels etc, 
% those have to be set again

function Reset(Obj)
  writeline(Obj.serialObj, '*RST');
  Obj.Acknowledge();
  pause(0.5);
  Obj.Restore_Defaults();

end
