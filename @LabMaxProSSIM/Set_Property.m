% File: Set_Property.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 06.05.2020

% Description: Sets a property of the power meter
% only response required here is ok

function Set_Property(pm, setCommand, flagAcknowledge)
	flush(pm.serialObj);
	writeline(pm.serialObj, setCommand);
	% pm.Acknowledge();
	flush(pm.serialObj);
end