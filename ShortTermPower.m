%% function [mrPower] = ShortTermPower(mcSignal,iWinLength)
% Calculates the short-term average power of a given signal mcSignal.
%% Input parameters:
%   mcSignal (required input): Signal to be processed. If a matrix, each
%       column is considered a separate signal.
%   iWinLength (optional input): Window length (specified in number of
%       samples) for the short-term average calculations. Default: length
%       of signals (i.e. power is averaged for the whole signal).
%% Output parameters:
%   mrPower: Matrix having the same size as mcSignal and containing the 
%       average power around each sample.
%% RFM 23/10/2014

function mrPower = ShortTermPower(mcSignal,iWinLength)

%% CHECK INPUTS
% Signal size
    [iNumRows,iNumColumns] = size(mcSignal);

% Error detection in signal size
    if ((iNumRows<2)&&(iNumColumns<2))
        error('Function ShortTermPower: Input cannot be a scalar');
    elseif (iNumRows<2)
        mcSignal = mcSignal';
        [iNumRows,iNumColumns] = size(mcSignal);
    end

% Error detection in window length
    if ((nargin<2)||(iWinLength>iNumRows)),
        iWinLength = iNumRows;
    end
    
%% COMPUTATION
% Instantaneous power    
    mrPower = abs(mcSignal).^2;

% Short-term averaging
    iFirstRow = floor((iWinLength + 1)/2);
    
    for k=1:iNumColumns,
        vrShortTermPower = conv(ones(iWinLength,1)./iWinLength,mrPower(:,k));
        mrPower(:,k) = vrShortTermPower(iFirstRow:iFirstRow+iNumRows-1);
    end

end