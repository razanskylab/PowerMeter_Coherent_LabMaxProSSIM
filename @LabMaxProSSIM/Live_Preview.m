% File: Live_Preview.m @ LabMaxProSSIM
% Author: Urs Hofmann
% Mail: hofmannu@biomed.ee.ethz.ch
% Date: 04.05.2020
% Description: live preview of measured per pulse energy
% notes heavily modified by Joe in 08/2020...

function [ppeBuffer,fullBuffer] = Live_Preview(Obj, varargin)
	oldVerbose = Obj.verboseOutput;
	Obj.verboseOutput = false;
	
	nStats = 500; % calculate current energy as mean over this many last samples
	nShots = 50000; 
	nHisto = min(1000,nShots); % use whatever is smaller....
	updateRate = 20; % (Hz) - how ofter to read from PM buffer
	nHistBins = 30;
	movMeanWindow = 100; % 100 shots for moving mean
	ppeBuffer = NaN(1,nShots);
	satShotBuffer = NaN(1,nShots);
	shotIds = 1:nShots;

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

		% ResetBtn = uicontrol('Style', 'PushButton', ...
		% 							'String', 'Reset', ...
		% 							'Callback', 'ppeBuffer = NaN(1,nShots);',...
		% 							'Position',[120 10 100 20]); %[left bottom width height]);
		drawnow;
		lastPlot = tic();

		Obj.Clear_Serial_Buffer(); % clear out any potential old data
		maxPPE = Obj.measurementRange.*1e6;
		Obj.Start_Stream();

		while ishandle(StopBtnH)
			drawnow limitrate;
			
			while(toc(lastPlot) < 1./updateRate)
				% do nothing but wait...
			end
			% read back as much data as you can
			[ppeTemp,flags] = Obj.Read_Buffer;
			satShots = (flags==10);
			% convert to uJ and take care of saturated shots
			ppeTemp = ppeTemp*1e6; % convert to uJ	
			ppeTemp(satShots) = NaN; % convert to NaN so that stats/histo are not affected
			ppeSatShots = ppeTemp; 
			ppeSatShots(satShots) = maxPPE; % convert to max range values
			ppeSatShots(~satShots) = NaN; % don't plot good values

			% check for some comon issues
			if isempty(ppeTemp)
				short_warn('Did not record any shots during last read-out!');
				pause(0.25); % let's wait a little to not flood the workspace 
				continue; % skip adding / plotting this round
			elseif max(ppeTemp) > maxPPE || min(ppeTemp) < 0
				Obj.Clear_Serial_Buffer();
				short_warn('Skipped last read-out due to out of range shots!');
				continue; % skip adding / plotting this round
			% elseif isempty
			% 	Obj.Clear_Serial_Buffer();
			% 	short_warn('Skipped last read-out due to flagged PPEs!');
			% 	pause(0.25); % let's wait a little to not flood the workspace 
			% 	continue; % skip adding / plotting this round
			end

			% add new data to end of ppeBuffer
			ppeBuffer = [ppeBuffer ppeTemp];
			satShotBuffer = [satShotBuffer ppeSatShots];
			% only create fullBuffer if requested 
			if nargout > 1
				fullBuffer = [fullBuffer ppeTemp]; 
			end
			% remove extra shots if we have filled the buffer
			ppeBuffer = ppeBuffer((end-nShots+1):end);
			satShotBuffer = satShotBuffer((end-nShots+1):end);
			ppeMovMean = movmean(ppeBuffer,movMeanWindow,'omitnan');
			histoShots = ppeBuffer((end-nHisto+1):end);
			meanShots = ppeBuffer(end-nStats+1:end);
			currentMean = mean(meanShots,'omitnan');
			meanStr = sprintf('%2.2fuJ',currentMean);
			% clean up old plots (if they existet...)
			if ishandle(StopBtnH) && (getappdata(hfig,'firstPlot'))
				figure(hfig); 

				subplot(2, 4, [1, 3]);
					ppePlot = plot(shotIds,ppeBuffer, '.','Color',Colors.DarkGreen);
					hold on
					satPlot = plot(shotIds,satShotBuffer, '.','Color',Colors.Red);
					movMeanPlot = plot(shotIds,ppeMovMean, '-','Color',Colors.DarkOrange);
					title('Per-Pulse Energy');
					xlabel('Shot ID');
					ylabel('Energy (uJ)');
					grid on
					axis tight

					
				subplot(2, 4, 4);
					title('PPE Boxplot');
					ylabel('Energy (uJ)');
					xlabel(sprintf('Last %i shots',nStats));
					bH = boxchart(meanShots,'Notch','on');
					hold on;
					tH = text(1.25,currentMean,meanStr,'Color',Colors.DarkOrange); 
					tH.FontSize = 16;
					tH.FontWeight = 'bold';
					hold off;

				subplot(2, 4, [5 6]);
					[h,s,p] = pretty_hist(histoShots,...
						Colors.DarkGreen,...
						nHistBins,...
						'probability',...
						true);
						
					title('Histogram');
					grid on; axis tight;
					xlabel('Energy (uJ)');
					ylabel('Probability (%)');


				setappdata(hfig,'firstPlot',0);
			% just update existing figure
			elseif ishandle(StopBtnH)
				set(ppePlot, 'ydata', ppeBuffer);
				set(satPlot, 'ydata', satShotBuffer);
				set(movMeanPlot, 'ydata', ppeMovMean);
				pretty_hist_update(histoShots,h,s,p,'probability');
				bH.YData = meanShots;
				tH.String = meanStr;
				tH.Position(2) = currentMean; % updaye ypos of mean string
				subplot(2, 4, [1, 3]);
					yLimPPE = ylim;
				subplot(2, 4, 4);
					ylim(yLimPPE);

			end
			lastPlot = tic;
			drawnow();
		end
		Obj.Stop_Stream();
		Obj.serialObj.flush(); % clean out 
		Obj.verboseOutput = oldVerbose;
	catch ME 
		Obj.Stop_Stream();
		Obj.serialObj.flush(); % clean out 
		Obj.verboseOutput = oldVerbose;
		rethrow(ME);
	end

end 
