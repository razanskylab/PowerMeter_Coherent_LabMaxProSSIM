% File: Query.m @ LabMaxProSSIM
% Author: Johannes Rebling
% Mail: johannesrebling@gmail.com
% Date: unknown

% Description: send a queryCommand to the pm and return the answer string
% flagAcknoledge: should we check for ok after naming?

function answer = Query(pm, queryCommand)
  % we need to run through this twice since it always first returns old info
  for i=1:2 
  	flush(pm.serialObj);
  	pause(0.05);
  	writeline(pm.serialObj, queryCommand);
  	pause(0.05);
  	answer = char(readline(pm.serialObj));
  	flush(pm.serialObj);
  end
end
