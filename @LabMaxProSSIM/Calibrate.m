function Calibrate(pm)
  % Sets the current measurement as the zero baseline measurement
  fprintf(pm.serialObj,'CONFigure:ZERO');
  pause(0.05);
  newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
  msg = char(newBytes)';
  error = regexp(msg,'OK');
  if(isempty(error))
      disp('failed!');
  else
      disp(['done!']);
  end
end
