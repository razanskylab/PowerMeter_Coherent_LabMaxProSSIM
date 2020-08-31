function pm_reset_plot(src,event,Obj)
  setappdata(src.Parent,'firstPlot',1); % forces a redrawing of all axis
  Obj.VPrintF('Reset plot!\n');
  Obj.Plot_Scope('reset');
end
