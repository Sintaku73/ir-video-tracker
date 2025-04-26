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
carPos = [x.' y.'];

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

frameStart = trimImg(read(v,listFrame(1)),hTrimMap,wTrimMap);
frameStartNext =  trimImg(read(v,listFrame(2)),hTrimMap,wTrimMap);
frameEnd = trimImg(read(v,listFrame(end)),hTrimMap,wTrimMap);
frameEndPrev = trimImg(read(v,listFrame(end-1)),hTrimMap,wTrimMap);

tformStart = getImgMove(rgb2gray(frameStart),rgb2gray(frameStartNext));
tfotmEnd = getImgMove(rgb2gray(frameEndPrev),rgb2gray(frameEnd));

diffFrameStart = norm(getCarMove(tformStart,carCoG));
diffFrameEnd = norm(getCarMove(tfotmEnd,carCoG));

%%
m2px = mean([diffFrameStart/diffGps(1) diffFrameEnd/diffGps(end)]);
carPosPixel = carPos.*m2px.*[1 -1];

posInt = round(carPosPixel);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrimMap wTrimMap]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = carPosPixel+flip(shiftMap,2)+([wTrimMap hTrimMap]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:nData,"UpdateRate",2)
    iFrame = listFrame(i);
    frameCurrent = trimImg(read(v,iFrame),hTrimMap,wTrimMap);
    frameCurrent = deleteAroundCar(frameCurrent,hCut,wCut);
    frameCurrent = imrotate(frameCurrent,rad2deg(yawValid(i))-90,"crop");
    idxStart = posFlip(i,:)+shiftMap;
    idxEnd = idxStart+[hTrimMap wTrimMap]-1;
    imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
    boolHollow = (frameCurrent==0);
    imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
end

%%
% imwrite(imgMap,"temp\trackmap_suzuka.png")

f = figure;
imshow(imgMap)
hold on
% ylim([0.5 sizeMap(2)*3/4+0.5])
plot(posShifted(:,1),posShifted(:,2))
axis on
% f.Position(2:4)=[360 800 600];

%%
function imgHollow = deleteAroundCar(imgOrig,hCut,wCut)
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg - hCut)/2 + 1;
wIdxStart = (wImg - wCut)/2 + 1;
imgOrig(hIdxStart:hIdxStart+hCut-1, wIdxStart:wIdxStart+wCut-1, :) = 0;
imgHollow = imgOrig;
end
