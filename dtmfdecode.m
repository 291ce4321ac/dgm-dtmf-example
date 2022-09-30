function varargout = dtmfdecode(signal,varargin)
%   KEYS = DTMFDECODE(SIGNAL,{SAMPLEFREQ})
%   Decode a sequence of DTMF tones in an audio signal.  
%   If called without any output arguments, a figure window 
%   will be opened, displaying the tone spectra and frequency
%   bins associated with the DTMF source tones.  
%
%   Each tone in the sequence should be separated by a period of
%   silence.  For normalized signals, the minimum tone duration 
%   and spacing are both well below 40ms. 
%  
%   This is a relatively simple implementation intended mainly
%   to help deal with questions asked by students.  This should
%   not require any special toolboxes.  I make no assurance of
%   the robustness of this implementation.
%   
%   SIGNAL is a vector describing a time-domain audio signal.
%   SAMPLEFREQ is the sampling frequency used by SIGNAL (Hz)
%       This is expected to be at least 3300. (default 8000)
%   
%   Output KEYS is a character vector
%
%  Example:
%   mysignal = dtmfencode('8675309');
%   themdigits = dtmfdecode(mysignal);
% 
%  See also: dtmfencode


fs = 8000;
if numel(varargin)>0
	fs = varargin{1};
end

if nargout==0
	runplots=true;
else 
	runplots=false;
end

bw = 50; % frequency bin width (max ~60)
sourcetones = bsxfun(@plus,[697 770 852 941 1209 1336 1477 1633]',[-bw/2 bw/2]);
symbols = {'1','2','3','A';'4','5','6','B';'7','8','9','C';'*','0','#','D'};

% logical map describing the duration of tones in the sequence
% this is a greedy approach, including some silence at the ends of each tone
% this degrades the clarity, but not enough to be a problem in good cases
if ifversion('>=','R2016a')
	tonemask = movmax(abs(signal),fs*0.02)>(0.05*max(abs(signal)));
else
	sp = ceil(fs*0.02);
	pad = zeros(sp,1);
	padded = [pad; abs(signal(:)); pad];
	tonemask = zeros(size(padded));
	for r=1:numel(signal)
		samp = padded((r-1)+(1:sp));
		tonemask(r) = max(samp(:));
	end
	tonemask = tonemask>(0.05*max(padded));
end
tonemask([1 end]) = 0;

% find approximate start and end of each tone
tmd = diff(tonemask);
starts = find(tmd==1);
stops = find(tmd==-1);

numkeys = numel(starts);
if runplots
	[f1 f2] = rectopt(numkeys);
	h=findall(0,'tag','DTMF_TONES');
	if ~isempty(h)
		% raise figure if already open
		figure(h);
		clf
	else
		% otherwise set up a new figure
		h = figure();
		set(h,'tag','DTMF_TONES','name','Spectra of identified tone blocks','numbertitle','off');
	end
end

keys = [];
for k=1:numkeys
	% fetch this chunk of the signal vector
	thissignal = signal(starts(k):stops(k));
	
	% run fft on this chunk
	fsignal=abs(fft(thissignal));   
	
	% find sum of spectrum with each frequency bin
	d = numel(fsignal)/fs;
	tonepower = zeros(8,1);
	for f=1:size(sourcetones,1)
		tonepower(f) = sum(fsignal(round(d*(sourcetones(f,1):sourcetones(f,2)))));
	end

	% find key matrix row and column indices from most powerful frequencies
	[~,row] = max(tonepower(1:4));
	[~,col] = max(tonepower(5:8));

	% look up the symbol and add it to the list
	thissymbol = symbols{row,col};
	keys = [keys thissymbol];
	
	% plot the signal and frequency bins if requested
	if runplots
		subplot_tight(f1,f2,k);
		
		x=500:2000;
		h = plot(x,fsignal(round(x*d)),'k'); hold on;
		
		yl = get(gca,'ylim');
		for f=1:size(sourcetones,1)
			xx = sourcetones(f,[1 2 2 1 1]);
			yy = yl([1 1 2 2 1]);
			patch(xx,yy,'m','facealpha',0.1,'edgealpha',0)
			
			ylrel = [yl(1) yl(2)*tonepower(f)/max(tonepower)];
			yy = ylrel([1 1 2 2 1]);
			patch(xx,yy,'m','facealpha',0.2,'edgealpha',0)
		end
		
		uistack(h,'top')
		text(1800,yl(2)*0.75,thissymbol,'fontsize',24);
		ylim(yl)
	end
end

if ~runplots
	varargout{1} = keys;
end

end

% try to find good subplot layout for n subplots
% this favors square layouts when possible
% if not square, wide layouts are favored
% since most screens are wider than tall
function [f1 f2] = rectopt(n)
	f0 = sqrt(n);
	f1 = n./(ceil(f0)+[0 1 2 3]);
	f1 = f1(mod(f1,1)==0);

	if ~isempty(f1)
		f1 = f1(1);
		f2 = n/f1;
	else
		f1 = floor(f0);
		f2 = ceil(n/f1);
	end
end

