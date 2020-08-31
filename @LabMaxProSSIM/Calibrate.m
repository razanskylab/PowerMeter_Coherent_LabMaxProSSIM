function Calibrate(~)
  % Sets the current measurement as the zero baseline measurement
  short_warn('This power meter does not support Calibrate()!');
  % writeline(pm.serialObj, 'CONFigure:ZERO');
  % pause(0.05);
  % pm.Acknowledge();
end
