

clear all; close all;
P = LabMaxProSSIM('COM18');

% check measurement modes out
measurementModes = [0, 1];
for iMeas = 1:length(measurementModes)
	P.measurementMode = measurementModes(iMeas);
	if (measurementModes(iMeas) ~= P.measurementMode)
		txtMsg = ['Something went wrong while setting the measurement mode to ', ...
		num2str(measurementModes(iMeas))];
		error(txtMsg);
	end
end

% check out wavelength selection
wavelengths = [500:50:900];
for iLambda = 1:length(wavelengths)
	fprintf("Setting wavelength to %f nm\n", wavelengths(iLambda));
	P.wavelength = wavelengths(iLambda);
	if (P.wavelength ~= wavelengths(iLambda))
		error("Something went wrong during wavelength definition");
	end
end

% check if we can retrieve minimum and maximum trigger level
minTrigLevel = P.minTriggerLevel;
maxTriglevel = P.maxTriggerLevel;

rangVec = [0, 1, 2];
rangVals = [9.5180e-06, 9.6270e-05, 9.6210e-04];
for iRange = 1:length(rangVec)
	P.measurementRange = rangVec(iRange);
	if (P.measurementRange ~= rangVals(iRange))
		error("Could not set correct measurement range");
	end
end

trigLvls = [1e-6:1e-6:10e-6];
for iLvl = 1:length(trigLvls)
	fprintf("Setting trigger level to %f microJ\n", trigLvls(iLvl) * 1e6);
	P.triggerLevel = trigLvls(iLvl);
	pause(0.1);
	if (P.triggerLevel ~= trigLvls(iLvl))
		error("Could not set trigger level");
	end
end


clear all;