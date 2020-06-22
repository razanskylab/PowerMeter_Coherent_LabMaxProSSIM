LM = LabMaxProSSIM;
LM.wavelength = 532;
LM.sensitivityLevel = 1;

LM.Start_Stream();
% start triggering here!
pause(8);
LM.Stop_Stream();

[signal, error, freq] = LM.Read_Buffer;
subplot(3, 1, 1);
plot(signal);
title('Energy');
xlabel('Shot ID');
ylabel('Energy [J]');
grid on
axis tight

subplot(3, 1, 2);
plot(error);
title('Error');
xlabel('Shot ID');
grid on
axis tight

subplot(3, 1, 3);
plot(freq);
xlabel('Shot ID');
ylabel('Frequency [Hz]');
grid on
axis tight