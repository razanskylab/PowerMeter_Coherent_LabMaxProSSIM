function [] = Initialize(pm)
  pm.wavelength = pm.WAVELENGTH;
  pm.measurementMode = pm.MEASUREMENT_MODE.JOULES;
  pm.triggerMode = pm.TRIGGER_MODE.INTERNAL;
%       pm.itemSelect = [0 2];
end
