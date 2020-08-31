% File: Live_Preview.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 04.05.2020
% Description: live preview of measured per pulse energy
% notes heavily modified by Joe in 08/2020...

function Live_Preview(lm, varargin)

	% prepare fgiure for plotting
	try
		%% prepare plotting
		hfig = figure('Name', 'Powermeter Live Preview');
		% see call_back_functions folder for these UI callbacks
		setappdata(hfig,'firstPlot',1);

		StopBtnH = uicontrol('Style', 'PushButton', ...
									'String', 'Stop PM Stream', ...
									'Callback', 'delete(gcbf)',...
									'Position',[10 10 100 20]); %[left bottom width height]);
		% see below for 
		uicontrol('Style', 'PushButton', ...
									'String', 'Reset Plot', ...
									'Callback', {@pm_reset_plot,F},...
									'Position',[130 10 100 20]); %[left bottom width height]);

		drawnow;

		while ishandle(StopBtnH)
			lm.Start_Stream();
			% start triggering here!
			pause(1);
			lm.Stop_Stream();

			[ppe, error] = lm.Read_Buffer;
			% not sure this ever happens?
			if any(error)
				short_warn('Errors during measurement!');
			end
			ppe = ppe(~error); 


			if (getappdata(hfig,'firstPlot'))
				% clean up old plots (if they existet...)
				figure(hfig); 
				clf;

				subplot(2, 2, [1, 2]);
					sigPlot = plot(zeros(1, 1001), '-');
					hold on
					meanPlot = plot(ones(1, 1001), 'r-');
					title('Energy');
					xlabel('Shot ID');
					ylabel('Energy [J]');
					grid on
					axis tight

				subplot(2, 2, 3);
					histPlot = plot(ones(1, 1001), ones(1, 1001));
					title('Histogram');
					grid on
					axis tight
					xlabel('Energy [uJ]');
					ylabel('Count');

				subplot(2, 2, 4);
					title('Nothing here yet');
					setappdata(hfig,'firstPlot',0);
			else
				set(sigPlot, 'ydata', ppe);
				set(meanPlot, 'ydata', mean(ppe).*ones(size(ppe)));
				[counts, edges] = histcounts(ppe(~error));
				centers = (edges(1:(end - 1)) + edges(2:end)) / 2;
				set(histPlot, 'xdata', centers);
				set(histPlot, 'ydata', counts);
			end
		end
	catch ME 
		lm.Stop_Stream();
		LM.serialObj.flush(); % clean out 
	end

end 
