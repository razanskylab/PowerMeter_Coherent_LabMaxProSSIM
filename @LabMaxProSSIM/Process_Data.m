% File: Process_Data.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

%^ Description: Processes response from power meter.

function [ppes, flagsHexs, freqs, cleanPpes] = Process_Data(pm, response)
  % ppes - per pulse energies in Joule
  % flags - infos on what was actually measured (see below)
  % freqs - 1./period wher period is expressed in decimal integer as microseconds
  % 
  % flags provides info on what happened with the shots
  % Bit Hex   Meaning
  % -----------------------------------------
  % 0   01    Trigger event
  % 1   02    Baseline CLIP
  % 2   04    Calculating (PTJ mode only)
  % 3   08    Final energy record (PTJ mode only)
  % 4   10    Over-range
  % 5   20    Under-range
  % 6   40    Measurement is sped up
  % 7   80    Over-temperature error
  % 8   100   Missed measurement
  % 9   200   Missed pulse
  % xxx 000   No qualification exists

  rawData = pm.Process_Msg(response);
  
  % [PPE, flags, freqs]_1 [PPE, flags, freqs]_2 ... 

  rawPpes = rawData(1:3:end);
  ppes = str2double(rawPpes);
  % ppes = [PPE_1, PPE_2, ...]
  
  rawFlags = rawData(2:3:end);
  % flags = [flag_1, flag_2, ...]
  flags = hexToBinaryVector(rawFlags, 16);
  % [x x x x x x x x x x x x x x x x]
  % [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1] --> bit 0 --> 16 - 0
  % [0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0] --> bit 1 --> 16 - 1
  % [0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0] --> bit 2 --> 16 - 2

  flagsHexs = str2double(rawFlags);
  
  rawFreqs = rawData(3:3:end);
  freqs = 1 ./ (str2double(rawFreqs) * 1e-6);

  % freqs = [freq_1, freq_2, ...]

  if any(flags)
    allShots = numel(flags);
    
    goodShots = sum((flags == 0)); % no flags, all good
    missedShots = sum((flags==200));

    warningMsg{1} = 'Error message was Trigger event';
    warningMsg{2} = 'Error message was Baseline CLIP';
    warningMsg{3} = 'Error message was Calculating (PTJ mode only)';
    warningMsg{4} = 'Error message was Final energy record (PTJ mode only)';
    warningMsg{5} = 'Error message was Over-range';
    warningMsg{6} = 'Error message was Under-range';
    warningMsg{7} = 'Error message was Measurement is sped up';
    warningMsg{8} = 'Error message was Over-temperature error';
    warningMsg{9} = 'Error message was Missed measurement';
    warningMsg{10} = 'Error message was Missed pulse';
    % warningMsg{11} = 'Error message was No qualification exists';

    errBit = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; 

    for (iErr = 1:10)
      % nProbShots = sum((flags == hexVal(iErr)));
      nProbShots = sum(single(flags(:, 16 - errBit(iErr))));
      percShots = nProbShots / allShots * 100;
      if (nProbShots > 0)
        warning(sprintf('%s for %2.f%% of shots (error %d)!',...
          warningMsg{iErr}, percShots, hexVal(iErr)));
      end
    end

    % we remove all read outs where flag was non-zero
    flagSum = sum(single(flags), 2);
    if any(flagSum)
      warning("Some error occured");
    end
    cleanPpes = ppes(flagSum == 0); 
    % cleanPpes = ppes(~flags); 

  else
    cleanPpes = ppes;
  end

end