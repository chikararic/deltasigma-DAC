%if used for DAC: bitxor 
%this program is for Statistical Transition Rate
%bitxor(4, 8)
%A normal digital circuit has no inherent weight.
L1=length(out.MASH111OUT);
L2=length(out.MASH111OUT1);
L3=length(out.MASH111OUT2);
L4=length(out.MASH111OUT3);
%a = int16(1);
%b = int16(13);
%c = bitxor(a, b)
ToggleRate1= [0];
ToggleRate2= [0,0,0];
ToggleRate3= [0,0,0];
ToggleRate4= [0,0];
for k = 1:(L1-1)
a1 = int16(out.MASH111OUT(k));
b1 = int16(out.MASH111OUT(k+1));

a2 = int16(out.MASH111OUT1(k,1:3));
b2 = int16(out.MASH111OUT1(k+1,1:3));

a3 = int16(out.MASH111OUT2(k,1:3));
b3 = int16(out.MASH111OUT2(k+1,1:3));

a4 = int16(out.MASH111OUT3(k,1:2));
b4 = int16(out.MASH111OUT3(k+1,1:2));
%MASH111OUT only 1
ToggleRate1=ToggleRate1+ sum(bitget(a1, 8:-1:1) ~= bitget(b1, 8:-1:1));
%MASH111OUT1, 3 dimesions
for i=1:3
    ToggleRate2(i)=ToggleRate2(i)+ sum(bitget(a2(i), 8:-1:1) ~= bitget(b2(i), 8:-1:1));
end
%MASH111OUT2, 3 dimensions
for i=1:3
    ToggleRate3(i)=ToggleRate3(i)+ sum(bitget(a3(i), 8:-1:1) ~= bitget(b3(i), 8:-1:1));
end
%MASH111OUT3, 2  dimensions
for i=1:2
    ToggleRate4(i)=ToggleRate4(i)+ sum(bitget(a4(i), 8:-1:1) ~= bitget(b4(i), 8:-1:1));
end
end
%Merge List
ToggleRateTotal=[ToggleRate1,ToggleRate2,ToggleRate3,ToggleRate4];
