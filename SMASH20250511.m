% 定义基本参数
OSR = 128;           % 过采样率
order = 4;           % 调制器阶数（根据需要调整）
nlev = 2;            % 量化器电平数 (2表示1比特量化器)
opt = 0;             % 优化标志
H_inf = 1.5;         % 无穷范数约束
f0 = 0;              % 中心频率 (0表示低通滤波器)

ntf = synthesizeNTF(order, OSR, opt, H_inf, f0);