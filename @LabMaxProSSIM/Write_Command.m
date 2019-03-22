function [] = Write_Command(pm,command)
  fprintf(pm.serialObj,'%s\n',command);
  returnMessage = fscanf(pm.serialObj,'%s\n');
  if ~strcmp(returnMessage,'OK')
    short_warn('Writing pm command failed!');
    fprintf(['Last message was: "' returnMessage '"\n']);
  end
end
