function [ppe, flag, freq] = Read_Buffer(Obj,ignoreEmptyRead)
  % ppe - per pulse energies
  % flag - true when PPE was read eronous...
  % freq - not sure tbh...
  if nargin < 2
    ignoreEmptyRead = false;
  end

  ppe = [];
  flag = [];
  freq = [];

  READ_AT_ONCE = 10*2^10; % how many bytes to read at once
  % 10 kB (10*2^10) seems to be optimal
  nBytesLeft = Obj.bytesAvailable;
  totalBytes = nBytesLeft;
  iRead = 1;
  allBytes = zeros(Obj.bytesAvailable, 1);
  tic;
  if nBytesLeft
    while nBytesLeft % read multiple times, not all at once
      if nBytesLeft > READ_AT_ONCE
        readBytes = READ_AT_ONCE;
      else
        readBytes = nBytesLeft;
      end
      newBytes = read(Obj.serialObj, readBytes, 'char');
      startIdx = (iRead - 1) * READ_AT_ONCE + 1;
      endIdx = startIdx + readBytes - 1;
      allBytes(startIdx:endIdx) = newBytes;
      iRead = iRead + 1;
      nBytesLeft = nBytesLeft - readBytes;
    end
    response = char(allBytes)';
    % check what data we got back...
    [ppe, flag, freq] = Obj.Process_Data(response);
        
    readString = num_to_SI_string(totalBytes, 3);
    infoStr = sprintf('[LabMaxProSSIM] Reading %i shots (%sB) took %1.2f seconds.\n',...
      length(ppe),readString,toc);
    fprintf(infoStr);
  elseif ignoreEmptyRead
    % we did not get bytes but we are OK with that
  else
    short_warn([Obj.classId ' No bytes available for reading!'])
  end

end
