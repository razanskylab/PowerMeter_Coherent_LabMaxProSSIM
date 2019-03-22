function Clear_Error(pm)
  % Clears all error records in the error queue
  fprintf(pm.serialObj,'SYSTem:ERRor:CLEar');

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
