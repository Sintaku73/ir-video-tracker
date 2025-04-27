clear
close all

%%
addpath(fullfile(pwd,"utils"));

v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

hTrim = 720;
wTrim = 1790;
iFrameStart = 185;
iFrameEnd = 6230;
intervalFrame = 1;

%%
[carPos,carYaw,listFrame] = irvtUtils.getCarPos(v,hTrim,wTrim,iFrameStart,iFrameEnd,intervalFrame);

%%
str = num2cell(listFrame);
figure
plot(carPos(:,1),carPos(:,2),".-")
axis equal
grid on
% hold on
% text(carPos(:,1),carPos(:,2),str)

%%
% save(sprintf("input/line_%dHz.mat",v.FrameRate/intervalFrame),"carPos","carYaw","listFrame");
