% File: LabMaxProSSIM.m at LabMaxProSSIM
% Author: Johannes Rebling, Urs Hofmann
% Version: 1.2

% Description: MATLAB class to control and read the power meter.

% TODO:
% change range set to just use 1/2/3 or low/med/high!

% Changelog:
% 180706: Added set for different sensitivity levels (set.measurementRange)

classdef LabMaxProSSIM < handle

  properties % default properties, probaly most of your data
    triggerMode(1, 1) uint8; % 0 = internal, 1 = external, 2 = CW. SET/GET
    bytesAvailable;
    measurementMode(1, 1) uint8; %0 = W, 1 = J, 2 = DBM
    wavelength(1, 1) single; % wavelength measured [nm]
    triggerLevel(1, 1) single; % in uJ
    triggerLevelPercent(1, 1) single; % in % of absolute range...
    sensitivityLevel(1, 1); % 0 = low, 1 = medium, 2 = high
    measurementRange(1, 1) double;
    %     9.1510e-06
    %     92.560e-06
    %     925.00e-06
    itemSelect; %0 = PRI, 1 = QUAD, 2 = FLAG, 3 = SEQ, 4 = PER
                %PRI Primary data value (includes Watts or Joules)
                %QUAD X, Y coordinate values for quad LM probes
                %FLAG Flags
                %SEQ Sequence ID
                %PER Pulse period (expressed in uSec, Joules mode)
%     noOfItems = 1;
%     items = 0
    flagVerbose(1, 1) logical = 1;
    flagHandshaking(1, 1) logical = 1;
    flagWavelengthcorrection(1, 1) logical = 1;
    flagAreaCorrection(1, 1) logical = 0;
    flagSpeedup(1, 1) logical = 0;
    flagRangeAuto(1, 1) logical = 0;
  end

  properties (Constant) % can only be changed here in the def file
    % in geraetemanger: LabMAX-Pro SSIM
    MEASUREMENT_MODE = struct('WATT', 0, 'JOULES', 1, 'DBM', 2);
    TRIGGER_MODE = struct('INTERNAL', 0, 'EXTERNAL', 1, 'CW',2);
    SENSITIVITY_LEVEL = struct('LOW', 0, 'MEDIUM', 1, 'HIGH', 2);
    ITEM_SELECT = struct('PRI', 0, 'QUAD', 1, 'FLAG', 2, 'SEQ', 3, 'PER', 4);
  end

  properties (Constant, Access=private) % can't be changed, can't be seen
    WAVELENGTH(1, 1) double = 532;
    TRIGGER_LEVEL_PERCENT(1, 1) double = 0.05;
    BAUD_RATE(1, 1) double = 115200;  % BaudRate as bits per second
    READTERMINATOR(1, :) char = 'CR/LF'; % carriage return + linefeed termination 
    WRITETERMINATOR(1, :) char = 'CR'; % carriage return + linefeed termination 
    INPUT_BUFFER_SIZE = 100 * 2^20; % bytes, 2^20 = 1 MB, so this is 100 MB
    DATA_BITS(1, 1) = 8;
    STOP_BITS(1, 1) = 1;
    FLOW_CONTROL(1, :) char = 'none';
    PARITY(1, :) char = 'none';
    TIME_OUT(1, 1) single = 1 ; %[s], serial port communication timeout
    CONNECT_ON_STARTUP(1, 1) logical = true;
    METER_ID(1, :) char = 'Coherent, Inc - LabMax-Pro '; %used to check connection to correct device, i.e. pm
    serialWaitTime(1, 1) single = 0.2;
  end


  properties (Dependent) %callulated based on other values
  end

  properties (GetAccess=private) % can't be seen but can be set by user
  end

  properties (SetAccess=private) % can be seen but not set by user
    COM_PORT(1, :) char = 'COM5'; % com port of diode pm
    serialObj; % serial port object, required for Matlab to pm comm.
    connectionStatus = 'Connection Closed';  % Connection stored as text
    errorCode; % errors stored as codes here
    sysStatus; % use SYSTem:STATus?
    isConnected(1, 1) logical = 0; % is the serial connection open
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and Desctructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function pm = LabMaxProSSIM(~, doConnect)
      % constructor, called when creating instance of this class
      switch nargin
        case 1
          % doConnect = doConnect
        case 0
          doConnect = pm.CONNECT_ON_STARTUP; % use default setting
        otherwise
          short_warn('[PowerMeter] Wrong number of input arguemnts. Using default settings!');
      end

      pm.COM_PORT = get_com_port('PM');

      % connect to power meter on startup
      if doConnect
        pm.Open_Connection;
        pm.Initialize;
      else
        fprintf('[PowerMeter] Initialized but not connected yet.\n')
      end
    end

    function delete(pm)
      %FIXME: disconnect here
      if pm.isConnected
        % disconnect
        pm.Close_Connection;
      end
    end

    function set.measurementMode(pm, measurementMode)
      % 0 = W, 1 = J, 2 = DBM
      switch measurementMode
        case pm.MEASUREMENT_MODE.WATT
          measurementMode = 'W';
        case pm.MEASUREMENT_MODE.JOULES
          measurementMode = 'J';
        case pm.MEASUREMENT_MODE.DBM
          measurementMode = 'DBM';
        otherwise
          error('Invalid mode, 0 = W, 1 = J, 2 = DBM');
      end

      txtMsg = ['CONFigure:MEASure:MODe ', measurementMode];
      pm.Set_Property(txtMsg);
    end

    % define trigger level of power meter in percent
    function set.triggerLevelPercent(pm, levelPercent)
      txtMsg = ['TRIGger:PERcent:LEVel ' num2str(levelPercent)];
      pm.Set_Property(txtMsg);
    end

    % define trigger level of power meter in joule
    function set.triggerLevel(pm, level)
      txtMsg = ['TRIGger:LEVel ' num2str(level)];
      pm.Set_Property(txtMsg);
    end

    % set wavelength for measurement
    function set.wavelength(pm, wavelength)
      txtMsg = ['CONFigure:WAVElength:WAVElength ' num2str(wavelength)];
      pm.Set_Property(txtMsg);
    end

    % handshaking on or off, ie should we return OK after successful operations
    function set.flagHandshaking(pm, flagHandshaking)
      if flagHandshaking
        strOnOff = 'ON';
      else
        strOnOff = 'OFF';  
      end
      txtMsg = ['SYSTem:COMMunicate:HANDshaking ', strOnOff];
      pm.Set_Property(txtMsg, flagHandshaking);
      pm.flagHandshaking = flagHandshaking;
    end

    % this would be the function to get this value from the device, we want
    % to avoid unnecessary serial communication though
    % function flagHandshaking = get.flagHandshaking(pm, flagHandshaking)
    %   txtMsg = ['SYSTem:COMMunicate:HANDshaking?'];
    %   answer = pm.Query(txtMsg, 0);
    %   if strcmp(answer, 'OFF')
    %     flagHandshaking = 0;
    %   else
    %     flagHandshaking = 1;
    %   end
    % end

    

    % trigger mode of powermeter
    function set.triggerMode(pm, mode)
      % 0 = internal, 1 = external, 2 = CW. SET/GET
      switch mode
        case pm.TRIGGER_MODE.INTERNAL
          mode = 'INTernal';
        case pm.TRIGGER_MODE.EXTERNAL
          mode = 'EXTernal';
        otherwise
          txtMsg = 'wrong mode, options: 0 = internal, 1 = external';
          error(txtMsg);
      end
      txtMsg = ['TRIGger:SOURce ' mode];
      pm.Set_Property(txtMsg);
    end

    % Defines the measurement range of the power meter, available options:
    %     9.1510e-06
    %     92.560e-06
    %     925.00e-06
    function set.measurementRange(pm, range)
      % Disbale auto range function of power meter
      writeline(pm.serialObj, 'CONFigure:RANGE:AUTO OFF');
      pm.Acknowledge();
      
      % Check desired range and set corresponding serialCommandString
      switch range
        case 9.1510e-06
          serialCommandString = ['CONF:RANGE:SEL 9.1510e-06'];
        case 92.560e-06
          serialCommandString = ['CONF:RANGE:SEL 92.560e-06'];
        case 925.00e-06
          serialCommandString = ['CONF:RANGE:SEL 915.10e-06'];
        otherwise
          error('Invalid range');
      end

      % Push serialCommandString to power meter and wait for response
      writeline(pm.serialObj, serialCommandString);
      pm.Acknowledge();

    end

    function measurementRange = get.measurementRange(pm)
      measurementRange = str2double(pm.Query('CONFigure:RANGe:SELect?'));
    end


    function set.itemSelect(pm, items)
    %%0 = PRI, 1 = QUAD, 2 = FLAG, 3 = SEQ, 4 = PER
      itemCom = [];
      for index=1:length(items);
          switch items(index)
              case pm.ITEM_SELECT.PRI
                  itemCom = [itemCom 'PRI,'];
              case pm.ITEM_SELECT.QUAD
                  itemCom = [itemCom 'QUAD,'];
              case pm.ITEM_SELECT.FLAG
                  itemCom = [itemCom 'FLAG,'];
              case pm.ITEM_SELECT.SEQ
                  itemCom = [itemCom 'SEQ,'];
              case pm.ITEM_SELECT.PER
                  itemCom = [itemCom 'PER,'];
              otherwise
                  disp('wrong item');
                  disp('0 = PRI, 1 = QUAD, 2 = FLAG, 3 = SEQ, 4 = PER');
                  return;
          end
      end
      itemCom = itemCom(1:end-1);
      fprintf(pm.serialObj,['CONFigure:ITEMselect ' itemCom]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set item select failed');
      else
          disp(['[PowerMeter] Set item select ' itemCom]);
      end
%       pm.noOfItems = length(items);
%       pm.items = items;
    end

    % return measurement mode from device
    function measurementMode = get.measurementMode(pm)
      measurementMode = pm.Query('CONFigure:MEASure:MODe?');
      switch measurementMode
        case 'W'
          measurementMode = pm.MEASUREMENT_MODE.WATT;
        case 'J'
          measurementMode = pm.MEASUREMENT_MODE.JOULES;
        case 'DBM'
          measurementMode = pm.MEASUREMENT_MODE.DBM;
        otherwise
          error('Invalid measurement mode returned from device');
      end
    end

    % return trigger level in percent from device
    function triggerLevelPercent = get.triggerLevelPercent(pm)
      triggerLevelPercent = str2double(pm.Query('TRIGger:PERcent:LEVel?'));
    end

    % return trigger level from device
    function triggerLevel = get.triggerLevel(pm)
      triggerLevel = str2double(pm.Query('TRIGger:LEVel?'));
    end

    % returns wavelength in nm
    function wavelength = get.wavelength(pm)
      wavelength = str2double(pm.Query('CONFigure:WAVElength:WAVElength?'));
    end

    function triggerMode = get.triggerMode(pm)
      triggerMode = pm.Query('TRIGger:SOURce?');
      switch triggerMode
          case 'INT';
              triggerMode = pm.TRIGGER_MODE.INTERNAL;
          case 'EXT'
              triggerMode = pm.TRIGGER_MODE.EXTERNAL;
      end
    end

    % return sensitivity level of powermeter
    function sensitivityLevel = get.sensitivityLevel(pm)
      sensitivityLevel = pm.Query('TRIGger:PTJ:LEVel?');
      switch sensitivityLevel
        case 'LOW'
          sensitivityLevel = pm.SENSITIVITY_LEVEL.LOW;
        case 'MEDIUM'
          sensitivityLevel = pm.SENSITIVITY_LEVEL.MEDIUM;
        case 'HIGH'
          sensitivityLevel = pm.SENSITIVITY_LEVEL.HIGH;
        otherwise
          error('Invalid sensitivity level passed');
      end
    end

    % flagAreaCorrection
    function set.flagAreaCorrection(pm, flagAreaCorrection)
      if flagAreaCorrection
        modeTxt = 'ON';
      else
        modeTxt = 'OFF';
      end
      txtMsg = ['CONFigure:AREA:CORRection ', modeTxt];
      pm.Set_Property(txtMsg);
    end

    function flagAreaCorrection = get.flagAreaCorrection(pm)
      response = pm.Query('CONFigure:AREA:CORRection?');
      switch response
        case 'ON'
          flagAreaCorrection = 1;
        case 'OFF'
          flagAreaCorrection = 0;
        otherwise
          error('Powermeter returned invalid response'); 
      end
    end

    % flagSpeedup
    function set.flagSpeedup(pm, flagSpeedup)
      if flagSpeedup
        modeTxt = 'ON';
      else
        modeTxt = 'OFF';
      end
      txtMsg = ['CONFigure:SPEedup ', modeTxt];
      pm.Set_Property(txtMsg);
    end

    function flagSpeedup = get.flagSpeedup(pm)
      response = pm.Query('CONFigure:SPEedup?');
      switch response
        case 'ON'
          flagSpeedup = 1;
        case 'OFF'
          flagSpeedup = 0;
        otherwise
          error('Powermeter returned invalid response'); 
      end
    end

    % flagWavelengthcorrection
    function set.flagWavelengthcorrection(pm, flagWavelengthcorrection)
      if flagWavelengthcorrection
        strOnOff = 'ON';
      else
        strOnOff = 'OFF';  
      end
      txtMsg = ['CONFigure:WAVElength:CORRection ', strOnOff];
      pm.Set_Property(txtMsg, pm.flagHandshaking);
    end

    function flagWavelengthcorrection = get.flagWavelengthcorrection(pm)
      txtMsg = ['CONFigure:WAVElength:CORRection?'];
      answer = pm.Query(txtMsg, 0);
      if strcmp(answer, 'OFF')
        flagWavelengthcorrection = 0;
      else
        flagWavelengthcorrection = 1;
      end
    end

    % flagRangeAuto
    function set.flagRangeAuto(pm, flagRangeAuto)
      if flagRangeAuto
        modeTxt = 'ON';
      else
        modeTxt = 'OFF';
      end
      txtMsg = ['CONFigure:RANGe:AUTO ', modeTxt];
      pm.Set_Property(txtMsg);
    end

    function flagRangeAuto = get.flagRangeAuto(pm)
      response = pm.Query('CONFigure:RANGe:AUTO?');
      switch response
        case 'ON'
          flagRangeAuto = 1;
        case 'OFF'
          flagRangeAuto = 0;
        otherwise
          error('Powermeter returned invalid response'); 
      end
    end

    function itemSelect = get.itemSelect(pm)
      itemSelect = [];
      fprintf(pm.serialObj,'CONFigure:ITEMselect?');
      pause(0.1);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      itemCells = pm.Process_Msg(msg);
      for index=1:length(itemCells)
        switch itemCells{index}
          case 'PRI'
            itemSelect(index) = pm.ITEM_SELECT.PRI;
          case 'QUAD'
            itemSelect(index) = pm.ITEM_SELECT.QUAD;
          case 'FLAG'
            itemSelect(index) = pm.ITEM_SELECT.FLAG;
          case 'SEQ'
            itemSelect(index) = pm.ITEM_SELECT.SEQ;
          case 'PER'
            itemSelect(index) = pm.ITEM_SELECT.PER;
          otherwise
            error('Invalid option passed');
        end
      end
    end

    % bytes available on serial port
    function bytes = get.bytesAvailable(pm)
      bytes = pm.serialObj.NumBytesAvailable;
    end

    function response = Process_Msg(pm, msg)
      % get rid of 'CR/LF' 'OK' linebreak and ','
      response = strsplit(msg,{',', '\n', 'OK', char(13), char(12)});
      response(strcmp('',response)) = [];       %remove null
    end

  end
end