function [answer] = Query(pm,queryCommand)
  % send a queryCommand to the pm and return the answer string
  fprintf(pm.serialObj,'%s\n',queryCommand);
  pause(0.1);
  answer = fscanf(pm.serialObj,'%s\n');
  pm.Acknowledge;
end
