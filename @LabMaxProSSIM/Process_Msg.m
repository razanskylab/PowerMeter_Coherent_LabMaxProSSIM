function response = Process_Msg(~, msg)
      % get rid of '
      % CR/LF' 'OK' linebreak and ','
      response = strsplit(msg,{',', '\n', 'OK', char(13), char(12)});
      response(strcmp('',response)) = [];       %remove null
end