function [ppe,flags] = Measure_Few_Shots(This, measTime)
	% output
	% ppe - [J] vector with PPEs
	% flags - info on good/bad shots

	if nargin < 2
		measTime = 2; % measure shots for this long
	end
	t1 = tic;
	This.VPrintF_With_ID('Measuring PPEs for %2.1f s...',measTime)
	
	% store old verbose settings
	oldVerbose = This.verboseOutput;
	This.verboseOutput = false;

	try
		This.Clear_Serial_Buffer(); % clear out any potential old data
		This.Start_Stream();
		pause(measTime); 
		This.Stop_Stream();
		[ppe,flags] = This.Read_Buffer(true);
		This.Clear_Serial_Buffer(); % clear out any potential old data
	catch ME
		rethrow(ME);
	end
	
	% restore old verbose settings
	This.verboseOutput = oldVerbose;
	This.Done(t1);

end 
