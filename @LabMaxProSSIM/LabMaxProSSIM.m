% File: LabMaxProSSIM.m at LabMaxProSSIM
% Author: Johannes Rebling, Urs Hofmann
% Version: 1.2

% Description: MATLAB class to control and read the power meter.

% Changelog:
% 180706: Added set for different sensitivity levels (set.measurementRange)
% 200831: Complete overhaul of class, basing it on SuperClass, bug fixing, 
  % better plotting, proper range select and many more goodies...

classdef LabMaxProSSIM < BaseHardwareClass

  properties % default properties, probaly most of your data
    classId char = '[PM]'; % this is displayed when using VPrintF_With_ID
    COM_PORT(1, :) char; % com port of diode pm
    triggerMode(1, 1) uint8; % 0 = internal, 1 = external
    measurementMode(1, 1) uint8 = 1; %0 = W, 1 = J, 2 = DBM
    wavelength(1, 1) single; % wavelength measured [nm]
    triggerLevel(1, 1) single; % in uJ
    triggerLevelPercent(1, 1) single; % in % of absolute range...
    measurementRange(1, 1) double = LabMaxProSSIM.MEAS_RANGES.LOW; 

    % Data items that appear in a measurement data record are selectable.
    itemSelect; %0 = PRI, 1 = QUAD, 2 = FLAG, 3 = SEQ, 4 = PER
                % PRI Primary data value (includes Watts or Joules)
                % QUAD X, Y coordinate values for quad LM probes
                % FLAG Flags
                % SEQ Sequence ID
                % PER Pulse period (expressed in uSec, Joules mode)
    flagVerbose(1, 1) logical = 1;
    flagWavelengthcorrection(1, 1) logical = 1; % correct for wavelength?
    flagAreaCorrection(1, 1) logical = 0; % correct for sensor area?
    flagSpeedup(1, 1) logical = 0;
    flagRangeAuto(1, 1) logical = 0;
  end

  properties (Constant) % can only be changed here in the def file
    MEASUREMENT_MODE = struct('WATT', 0, 'JOULES', 1, 'DBM', 2);
    TRIGGER_MODE = struct('INTERNAL', 0, 'EXTERNAL', 1, 'CW',2);
    MEAS_RANGES = struct('LOW', 0, 'MEDIUM', 1, 'HIGH', 2);
      % 1 - low range <= 11.72 uJ
      % 2 - mid range <= 119.0 uJ
      % 3 - high range <= 1189 uJ
    ITEM_SELECT = struct('PRI', 0, 'QUAD', 1, 'FLAG', 2, 'SEQ', 3, 'PER', 4);
    % default values use when running Obj.Initialize();
    DEFAULT_WAVELENGTH(1, 1) double = 532;
    DEFAULT_TRIGGER_LEVEL(1, 1) double = 700e-9; % high enough to not cause false triggers
    DEFAULT_TRIG_MODE = LabMaxProSSIM.TRIGGER_MODE.INTERNAL;
    DEFAULT_MEAS_MODE = LabMaxProSSIM.MEASUREMENT_MODE.JOULES;
    DEFAULT_MEAS_RANGE = LabMaxProSSIM.MEAS_RANGES.LOW;
  end

  properties (Constant, Access=private) % can't be changed, can't be seen
    CONNECT_ON_STARTUP(1, 1) logical = true;
    BAUD_RATE(1, 1) double = 115200;  % BaudRate as bits per second
    READTERMINATOR(1, :) char = 'CR/LF'; % carriage return + linefeed termination 
    WRITETERMINATOR(1, :) char = 'CR'; % carriage return + linefeed termination 
    INPUT_BUFFER_SIZE = 100 * 2^20; % bytes, 2^20 = 1 MB, so this is 100 MB
    DATA_BITS(1, 1) = 8;
    STOP_BITS(1, 1) = 1;
    FLOW_CONTROL(1, :) char = 'none';
    PARITY(1, :) char = 'none';
    TIME_OUT(1, 1) double = 3; %[s], serial port communication timeout
    METER_ID(1, :) char = 'Coherent, Inc - LabMax-Pro '; %used to check connection to correct device, i.e. pm
    serialWaitTime(1, 1) single = 0.2;
  end


  properties (Dependent) %callulated based on other values
    bytesAvailable;
    flagHandshaking; % we always want handshaking I think...
  end

  properties (GetAccess=private) % can't be seen but can be set by user
  end

  properties (SetAccess=private) % can be seen but not set by user
    COM_PORT(1, :) char = 'COM5'; % com port of diode pm
    serialObj; % serial port object, required for Matlab to pm comm.
    connectionStatus = 'Connection Closed';  % Connection stored as text
    errorCode; % errors stored as codes here
    sysStatus; % use SYSTem:STATus?
    isConnected(1, 1) logical = 0;
    sensitivityLevel(1, 1); % 0 = low, 1 = medium, 2 = high
  end

  %% "Standard" methods, 
  methods

    %---------------------------------------------------------------------------
    function This = LabMaxProSSIM(varargin)
      % constructor, called when creating instance of this class
      if nargin < 1
        doConnect = true;
      end

      if (nargin >= 1)
        doConnect = varargin{1};
      end

      pm.COM_PORT = get_com_port('PM');

      % connect to power meter on startup
      if doConnect
        success = This.Open_Connection;
        if (success == 1)
            This.Reset();
        end
        This.Measure_Noise_Floor(true);
      else
        fprintf('[PowerMeter] Initialized but not connected yet.\n')
      end
    end

    %---------------------------------------------------------------------------
    function delete(Obj)
      Obj.Close_Connection();
    end

    %---------------------------------------------------------------------------
    function bytesRemoved = Clear_Serial_Buffer(Obj)
      bytesRemoved = Obj.bytesAvailable;
      Obj.serialObj.flush(); % just to be on the safe side... 
      if bytesRemoved
        infoStr = sprintf('Cleared %i Bytes from serial buffer!\n', bytesRemoved);
        Obj.VPrintF_With_ID(infoStr);
      end
      remainingBytes = Obj.bytesAvailable;
      if remainingBytes
        short_warn('Bytes remained after clearing the buffer!');
      end
    end

    function response = Process_Msg(~, msg)
      % get rid of 'CR/LF' 'OK' linebreak and ','
      response = strsplit(msg,{',', '\n', 'OK', char(13), char(12)});
      response(strcmp('',response)) = [];       %remove null
    end

    function [] = Display_Status(Obj)
      Obj.VPrintF_With_ID(['Connection Status: '  Obj.connectionStatus '\n']);
    end
  end

  % SET/GET Methods
  methods 
    
    %---------------------------------------------------------------------------
    % bytes available on serial port
    function bytes = get.bytesAvailable(pm)
      bytes = pm.serialObj.NumBytesAvailable;
    end

    % --------------------------------------------------------------------------
    % set/get triggerMode 0 = internal, 1 = external 
    function set.triggerMode(Obj, mode)
      % 0 = internal, 1 = external, 2 = CW. SET/GET
      switch mode
        case Obj.TRIGGER_MODE.INTERNAL
          mode = 'INTernal';
        case Obj.TRIGGER_MODE.EXTERNAL
          mode = 'EXTernal';
        otherwise
          txtMsg = 'wrong mode, options: 0 = internal, 1 = external';
          error(txtMsg);
      end
      txtMsg = ['TRIGger:SOURce ' mode];
      Obj.Set_Property(txtMsg);
    end
    function triggerMode = get.triggerMode(Obj)
      triggerMode = Obj.Query('TRIGger:SOURce?');
      switch triggerMode
        case 'INT';
          triggerMode = Obj.TRIGGER_MODE.INTERNAL;
        case 'EXT'
          triggerMode = Obj.TRIGGER_MODE.EXTERNAL;
      end
    end

    % --------------------------------------------------------------------------
    % set/get measurementMode 0 = W, 1 = J, 2 = DBM  
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

    
    % set/get wavelength (nm) 
    function set.wavelength(pm, wavelength)
      txtMsg = ['CONFigure:WAVElength:WAVElength ' num2str(wavelength)];
      pm.Set_Property(txtMsg);
    end

    function wavelength = get.wavelength(pm)
      wavelength = str2double(pm.Query('CONFigure:WAVElength:WAVElength?'));
    end

    % set/get absolute level in J 
    function set.triggerLevel(pm, level)
      txtMsg = ['TRIGger:LEVel ' num2str(level)];
      pm.Set_Property(txtMsg);
    end

    function triggerLevel = get.triggerLevel(pm)
      triggerLevel = str2double(pm.Query('TRIGger:LEVel?'));
    end   

    % set/get trigger level in percent from device 
    function set.triggerLevelPercent(pm, levelPercent)
      txtMsg = ['TRIGger:PERcent:LEVel ' num2str(levelPercent)];
      pm.Set_Property(txtMsg);
    end

    function triggerLevelPercent = get.triggerLevelPercent(pm)
      triggerLevelPercent = str2double(pm.Query('TRIGger:PERcent:LEVel?'));
    end

    function set.measurementRange(Obj, range)
      Obj.flagRangeAuto = false; % disable auto range just in case...
      switch range
        case 0 % low
          serialCommandString = 'CONF:RANGE:SEL 0.000008';
        case 1 % mid
          serialCommandString = 'CONF:RANGE:SEL 0.000080';
        case 2 % high
          serialCommandString = 'CONF:RANGE:SEL 0.000800';
        otherwise
          error('Invalid range');
      end

      % Push serialCommandString to power meter and wait for response
      writeline(Obj.serialObj, serialCommandString);
      Obj.Acknowledge();
    end
    function measurementRange = get.measurementRange(Obj)
      [answer] = Obj.Query('CONF:RANG:SEL?');
      measurementRange = str2double(answer);
      if measurementRange <= 15e-06
        Obj.VPrintF_With_ID('Low measurement range (max is ~9-11 uJ).\n');
      elseif measurementRange <= 150e-06
        Obj.VPrintF_With_ID('Medium measurement range (max is ~90-110 uJ).\n');
      else
        Obj.VPrintF_With_ID('High measurement range (max is ~1 mJ).\n');
      end
    end
 
    function flagHandshaking = get.flagHandshaking(pm)
      txtMsg = ['SYSTem:COMMunicate:HANDshaking?'];
      answer = pm.Query(txtMsg);
      if strcmp(answer, 'OFF')
        flagHandshaking = 0;
      else
        flagHandshaking = 1;
      end
    end

    % flagRangeAuto ------------------------------------------------------------
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

    % --------------------------------------------------------------------------
    % set/get data items from power meter
    function set.itemSelect(pm, items)

      %0 = PRI, 1 = QUAD, 2 = FLAG, 3 = SEQ, 4 = PER
      itemCom = [];
      for index=1:length(items)
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
      newBytes = fread(pm.serialObj,pm.serialObj.NumBytesAvailable,'char');
      msg = char(newBytes)';
      error = regexp(msg,'OK','once');
      if(isempty(error))
          disp('[PowerMeter] Set item select failed');
      else
          disp(['[PowerMeter] Set item select ' itemCom]);
      end
      % pm.noOfItems = length(items);
    end
    function itemSelect = get.itemSelect(pm)
      itemSelect = [];
      fprintf(pm.serialObj,'CONFigure:ITEMselect?');
      pause(0.1);
      newBytes = fread(pm.serialObj,pm.serialObj.NumBytesAvailable,'char');
      msg = char(newBytes)';
      itemCells = pm.Process_Msg(msg);
      for index = length(itemCells):-1:1
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

    % flagAreaCorrection -------------------------------------------------------
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

    % flagSpeedup, no idea what this acutally does -----------------------------
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

    % flagWavelengthcorrection --------------------------------------------------
    function set.flagWavelengthcorrection(pm, flagWavelengthcorrection)
      if flagWavelengthcorrection
        strOnOff = 'ON';
      else
        strOnOff = 'OFF';  
      end
      txtMsg = ['CONFigure:WAVElength:CORRection ', strOnOff];
      pm.Set_Property(txtMsg);
    end
    function flagWavelengthcorrection = get.flagWavelengthcorrection(pm)
      txtMsg = ['CONFigure:WAVElength:CORRection?'];
      answer = pm.Query(txtMsg);
      if strcmp(answer, 'OFF')
        flagWavelengthcorrection = 0;
      else
        flagWavelengthcorrection = 1;
      end
    end
  end
end