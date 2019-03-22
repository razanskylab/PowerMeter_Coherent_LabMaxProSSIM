function [] = Start_Stream(pm,nPoints)
  fprintf('[PowerMeter] Starting power meter data stream.\n')
  switch nargin
  case 1
    command = 'STARt';
  case 2
    command = ['STARt ' num2str(round(nPoints))];
  end
  fprintf(pm.serialObj,'%s\n',command);
end
