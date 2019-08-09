LM = LabMaxProSSIM;
LM.wavelength = 532;


LM.Start_Stream();
% start triggering here!
pause(5);
LM.Stop_Stream;

[signal, error, freq] = LM.Read_Buffer;
subplot(3,1,1), plot(signal);
subplot(3,1,2), plot(error);
subplot(3,1,3), plot(freq);
