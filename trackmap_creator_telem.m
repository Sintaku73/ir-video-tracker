%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

load("input\superformulasf23 toyota_suzuka grandprix 2025-04-20 18-23-54_Stint_3.mat", ...
    "Lap","Lap_Distance","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");

%%
lapSelected = 3;
idxValid = Lap.Value==lapSelected;

gpsLat = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLon = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

gpsLatValid = gpsLat(idxValid);
gpsLonValid = gpsLon(idxValid);
gpsAltValid = GPS_Altitude.Value(idxValid);
yawValid = (YawNorth.Value(idxValid)-pi/2).*(-1);

[x,y,~] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,gpsLatValid(1),gpsLonValid(1),gpsAltValid(1));
carPos = [x.' y.'].*[1 -1];

%%
nData = sum(idxValid);
iFrameStart = 185;
listFrame = iFrameStart:iFrameStart+nData-1;

%%
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

hTrimMap = 300;
wTrimMap = hTrimMap;
hCut = 60;
wCut = 30;
hTrimMove = 720;
wTrimMove = 1790;

carCoG = [wTrimMove/2+0.5 hTrimMove/2+0.5];

%%
diffGps = vecnorm(diff(carPos,[],1),2,2);

frameStart = irvtUtils.trimImg(read(v,listFrame(1)),hTrimMove,wTrimMove);
frameStartNext =  irvtUtils.trimImg(read(v,listFrame(2)),hTrimMove,wTrimMove);
frameEnd = irvtUtils.trimImg(read(v,listFrame(end)),hTrimMove,wTrimMove);
frameEndPrev = irvtUtils.trimImg(read(v,listFrame(end-1)),hTrimMove,wTrimMove);

tformStart = irvtUtils.getImgMove(rgb2gray(frameStart),rgb2gray(frameStartNext));
tfotmEnd = irvtUtils.getImgMove(rgb2gray(frameEndPrev),rgb2gray(frameEnd));

diffFrameStart = norm(irvtUtils.getCarMove(tformStart,carCoG));
diffFrameEnd = norm(irvtUtils.getCarMove(tfotmEnd,carCoG));

%%
m2px = mean([diffFrameStart/diffGps(1) diffFrameEnd/diffGps(end)]);
carPosPixel = carPos.*m2px;

posInt = round(carPosPixel);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrimMap wTrimMap]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = carPosPixel+flip(shiftMap,2)+([wTrimMap hTrimMap]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:nData,"UpdateRate",2)
    iFrame = listFrame(i);
    frameCurrent = irvtUtils.trimImg(read(v,iFrame),hTrimMap,wTrimMap);
    frameCurrent = irvtUtils.deleteAroundCar(frameCurrent,hCut,wCut);
    frameCurrent = imrotate(frameCurrent,rad2deg(yawValid(i))-90,"crop");
    idxStart = posFlip(i,:)+shiftMap;
    idxEnd = idxStart+[hTrimMap wTrimMap]-1;
    imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
    boolHollow = (frameCurrent==0);
    imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
end

%%
posMin = min(carPos,[],1);
posMax = max(carPos,[],1);

hTrimMeter = hTrimMap/m2px;
wTrimMeter = wTrimMap/m2px;

xWorldLimits = [posMin(1)-hTrimMeter/2 posMax(1)+hTrimMeter/2];
yWorldLimits = [posMin(2)-wTrimMeter/2 posMax(2)+wTrimMeter/2];
RA = imref2d(size(imgMap),xWorldLimits,yWorldLimits);

figure
imshow(imgMap,RA)
title("m")
hold on
plot(carPos(:,1),carPos(:,2))
% print("temp/m","-dtiffn","-r600")

%%
save("input\reference_lap.mat","v","listFrame","carPos","yawValid","m2px","imgMap","RA");

%% car position visualization
% hShow = 300/m2px;
% ratioShow = size(imgMap,2)/size(imgMap,1);
% wShow = ratioShow*hShow;
%
% xCurrent = carPos(1,1);
% yCurrent = carPos(1,2);
%
% v = VideoWriter("temp/result_trackmap.mp4","MPEG-4");
% v.FrameRate = 60;
% open(v);
%
% f = figure("Visible","off");
% imshow(imgMap,RA)
% hold on
% plot(carPos(:,1),carPos(:,2))
% p = plot(carPos(1,1),carPos(1,2),'o','MarkerFaceColor','red');
% xlabel("x [m]")
% ylabel("y [m]")
% xlim([xCurrent-wShow/2 xCurrent+wShow/2])
% ylim([yCurrent-hShow/2 yCurrent+hShow/2])
% hold off
% % f.Visible = "on";
% writeVideo(v,getframe(f));
% for i = progress(2:nData,"UpdateRate",2)
%     xCurrent = carPos(i,1);
%     yCurrent = carPos(i,2);
%     p.XData = xCurrent;
%     p.YData = yCurrent;
%     xlim([xCurrent-wShow/2 xCurrent+wShow/2])
%     ylim([yCurrent-hShow/2 yCurrent+hShow/2])
%     drawnow
%     writeVideo(v,getframe(f));
% end
% close(v);
