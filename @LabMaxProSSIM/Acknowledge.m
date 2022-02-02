% File: Acknoledge.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: unknown

% Description: Checks if last command received is ok.

function Acknowledge(Obj)
  acknowledge = readline(Obj.serialObj);
  % if we did not receive ok, throw error
  if isempty(acknowledge)
      error('[PM] Did not recieved acknowledge!');
  end
  switch acknowledge
    case 'OK'
      % do nothing, this is expected outcome
    case 'ERR-200'
      warning('Recieved ERR-200, missing .Start_Stream?')
    case 'ERR101'
      error("ERR101: The command or query parameter is invalid");
    otherwise
      txtMsg = ['Did not recieved OK, but: ', char(acknowledge)];
      fprintf(2, txtMsg); % output as error, but not crashing
      Obj.Clear_Serial_Buffer();
  end
end
