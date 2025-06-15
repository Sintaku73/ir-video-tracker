%%
clear
close all

%%
v = VideoReader("input/sample_video_ref.mp4");

hTrim = 720;
wTrim = 1790;
iFrameStart = 185;
iFrameEnd = 6230;
intervalFrame = 1;

%%
[carPos,carYaw,listFrame] = functions.getCarPos(v,iFrameStart,iFrameEnd,hTrim,wTrim,intervalFrame);

%%
str = num2cell(listFrame);
vectorYaw = [cosd(carYaw+90) sind(carYaw+90)];
vectorYaw = vectorYaw./vecnorm(vectorYaw,2,2);

figure
plot(carPos(:,1),carPos(:,2),".-")
axis equal
grid on
hold on
% text(carPos(:,1),carPos(:,2),str)
quiver(carPos(:,1),carPos(:,2),vectorYaw(:,1),vectorYaw(:,2),0.1)
title('Car Position and Yaw Direction')

%%
% save(sprintf("input/line_%dHz.mat",v.FrameRate/intervalFrame),"carPos","carYaw","listFrame");
