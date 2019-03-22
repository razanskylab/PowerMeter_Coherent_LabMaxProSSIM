pm = PowerMeter;

pm.wavelength = 532;
triggerInit('oa',1000);
triggerStart();
pm.Start_Stream();
pause(5);
pm.Stop_Stream;
[signal, error, freq] = pm.Read_Buffer;
subplot(3,1,1), plot(signal);
subplot(3,1,2), plot(error);
subplot(3,1,3), plot(freq);
i = i + 1;
triggerStop;
