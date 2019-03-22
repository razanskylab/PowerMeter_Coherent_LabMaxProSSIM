function [] = Acknowledge(pm)
  acknowledge = fscanf(pm.serialObj,'%s\n');
  if ~strcmp(acknowledge,'OK')
    short_warn('Did not recieved OK!');
    fprintf(['Acknowledge was: "' acknowledge '"\n']);
  end
end
