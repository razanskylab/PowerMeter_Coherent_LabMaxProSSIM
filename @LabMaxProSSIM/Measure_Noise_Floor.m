function [noise,trigLim] = Measure_Noise_Floor(This, autoSetTrig)
	% output
	% noise - [J] vector with noise PPEs
	% trigLim - [J] trigger limit at which no shots should be recorded...
	
	t1 = tic;
	noiseWait = 1; % measure noise level for this long
	This.VPrintF_With_ID('Measuring noise floor for %2.1f s...',noiseWait)
	
	% store old verbose settings
	oldVerbose = This.verboseOutput;
	This.verboseOutput = false;

	if nargin < 2
		autoSetTrig = false;
	end

	% prepare fgiure for plotting
	oldTrigLevel = This.triggerLevel;
	try
		This.triggerLevel = 30e-9; % VERY low, to only measure noise
		This.Clear_Serial_Buffer(); % clear out any potential old data
		This.Start_Stream();

		pause(noiseWait); 
		This.Stop_Stream();
		noise = This.Read_Buffer;
		This.Clear_Serial_Buffer(); % clear out any potential old data
	catch ME
		% restore old trigger level
		This.triggerLevel = oldTrigLevel;
		rethrow(ME);
	end
	
	% restore old verbose settings
	This.verboseOutput = oldVerbose;
	This.Done(t1);

	% at this trigger limit, no noise should be measured
	trigLim = max(noise) + 4.*std(noise);
	if autoSetTrig
		This.triggerLevel = trigLim; % 
		This.VPrintF_With_ID('Setting new trigger level to %2.1f nJ\n',trigLim.*1e9)
	else
		This.triggerLevel = oldTrigLevel;
	end
end 
