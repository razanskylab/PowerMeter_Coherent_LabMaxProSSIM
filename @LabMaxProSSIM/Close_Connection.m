function [] = Close_Connection(pm)
  % close serial connection to pm, delete serialObj
  fclose(pm.serialObj);  % always, always want to close serial connection
  delete(pm.serialObj);
  pm.connectionStatus = 'Power Meter Connection Closed';
  pm.isConnected = 0;
  fprintf('[PowerMeter] Connection closed.\n');
end
