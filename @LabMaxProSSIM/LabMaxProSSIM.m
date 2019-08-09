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
    triggerMode; %0 = internal, 1 = external, 2 = CW. SET/GET
    bytesAvailable;
    measurementMode; %0 = W, 1 = J, 2 = DBM
    wavelength;
    triggerLevel; % in uJ
    triggerLevelPercent; % in % of absolute range...
    sensitivityLevel; %0 = low, 1 = medium, 2 = high
    measurementRange;
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
  end

  properties (Constant) % can only be changed here in the def file
    COM_PORT = 'COM22'; % com port of diode pm
    % in geraetemanger: LabMAX-Pro SSIM
    MEASUREMENT_MODE = struct('WATT', 0,'JOULES', 1,'DBM', 2);
    TRIGGER_MODE = struct('INTERNAL',0,'EXTERNAL',1,'CW',2);
    SENSITIVITY_LEVEL = struct('LOW', 0, 'MEDIUM', 1, 'HIGH', 2);
    ITEM_SELECT = struct('PRI', 0, 'QUAD', 1, 'FLAG', 2, 'SEQ', 3, 'PER', 4);
  end

  properties (Constant, Access=private) % can't be changed, can't be seen
    WAVELENGTH = 532;
    TRIGGER_LEVEL_PERCENT = 0.05;

    % constants for serial port
    BAUD_RATE = 115200;  % BaudRate as bits per second
    % messages sent by meter terminated by carriage return (decimal 13) and line feed (decimal 10) pair
    TERMINATOR = 'CR/LF'; % carriage return + linefeed termination
    INPUT_BUFFER_SIZE = 100*2^20; % bytes, 2^20 = 1 MB, so this is 100 MB
    DATA_BITS = 8;
    STOP_BITS = 1;
    FLOW_CONTROL = 'none';
    TIME_OUT = 1 ; %[s], serial port communication timenout
    CONNECT_ON_STARTUP = true;
    METER_ID = 'Coherent,Inc-LabMax-ProSSIM'; %used to check connection to correct device, i.e. pm
  end


  properties (Dependent) %callulated based on other values
  end

  properties (GetAccess=private) % can't be seen but can be set by user
  end

  properties (SetAccess=private) % can be seen but not set by user
    serialObj; % serial port object, required for Matlab to pm comm.
    connectionStatus = 'Connection Closed';  % Connection stored as text
    errorCode; % errors stored as codes here
    sysStatus; % use SYSTem:STATus?
    isConnected = 0;
  end

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% "Standard" methods, i.e. functions which can be called by the user and by
  % the class itself
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Constructor and Desctructor
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function pm = LabMaxProSSIM(~,doConnect)
      % constructor, called when creating instance of this class
      switch nargin
      case 1
        % doConnect = doConnect
      case 0
        doConnect = pm.CONNECT_ON_STARTUP; % use default setting
      otherwise
        short_warn('[PowerMeter] Wrong number of input arguemnts. Using default settings!');
      end

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

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Property Set functions are down here...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Set Setup and Control...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.measurementMode(pm, mode)
    %0 = W, 1 = J, 2 = DBM
      switch mode
          case pm.MEASUREMENT_MODE.WATT
              mode = 'W';
          case pm.MEASUREMENT_MODE.JOULES
              mode = 'J';
          case pm.MEASUREMENT_MODE.DBM
              mode = 'DBM';
          otherwise
              disp('wrong mode');
              disp('0 = W, 1 = J, 2 = DBM');
              return;
      end
      fprintf(pm.serialObj,['CONFigure:MEASure:MODe ' mode]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set Measurement Mode failed');
      else
          disp(['[PowerMeter] Set Measurement Mode ' mode '!']);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.triggerLevelPercent(pm, level)
    %percentage of the trigger
      fprintf(pm.serialObj,['TRIGger:PERcent:LEVel ' num2str(level)]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set trigger level failed');
      else
          disp(['[PowerMeter] Set trigger level ' num2str(level*100) '%!']);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.triggerLevel(pm, level)
      level = level*1e-6;
      fprintf(pm.serialObj,['TRIGger:LEVel ' num2str(level)]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set trigger level failed');
      else
          disp(['[PowerMeter] Set trigger level ' num2str(level*1e6) ' uJ!']);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.wavelength(pm, wavelength)
      fprintf(pm.serialObj,['CONFigure:WAVElength:WAVElength ' num2str(wavelength)]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set wavelength failed.');
      else
          disp(['[PowerMeter] Set wavelength to ' num2str(wavelength) ' nm!']);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.triggerMode(pm, mode)
    %0 = internal, 1 = external, 2 = CW. SET/GET
      switch mode
          case pm.TRIGGER_MODE.INTERNAL
              mode = 'INTernal';
          case pm.TRIGGER_MODE.EXTERNAL
              mode = 'EXTernal';
          otherwise
              disp('wrong mode');
              disp('0 = internal, 1 = external');
              return;
      end
      fprintf(pm.serialObj,['TRIGger:SOURce ' mode]);
      pause(0.5);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      if(isempty(error))
          disp('[PowerMeter] Set trigger mode failed');
      else
          disp(['[PowerMeter] Set trigger mode ' mode]);
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Defines the measurement range of the power meter, available options:
    %     9.1510e-06
    %     92.560e-06
    %     925.00e-06

    function [] = set.measurementRange(pm, range)
      % Disbale auto range function of power meter
      fprintf(pm.serialObj,['CONFigure:RANGE:AUTO OFF']);
      pause(0.25);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      okMessage = regexp(msg,'OK'); % regexp: match regular expression, if
      % regular expressions do not match, e.g. 'car' and 'test' okMessage will
      % be empty
      if(isempty(okMessage))
          disp('[PowerMeter] Set range failed while disabling auto mode.\n');
      end

      % Check desired range and set corresponding serialCommandString
      switch range
        case 9.1510e-06
          serialCommandString = ['CONF:RANGE:SEL 9.1510e-06'];
        case 92.560e-06
          serialCommandString = ['CONF:RANGE:SEL 92.560e-06'];
        case 925.00e-06
          serialCommandString = ['CONF:RANGE:SEL 915.10e-06'];
        otherwise
          warning('[PowerMeter] Invalid range, gonna use 9.1510e-06');
          serialCommandString = ['CONF:RANGE:SEL 9.1510e-06'];
      end

      % Push serialCommandString to power meter and wait for response
      fprintf(pm.serialObj, serialCommandString);
      pause(0.25);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK');
      okMessage = regexp(msg,'OK');
      if(isempty(okMessage))
          disp('[PowerMeter] Set range failed at pushing string to PM.\n');
      end

      fprintf(pm.serialObj,['CONFigure:RANGE:SELect?']);
      pause(0.25);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      range = str2num(msg(1:9));
      disp(['[PowerMeter] Set range level ' num2str(range*1e6) ' uJ.']);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [] = set.itemSelect(pm, items)
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



    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Get Setup and Control...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function measurementMode = get.measurementMode(pm)
      fprintf(pm.serialObj,'CONFigure:MEASure:MODe?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      modeCells = pm.Process_Msg(msg);
      modeChar = modeCells{1};
      switch modeChar
          case 'W'
              measurementMode = pm.MEASUREMENT_MODE.WATT;
          case 'J'
              measurementMode = pm.MEASUREMENT_MODE.JOULES;
          case 'DBM'
              measurementMode = pm.MEASUREMENT_MODE.DBM;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function triggerLevelPercent = get.triggerLevelPercent(pm)
      fprintf(pm.serialObj,'TRIGger:PERcent:LEVel?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      triggerLevelPercent = str2double(pm.Process_Msg(msg));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function triggerLevelPercent = get.triggerLevel(pm)
      fprintf(pm.serialObj,'TRIGger:LEVel?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      triggerLevelPercent = str2double(pm.Process_Msg(msg))*1e6;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function wavelength = get.wavelength(pm)
      fprintf(pm.serialObj,'CONFigure:WAVElength:WAVElength?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      wavelength = str2double(pm.Process_Msg(msg));
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function triggerMode = get.triggerMode(pm)
      fprintf(pm.serialObj,'TRIGger:SOURce?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      modeCells = pm.Process_Msg(msg);
      modeChar = modeCells{1};
      switch modeChar
          case 'INT';
              triggerMode = pm.TRIGGER_MODE.INTERNAL;
          case 'EXT'
              triggerMode = pm.TRIGGER_MODE.EXTERNAL;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function sensitivityLevel = get.sensitivityLevel(pm)
      fprintf(pm.serialObj,'TRIGger:PTJ:LEVel?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      sensCells = pm.Process_Msg(msg);
      senseChar = sensCells{1};
      switch senseChar
          case 'LOW'
              sensitivityLevel = pm.SENSITIVITY_LEVEL.LOW;
          case 'MEDIUM'
              sensitivityLevel = pm.SENSITIVITY_LEVEL.MEDIUM;
          case 'HIGH'
              sensitivityLevel = pm.SENSITIVITY_LEVEL.HIGH;
      end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function range = get.measurementRange(pm)
      fprintf(pm.serialObj,'CONFigure:RANGe:SELect?');
      pause(0.05);
      newBytes = fread(pm.serialObj,pm.bytesAvailable,'char');
      msg = char(newBytes)';
      rangeCells = pm.Process_Msg(msg);
      rangeChar = rangeCells{1};
      range = str2double(rangeChar);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
          end
      end
%       pm.noOfItems = length(itemSelect);
%       pm.items = itemSelect;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % bytes available on serial port
    function bytes = get.bytesAvailable(pm)
      bytes = pm.serialObj.BytesAvailable;
    end


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Processing...
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % not sure this is used...
    function [signal, flag, freq] = Process_Data(pm, response)
        rawData = pm.Process_Msg(response);
            rawSignal = rawData(1:3:end);
            signal = str2double(rawSignal);
            rawFlag = rawData(2:3:end);
            flag = str2double(rawFlag);
            rawFreq = rawData(3:3:end);
            freq = 1./(str2double(rawFreq)*1e-6);
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function response = Process_Msg(pm, msg)
        %get rid of 'CR/LF' 'OK' linebreak and ','
        response = strsplit(msg,{',','\n','OK',char(13),char(12)});
        response(strcmp('',response)) = [];       %remove null
    end

  end


end
