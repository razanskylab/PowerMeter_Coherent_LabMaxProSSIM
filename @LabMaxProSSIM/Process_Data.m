% File: Process_Data.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 12.05.2020

%^ Description: Processes response from power meter.

function [ppes, flags, freqs, cleanPpes] = Process_Data(pm, response)
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
  
  rawFlags = rawData(2:3:end);
  flags = str2double(rawFlags);
  
  rawFreqs = rawData(3:3:end);
  freqs = 1 ./ (str2double(rawFreqs) * 1e-6);

  if any(flags)
    allShots = numel(flags);
    goodShots = sum((flags==0));
    satShots = sum((flags==10));
    missedShots = sum((flags==200));
    otherProb = allShots - goodShots - satShots - missedShots;

    if satShots
      short_warn(sprintf(' %2.f%% of shots were saturated (error 10)!',...
        (satShots./allShots)*100));
    end
    if missedShots
      short_warn(sprintf(' %2.f%% of shots were missed (error 200)!',...
        (missedShots./allShots)*100));
    end
    if otherProb
      short_warn(sprintf(' %2.f%% of shots had other problems!',...
        (otherProb./allShots)*100));
    end
    % we remove all read outs where flag was non-zero
    cleanPpes = ppes(~flags); 
  else
    cleanPpes = ppes;
  end

end