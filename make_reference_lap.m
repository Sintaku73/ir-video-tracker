%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

pathVideo = "input/sample_video_ref.mp4";
v = VideoReader(pathVideo);

pathLog = "input/sample_telemetry_ref.mat";
lapSelected = 3;
iFrameStart = 185;
hTrimMap = 300;
wTrimMap = hTrimMap;
hCar = 60;
wCar = 30;
hTrimMove = 720;
wTrimMove = 1790;

%%
[carPos,yawValid,listFrame,m2px,imgMap,RA,lat0,lon0,h0] = irvtUtils.getTrackMapLog( ...
    v,iFrameStart,pathLog,lapSelected,hTrimMap,wTrimMap,hCar,wCar,hTrimMove,wTrimMove);
carPosInv = carPos.*[1 -1];

%%
figure
imshow(imgMap,RA)
title("m")
hold on
plot(carPosInv(:,1),carPosInv(:,2))

%%
save("output/reference_lap.mat","pathVideo","listFrame","carPos","yawValid","m2px","imgMap","RA","lat0","lon0","h0");

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
