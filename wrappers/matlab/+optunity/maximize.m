function [solution, details] = maximize( solver, f, varargin)
%MAXIMIZE: Maximizes f using the given solver and extra options.
%
% This function accepts the following arguments:
% - solver: an Optunity solver, as generated by optunity.make_solver()
% - f: the objective function to be maximized
% - varargin: a list of optional key:value pairs
%   - constraints: a list of domain constraints on f (see details below)
%   - default: default function value if constraints are violated
%   - call_log: struct representing an existing call log of f
%   - return_call_log: (boolean) whether or not to return a call log
%
% Constraints on the domain of f can be formulated via a struct.
% The following constraints are available:
% - ub_{oc}: upper bound (open or closed)
% - lb_{oc}: lower bound (open or closed)
% - range_{oc}{oc}: lower and upper bound (open or closed x2)
% To use constraints, create a struct with the appropriate fields. The
% values are new structs mapping argument names to their constraint.
% Example: constrain argument 'x' to the range (1, 3]:
% constraints = struct('range_oc', struct('x', [1, 3]));

%% process varargin
defaults = struct('constraints', NaN, ...
    'call_log', NaN, ...
    'return_call_log', false, ...
    'default',NaN);
options = optunity.process_varargin(defaults, varargin);

%% launch SOAP subprocess
[m2py, py2m, stderr, subprocess, cleaner] = optunity.comm.launch();

pipe_send = @(data) optunity.comm.writepipe(m2py, optunity.comm.json_encode(data));
pipe_receive = @() optunity.comm.json_decode(optunity.comm.readpipe(py2m));

%% initialize solver
msg = struct('solver',solver.name,'config',solver.config,'return_call_log',options.return_call_log);
if isstruct(options.constraints)
    msg.constraints = options.constraints;
    if ~isnan(options.default)
        msg.default = options.default;
    end
end
if isstruct(options.call_log)
    msg.call_log = options.call_log;
end
pipe_send(msg);

%% iteratively send function evaluation results until solved
reply = struct();
while true
    reply = pipe_receive();
    
    if isfield(reply, 'solution') || isfield(reply, 'error_msg')
        break;
    end
    
    if iscell(reply)
        results = zeros(numel(reply), 1);
        parfor ii=1:numel(reply)
            results(ii) = f(reply{ii});
        end
        msg = struct('values', results);
    else
        msg = struct('value', f(reply));
    end
    
    pipe_send(msg);
end

if isfield(reply, 'error_msg')
    error(['Error: ', reply.error_msg]);
end

solution = reply.solution;
details = reply;

end