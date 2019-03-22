function [] = Stop_Stream(pm)
  fprintf('[PowerMeter] Stoping power meter data stream.\n');
  fprintf(pm.serialObj,'%s\n','STOP');
end
