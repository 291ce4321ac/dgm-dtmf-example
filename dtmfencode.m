function signal = dtmfencode(keys,varargin)
%   SIGNAL = DTMFENCODE(KEYS,{OPTIONS})
%   Encode a sequence of DTMF tones in an audio signal.  
%
%   Each tone in the sequence is separated by a period of silence.
%   The minimum typical tone and space duration used by equipment
%   is 40 ms.
%   
%   KEYS is a character vector made from the keys on a 4x4 keypad:
%     123A
%     456B
%     789C
%     *0#D
%   OPTIONS are key value pairs:
%    'toneduration' specifies the length of the tones (default 0.2s)
%    'spaceduration' specifies the intertone silence (default 0.1s)
%    'fs' specifies sampling frequency (default 8000 Hz)
%   
%   Output SIGNAL is a vector describing a time-domain audio signal
%
%  Example:
%   mysignal = dtmfencode('8675309');
%   themdigits = dtmfdecode(mysignal);
% 
%  See also: dtmfdecode


toneduration = 0.2;
spaceduration = 0.1;
fs = 8000;

if numel(varargin)>0
	k=1;
	while k<numel(varargin)
		thisarg = varargin{k};
		switch lower(thisarg)
			case {'toneduration','td'}
				toneduration = varargin{k+1};
				k=k+2;
			case {'spaceduration','sd'}
				spaceduration = varargin{k+1};
				k=k+2;
			case 'fs'
				fs = varargin{k+1};
				k=k+2;
			otherwise
				error('DTMFENCODE: unknown argument %s',thisarg)
		end
	end
end

sourcetones = [697 770 852 941 1209 1336 1477 1633];
symbols = {'1','2','3','A';'4','5','6','B';'7','8','9','C';'*','0','#','D'};
t = linspace(0,toneduration,toneduration*fs);

signal = [];
for k = 1:numel(keys)
	% associate key with high and low frequency pair
	[row col] = find(strcmpi(keys(k),symbols));
	if isempty(row)
		error('DTMFENCODE: invalid key %s',keys(k))
	end
	FL = sourcetones(row);
	FH = sourcetones(col+4);
	
	% append space where necessary
	if k~=1
		signal = [signal zeros(1,spaceduration*fs)];
	end
	
	% append tone segment
	signal = [signal 0.5*(sin(2*pi*FL*t) + sin(2*pi*FH*t))];
end








     