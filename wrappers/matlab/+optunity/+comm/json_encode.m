function [ json ] = json_encode( struct )
%JSON_ENCODE Encodes the given struct in json format.

if isstruct(struct)
    fields = fieldnames(struct);
    strings = arrayfun(@(x) ['"',fields{x},'": ', ...
        optunity.comm.json_encode(struct.(fields{x}))], ...
        1:numel(fields),'UniformOutput',false);
    json = ['{',strjoin(strings,', '),'}'];
    
elseif ischar(struct)
    json = ['"',struct,'"'];
    
elseif numel(struct) > 1
    strings = arrayfun(@(x) optunity.comm.json_encode(x), struct,'UniformOutput',false);
    json = ['[', strjoin(strings,', '),']'];
    
elseif isnumeric(struct)
    json = num2str(struct);
    
elseif islogical(struct)
    if struct
        json = 'true';
    else
        json = 'false';
    end 
elseif iscell(struct)
    strs = cellfun(@(x) optunity.comm.json_encode(x), struct, 'UniformOutput', false);
    json = strjoin(strs, ', ');
else
    error('UNKNOWN DATA');
end
end


function str = strjoin(data, delim)
if iscell(data)
    str = cellfun(@(x) [x, delim], data, 'UniformOutput', false);
else
    error('NOT IMPLEMENTED!');
    %     str = arrayfun(@(x) [x, delim], data, 'UniformOutput', false);
end
% str
cat = str{1};
for ii=2:numel(str)
    cat = [cat, str{ii}];
end
% str = cell2mat(str);
str = cat(1:end-numel(delim));
end