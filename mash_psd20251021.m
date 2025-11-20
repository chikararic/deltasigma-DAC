%% PSD
% reference: https://zhuanlan.zhihu.com/p/50272016
clc
clear
ADD_WIN_FLAG = 1;
LOG_PLOT_FLAG = 1;
% name = "SP MASH 5bit input 17";
% figname = "results/sp_mash_5bit_17_psd.png";
% load("SP_MASH_5bit_output_17.mat");

%name = "MASH 9bit input 255";
%figname = "results/mash_9bit_255_psd.svg";
%load("MASH_9bit_input_255.mat");

%x = y.Data;
%x = double(x);
sig = out.MASH111OUT;                 % timeseries
x   = double(sig.Data(:));  

% FFT 求功率谱密度
L = length(x);
% N = L;

% % 比当前长度大的下一个最小的 2 的次幂值
% N = 2^nextpow2(L);
% x_new = zeros(1, N-L);
% x = [x, x_new];

%%
% 取2的幂次方
N = 2^(nextpow2(L)-1);
x = x(1:N);

% 加窗
if ADD_WIN_FLAG
    wn=hann(N);  %汉宁窗
    x=x.*wn;   % 原始信号时域加窗
end

xdft = fft(x, N);
psdx = xdft.*conj(xdft)/N; % 双边功率谱密度，conj 共轭复数

% 加窗系数修正
if ADD_WIN_FLAG
    zz = wn.*wn;
    zz1 = sum(zz);
    psdx = psdx*N/zz1;
end

spsdx = psdx(1:floor(N/2)+1)*2; % 单边功率谱密度
spsdx(1) = psdx(1);

spsdx_log = 10*log10(spsdx); % 取log
spsdx_log(spsdx_log == -inf) = -300; % 处理 log10(0) 的情况

% 单边带
freq = 0:(2*pi)/N:pi;
% 双边带
% freq = 0:(2*pi)/N:(2*pi-(2*pi)/N);

% NTF 3阶
NTF = 3*20*log10(2*sin(freq/2));

if LOG_PLOT_FLAG
    semilogx(freq/pi, spsdx_log, freq/pi, NTF, '--')
else
    plot(freq/pi, spsdx_log, freq/pi, NTF, '--')
end
grid on
legend(name, 'NTF','Location', 'northwest')
title('Periodogram Using FFT')
xlabel('Normalized Frequency (\times\pi rad/sample)') 
ylabel('Power/Frequency (dB/rad/sample)')
saveas(gcf,figname)

%%
% periodogram 求功率谱密度
% win: hann rectwin
[h, w] = periodogram(x,rectwin(length(x)),length(x));
plot(w/pi, h)
% periodogram(x,rectwin(length(x)),length(x));
semilogx(w/pi, 10*log10(h))
grid on
legend(name, 'NTF','Location', 'northwest')
title('Periodogram Using FFT')
xlabel('Normalized Frequency (\times\pi rad/sample)') 
ylabel('Power/Frequency (dB/rad/sample)')
% test
% fs = 1000;
% t = 0:1/fs:5-1/fs;
% x = cos(2*pi*100*t) + randn(size(t));
% x = cos(2*pi*100*t);

%%
% pwelch
% fs = 100000;

% NTF
a = 1;
b = [1,-3,3,-1];
[h_ntf,w_ntf] = freqz(b,a,5000);

N = length(x);
win = hanning(N);  %汉宁窗
% win = rectwin(N);
nfft = N;
noverlap = 50;
[pxx,w] = pwelch(x, win, noverlap, nfft);

% plot(w/pi,10*log10(pxx))
semilogx(w/pi,10*log10(pxx),w_ntf/pi,20*log10(abs(h_ntf)), '--')
xlabel('\omega / \pi')
grid on
legend(name, 'NTF','Location', 'northwest')
title('Periodogram Using FFT')
xlabel('Normalized Frequency (\times\pi rad/sample)') 
ylabel('Power/Frequency (dB/rad/sample)')