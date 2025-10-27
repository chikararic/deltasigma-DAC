%这个版本是能用的本版本，配合那三个MASH结构，可以
% 基本参数 
Ts = 0.1;           % 采样周期
Fs = 1/Ts;          % 10 Hz
x  = double(out.MASH111OUT(:));        % ARRAY→列向量
x  = detrend(x,0);               % 去均值

% 方案A：更稳健（K≈5），RBW=Fs/M≈0.078 Hz
M = 128; 
% 方案B：更细分辨率（K≈2），RBW≈0.039 Hz
%M = 256;

win   = hann(M,'periodic');
nover = floor(M/2);
Nfft  = max(1024, 2^nextpow2(M));   % 零填充只为平滑，分辨率仍=Fs/M

% 不传 Fs → 频轴 w 为 rad/sample，对应单位 power/rad/sample
[Pxx,w] = pwelch(x, win, nover, Nfft, 'psd');
semilogx(w/pi, 10*log10(Pxx)); grid on
xlabel('Normalized Frequency (\times\pi rad/sample)');
ylabel('Power/Frequency (dB/rad/sample)');

% 能量一致性自检（应接近 var(x)）
var_est = trapz(w, Pxx)/(2*pi);
disp([var(x) var_est])
