% File: Read_Buffer.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch

function [signal, flag, freq] = Read_Buffer(pm)
  READ_AT_ONCE = 10*2^10; % how many bytes to read at once
  % 10 kB (10*2^10) seems to be optimal
  % FIXME writing bytes in the order they are read, probably needs to be flipped
  % in order to get chronological order...
  nBytesLeft = pm.bytesAvailable;
  totalBytes = nBytesLeft;
  iRead = 1;
  allBytes = zeros(pm.bytesAvailable, 1);
  tic;
  if nBytesLeft
    while nBytesLeft % read multiple times, not all at once
      if nBytesLeft > READ_AT_ONCE
        readBytes = READ_AT_ONCE;
      else
        readBytes = nBytesLeft;
      end
      newBytes = read(pm.serialObj, readBytes, 'char');
      startIdx = (iRead - 1) * READ_AT_ONCE + 1;
      endIdx = startIdx + readBytes - 1;
      allBytes(startIdx:endIdx) = newBytes;
      % readString = num_to_SI_string(readBytes,3);
      % fprintf(['Reading ' readString 'B took %f seconds.\n'],toc);
      iRead = iRead + 1;
      nBytesLeft = nBytesLeft - readBytes;
    end
  else
    warning('No bytes available for reading!')
  end
  response = char(allBytes)';
  [signal, flag, freq] = pm.Process_Data(response);
  readString = num_to_SI_string(totalBytes, 3);

  fprintf('[PowerMeter] Reading %i shots (%sB) took %1.2f seconds.\n',...
    length(signal),readString,toc);
end
