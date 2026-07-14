clc;
clear;
close all;

%% Parameters
M = 32;                 % Number of banks
N = 32;                 % FFT length
WIDTH = M*N;

%% Input Ramp
x = 0:WIDTH-1;

%% Arrange exactly as the hardware writes
% Row-wise fill of a 32x32 matrix
X = reshape(x, M, N).';

% X(row,column)
% Rows = addresses
% Columns = banks

%% Perform a 32-point FFT on every bank
zak = zeros(N,M);

for bank = 1:M
    zak(:,bank) = fft(X(:,bank),N);
end

%% Hardware output order
% Scheduler outputs:
% Bank0 FFT
% Bank1 FFT
% ...
% Bank31 FFT

golden = [];

for bank = 1:M
    golden = [golden; zak(:,bank)];
end

%% Save reference
fid = fopen('golden_reference.txt','w');

for k = 1:length(golden)
    fprintf(fid,'%.10f %.10f\n',real(golden(k)),imag(golden(k)));
end

fclose(fid);

disp('Golden reference written to golden_reference.txt');