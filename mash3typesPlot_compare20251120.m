%三组数据之间进行对比，一个对比图
A = [ ...
    12000  3000  7500  4500  3000 10500  6000 12000 13500;  % 第 1 行
    10519  2904  2443  2406  5806 12224 11199 13912  8663;  % 第 2 行
    10973  3000  4409  2685  3000  8719 11036 15575  9459];


n = 1:size(A,2);   % 横轴：1~9
x1 = n;               % 第1组
x2 = n + 0.3;          % 第2组
x3 = n + 0.5; 
figure;
hold on; grid on; box on;

stem(x1, A(1,:), 'Marker','none', 'LineWidth',1.5);
stem(x2, A(2,:), 'Marker','none', 'LineWidth',1.5);
stem(x3, A(3,:), 'Marker','none', 'LineWidth',1.5);



xlabel('Sample type');
ylabel('Switching num');
legend('MASH','hkmash','spmash');
title('Switching Activity Ratio Comparison');
hold off;