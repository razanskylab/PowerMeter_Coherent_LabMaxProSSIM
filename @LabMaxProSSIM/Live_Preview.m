% File: Live_Preview.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 04.05.2020

% Description: live preview of measured per pulse energy

function Live_Preview(lm, varargin)

	% prepare fgiure for plotting

	fPreview = figure('Name', 'Powermeter Live Preview');
	ax1 = subplot(2, 2, [1, 2]);
	sigPlot = plot(zeros(1, 1001), '-');
	hold on
	meanPlot = plot(ones(1, 1001), 'r-');
	title('Energy');
	xlabel('Shot ID');
	ylabel('Energy [J]');
	grid on
	axis tight

	ax2 = subplot(2, 2, 3);
	histPlot = plot(ones(1, 1001), ones(1, 1001));
	title('Histogram');
	grid on
	axis tight
	xlabel('Energy [J]');
	ylabel('Count');

	ax3 = subplot(2, 2, 4);
	title('Nothing here yet');

	while(1)
		lm.Start_Stream();
		% start triggering here!
		pause(1);
		lm.Stop_Stream();

		[signal, error, freq] = lm.Read_Buffer;
		set(sigPlot, 'ydata', signal);
		set(meanPlot, 'ydata', mean(signal(~error)) * ones(size(signal)));
		[counts, edges] = histcounts(signal(~error));
		centers = (edges(1:(end - 1)) + edges(2:end)) / 2;
		set(histPlot, 'xdata', centers);
		set(histPlot, 'ydata', counts);
	end
end 