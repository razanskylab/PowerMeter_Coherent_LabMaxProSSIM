% File: VPrintf.m @LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@bniomed.ee.ethz.ch
% Date: 05.05.2020

% Description: verbose output enabled or disabled by flagVerbose

function VPrintf(lm, txtMsg, flagName)

	if lm.flagVerbose
		if flagName 
			txtMsg = ['[LabMaxProSSIM] ', txtMsg];
		end
		fprintf(txtMsg);
	end

end