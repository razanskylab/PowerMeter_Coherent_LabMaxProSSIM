% File: Initialize.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020
% 
% Restore power meter settings to defaults defined as properties
% Is automatically called after resetting scope

function Restore_Defaults(Obj)
  % Obj.flagHandshaking = 1; % no longer optional...we always handshake
  tic;
  fprintf('[LabMaxProSSIM] Restoring default flags...');
  Obj.flagSpeedup = true;
  Obj.flagRangeAuto = false;
  Obj.flagWavelengthcorrection = true;
  Obj.Done();
  
  tic;
  fprintf('[LabMaxProSSIM] Restoring default settings...');
  Obj.wavelength = Obj.DEFAULT_WAVELENGTH;
  Obj.measurementMode = Obj.DEFAULT_MEAS_MODE;
  Obj.triggerLevel = Obj.DEFAULT_TRIGGER_LEVEL;
  Obj.triggerMode = Obj.DEFAULT_TRIG_MODE;
  Obj.measurementRange = Obj.DEFAULT_MEAS_RANGE;
  Obj.Done();
end
