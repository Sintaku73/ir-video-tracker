%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

pathLog = "input\superformulasf23 toyota_suzuka grandprix 2025-04-20 18-23-54_Stint_3.mat";
lapSelected = 3;
iFrameStart = 185;
hTrimMap = 300;
wTrimMap = hTrimMap;
hCar = 60;
wCar = 30;
hTrimMove = 720;
wTrimMove = 1790;

%%
[carPos,yawValid,listFrame,m2px,imgMap,RA] = irvtUtils.getTrackMapLog( ...
    v,iFrameStart,pathLog,lapSelected,hTrimMap,wTrimMap,hCar,wCar,hTrimMove,wTrimMove);
carPosInv = carPos.*[1 -1];

%%
figure
imshow(imgMap,RA)
title("m")
hold on
plot(carPosInv(:,1),carPosInv(:,2))
% print("temp/m","-dtiffn","-r600")

%%
save("input\reference_lap.mat","v","listFrame","carPos","yawValid","m2px","imgMap","RA");

%% car position visualization
hShow = 300/m2px;
ratioShow = size(imgMap,2)/size(imgMap,1);
wShow = ratioShow*hShow;

xCurrent = carPosInv(1,1);
yCurrent = carPosInv(1,2);

% v = VideoWriter("temp/result_trackmap.mp4","MPEG-4");
% v.FrameRate = 60;
% open(v);

f = figure("Visible","off");
imshow(imgMap,RA)
hold on
plot(carPosInv(:,1),carPosInv(:,2))
p = plot(carPosInv(1,1),carPosInv(1,2),'o','MarkerFaceColor','red');
xlabel("x [m]")
ylabel("y [m]")
xlim([xCurrent-wShow/2 xCurrent+wShow/2])
ylim([yCurrent-hShow/2 yCurrent+hShow/2])
hold off
f.Visible = "on";
% writeVideo(v,getframe(f));
for i = progress(2:length(listFrame),"UpdateRate",2)
    xCurrent = carPosInv(i,1);
    yCurrent = carPosInv(i,2);
    p.XData = xCurrent;
    p.YData = yCurrent;
    xlim([xCurrent-wShow/2 xCurrent+wShow/2])
    ylim([yCurrent-hShow/2 yCurrent+hShow/2])
    drawnow
    % writeVideo(v,getframe(f));
end
% close(v);
