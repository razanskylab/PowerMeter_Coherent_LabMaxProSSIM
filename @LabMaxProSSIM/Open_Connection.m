function [] = Open_Connection(pm)
  % open serial connection to pm on COM_PORT, creates serial obj
  % also displays pm status
  fprintf('[PowerMeter] Establishing connection...');

  % add serachpath to where waitbar fct
  pm.serialObj = instrfind('Type', 'serial', 'Port', pm.COM_PORT);

  % Create the serial port object if it does not exist
  % otherwise use the object that was found.
  if isempty(pm.serialObj)
    pm.serialObj = serial(pm.COM_PORT);
  else
    fclose(pm.serialObj);
    pm.serialObj = pm.serialObj(1);
  end

  % setup serial connection correctly
  set(pm.serialObj, 'BaudRate', pm.BAUD_RATE);
  set(pm.serialObj, 'Terminator',pm.TERMINATOR);
  set(pm.serialObj, 'Timeout', pm.TIME_OUT);
  set(pm.serialObj, 'InputBufferSize', pm.INPUT_BUFFER_SIZE);
  set(pm.serialObj, 'DataBits', pm.DATA_BITS);
  set(pm.serialObj, 'StopBits', pm.STOP_BITS);
  set(pm.serialObj, 'FlowControl', pm.FLOW_CONTROL);

  fopen(pm.serialObj); % Connect to pm

  id = Query(pm,'*IDN?');
  isCorrectMeter = strcmp(id(1:27),pm.METER_ID);
  connectionIsOpen = strcmp(pm.serialObj.Status,'open');
  if (connectionIsOpen && isCorrectMeter)
    pm.connectionStatus = 'Connected';
    pm.isConnected = 1;
    disp(pm.connectionStatus);
  else
    disp('[PowerMeter] Connection NOT established!');
    disp(['isCorrectMeter: ' isCorrectMeter]);
    disp(['connectionIsOpen: ' connectionIsOpen]);
    return;
  end
end
