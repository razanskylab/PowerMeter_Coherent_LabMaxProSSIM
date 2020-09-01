% File: Process_Data.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

%^ Description: Processes response from power meter.

function [ppes, flags, freqs] = Process_Data(pm, response)
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
  
  rawPpes = rawData(1:3:end);
  ppes = str2double(rawPpes);
  
  rawFlagss = rawData(2:3:end);
  flags = str2double(rawFlagss);
  
  rawFreqs = rawData(3:3:end);
  freqs = 1 ./ (str2double(rawFreqs) * 1e-6);

  if any(flags)
    flags = unique(flags);
    flags(~isnumeric(flags)) = []; % there seems to be an empty line in flags as well
    flags(flags==0) = []; % we are fine with 0 
    short_warn('Recorded data points with flagss: ');
    short_warn(sprintf('   %i\n',unique(flags)));
    goodData = sum((flags==0));
    allData = numel(flags);
    short_warn(sprintf(' %2.f%% of data was trash!',(1-goodData./allData)*100));
    % we remove all read outs where flag was non-zero
    ppes = ppes(~flags); 
  end


end