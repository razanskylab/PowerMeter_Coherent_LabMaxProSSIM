function [signal, flag, freq] = Stream(pm,nPoints)
  switch nargin
  case 1
    pm.Start_Stream();
  case 2
    pm.Start_Stream(nPoints);
  end
  preAvailable = pm.bytesAvailable;
  pause(0.2);
  % wait for data stream to stop
  while true
    nowAvailable = pm.bytesAvailable;
    if nowAvailable > preAvailable
      availabeString = num_to_SI_string(nowAvailable,3);
      fprintf([availabeString 'B available.\n']);
      preAvailable = nowAvailable;
      pause(0.5);
    else
      break
    end
  end
  pm.Stop_Stream();
  [signal, flag, freq] = pm.Read_Buffer;
  % charBuffer = char(byteBuffer)'; % convert double to chars
  % response = sscanf(charBuffer,['%f,%i,%i\n']); % convert into numbers
  %response = numberBuffer; % convert into numbers
  % response(1,:) = numberBuffer(1:3:end);
  % response(2,:) = numberBuffer(2:3:end);
  % response(3,:) = numberBuffer(3:3:end);
end
