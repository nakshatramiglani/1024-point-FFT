scriptFolder = fileparts(mfilename('fullpath'));
cd(scriptFolder);
outFile = "data/ref.json";

N = 1024;

data = readmatrix("data/input.txt");
X = data(:, 1) + 1i * data(:, 2);
tic;
X_fft = fft(X, N);
elapsedTime = toc;
disp(['Exeuction time: ', num2str(elapsedTime), ' seconds']);
X_fft_real = real(X_fft);
X_fft_imag = imag(X_fft);

data = fopen(outFile, "w");

s = struct();

for i = 1 : length(X_fft)
    op = [X_fft_real(i), X_fft_imag(i)];
    s.(sprintf('in_%d', i)) = op;
end

jsonString = jsonencode(s, PrettyPrint=true);
fprintf(data, "%s", jsonString);