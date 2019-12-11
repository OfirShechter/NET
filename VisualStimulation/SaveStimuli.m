function SaveStimuli(obj,stimname,varargin)
%SAVESTIMULI Summary of this function goes here
%   Detailed explanation goes here
NSKToolBoxMainDir=fileparts(which('identifierOfMainDir4NSKToolBox'));
NSKToolBoxMainDir=regexp(NSKToolBoxMainDir,filesep,'split');
NSKToolBoxMainDir=fullfile(NSKToolBoxMainDir{1:end-1});
savepath=fscanf(fopen([NSKToolBoxMainDir filesep 'NET' filesep 'PCspecificFiles' filesep 'stimSavePath.txt']),'%c');
savepath = strcat(savepath,filesep,obj.user,filesep);
if IsWin
    savepath= strrep(savepath,'\', '\\');
else
    savepath= strrep(savepath,'\', '/');
end
filename = sprintf(strcat(savepath, stimname,'_%s.mat'), datestr(now,'mm_dd_yyyy_HHMM'));
save(filename, 'varargin', 'obj', '-v7.3');

end

