function Clear_Error(Obj)
  % Clears all error records in the error queue
  tic;
  Obj.VPrintF_With_ID('Clearing all errors...\n');
  writeline(Obj.serialObj,'SYSTem:ERRor:CLEar');
  Obj.Acknowledge();
  Obj.Done(toc);
end
