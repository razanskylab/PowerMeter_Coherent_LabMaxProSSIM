% File: Initialize.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

function Initialize(pm)
  pm.wavelength = pm.WAVELENGTH;
  pm.flagHandshaking = 1;
  pm.flagWavelengthcorrection = 1;
  % pm.measurementMode = pm.MEASUREMENT_MODE.JOULES;
  % pm.triggerMode = pm.TRIGGER_MODE.INTERNAL;
	% pm.itemSelect = [0 2];
end
