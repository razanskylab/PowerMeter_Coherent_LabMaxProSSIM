function [Stats,rawPPE] = Record_PPE(Obj,measDuration)
  % measures per pulse energies using power meter for given freq, laser power
  % and duration. 
  
  % settings
  smoothWindow = 50; %
  % wait this much shooting laser before starting measurement
  preWait = 0.5*measDuration;
  
  persistent figH;

  F.AQ.verboseOutput = false;
  F.Trigger.verboseOutput = false;

  F.Start_Trigger();
  PBar.progBarStr{end} = 'Pre-Shooting laser...';
  wait_with_progress(preWait,PBar);

  LM.Start_Stream();
  PBar.progBarStr{end} = 'Recording PPEs...';
  wait_with_progress(measDuration,PBar);

  LM.Stop_Stream;
  F.Stop_Trigger();

  [rawPPE] = LM.Read_Buffer;
  if (length(rawPPE) < (F.maxPrf*measDuration))
    short_warn('Power meter is missing shots!');
    rawPPE = [];
    Stats = [];
    return; % don't use theses PPEs as we have prob. not recorded them all
  end

  if any(isnan(rawPPE))
    short_warn('Power meter recorded NaNs...we do not like nans!');
  end

  rawPPE(isnan(rawPPE)) = []; % remove thos anoying NANs
  rawPPE = rawPPE*1e6; % convert to uJ

  meanPPE = mean(rawPPE);
  absStd = std(rawPPE);
  relStd = std(rawPPE)./meanPPE*100;

  relPPE = rawPPE./meanPPE.*100;
  absMovMeanPPE = movmean(rawPPE,smoothWindow);
  relMovMeanPPE = absMovMeanPPE./meanPPE.*100;

  stdPPE = movstd(rawPPE,3)./meanPPE.*100; % get local std in %
  movStdPPE = movmean(stdPPE,smoothWindow);

  % generate Stats struct
  Stats.rawPPE = rawPPE; 
  Stats.relPPE = relPPE; 

  Stats.meanPPE = meanPPE; 
  Stats.absStd = absStd; % in uJ
  Stats.relStd = relStd; % in % of mean PPE
  Stats.maxDiff = diff(minmax(relPPE));

  if isempty(rawPPE)
    short_warn('We have not measured a single shot!');
    return; % nothing measured...we warned the user, nothing else to do here...
  end

  % plot the current measurement results
  dT = 1./F.maxPrf;
  tPlot = (0:numel(rawPPE)-1)*dT;
  
  if isempty(figH) || ~ishandle(figH)
    figH = figure();
  else
    figure(figH);
    clf;
  end
  tiledlayout('flow');
    
  nexttile();
    plot(tPlot,rawPPE,'.');
    hold on;
    plot(tPlot,absMovMeanPPE,'Linewidth',2);
    axis tight;
    title('Absolute Per Pulse Energies');
    xlabel('time (s)');
    legend({'raw PPE','moving mean'});
  
  nexttile();
    plot(tPlot,relPPE,'.');
    hold on;
    plot(tPlot,relMovMeanPPE,'Linewidth',2);
    axis tight;
    title('Relative Per Pulse Energies');
    xlabel('time (s)');
    legend({'raw PPE','moving mean'});

  nexttile();
    plot(tPlot,stdPPE,'.');
    hold on;
    plot(tPlot,movStdPPE,'Linewidth',2);
    axis tight;
    title('Per Pulse Energies Fluctuations');
    xlabel('time (s)');
    legend('moving std (%)');
    legend({'raw std','moving mean std'});

  nexttile();
    pretty_hist(rawPPE);
    axis tight;
    title('shot distribution');
  drawnow();
end