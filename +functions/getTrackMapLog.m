function [carPos,yawValid,listFrame,m2px,imgMap,RA,lat0,lon0,h0] = getTrackMapLog( ...
    v,iFrameStart,pathLog,lapSelected,hTrimMap,wTrimMap,hCar,wCar,hTrimMove,wTrimMove)
arguments
    v (1,1) VideoReader
    iFrameStart (1,1) double
    pathLog (1,:) string
    lapSelected (1,1) double
    hTrimMap (1,1) double = 300
    wTrimMap (1,1) double = 300
    hCar (1,1) double = 60
    wCar (1,1) double = 30
    hTrimMove (1,1) double = 720
    wTrimMove (1,1) double = 1790
end
% Load the log file
load(pathLog,"Lap","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");
gpsLat = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLon = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

% Select the lap
idxValid = Lap.Value==lapSelected;
gpsLatValid = gpsLat(idxValid);
gpsLonValid = gpsLon(idxValid);
gpsAltValid = GPS_Altitude.Value(idxValid);
yawValid = (YawNorth.Value(idxValid)-pi/2).*(-1);

lat0 = gpsLatValid(1);
lon0 = gpsLonValid(1);
h0 = gpsAltValid(1);
[x,y,~] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,lat0,lon0,h0);
carPos = [x.' y.'];
carPosInv = carPos.*[1 -1];

nData = sum(idxValid);
listFrame = iFrameStart:iFrameStart+nData-1;

% Calculate resolution
carCoG = [wTrimMove/2+0.5 hTrimMove/2+0.5];
diffGps = vecnorm(diff(carPosInv,[],1),2,2);

frameStart = functions.trimImg(read(v,listFrame(1)),hTrimMove,wTrimMove);
frameStartNext =  functions.trimImg(read(v,listFrame(2)),hTrimMove,wTrimMove);
frameEnd = functions.trimImg(read(v,listFrame(end)),hTrimMove,wTrimMove);
frameEndPrev = functions.trimImg(read(v,listFrame(end-1)),hTrimMove,wTrimMove);

tformStart = functions.getImgMove(rgb2gray(frameStart),rgb2gray(frameStartNext));
tfotmEnd = functions.getImgMove(rgb2gray(frameEndPrev),rgb2gray(frameEnd));

diffFrameStart = norm(functions.getCarMove(tformStart,carCoG));
diffFrameEnd = norm(functions.getCarMove(tfotmEnd,carCoG));

m2px = mean([diffFrameStart/diffGps(1) diffFrameEnd/diffGps(end)]);

carPosPixel = round(carPosInv.*m2px);
posFlip = flip(carPosPixel,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrimMap wTrimMap]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;

% Create the track map
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:nData,"UpdateRate",2)
    iFrame = listFrame(i);
    frameCurrent = functions.trimImg(read(v,iFrame),hTrimMap,wTrimMap);
    frameCurrent = functions.deleteAroundCar(frameCurrent,hCar,wCar);
    frameCurrent = imrotate(frameCurrent,rad2deg(yawValid(i))-90,"crop");
    idxStart = posFlip(i,:)+shiftMap;
    idxEnd = idxStart+[hTrimMap wTrimMap]-1;
    imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
    boolHollow = all(frameCurrent==0,3);
    imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
end

% Convert the background from black to white
boolBg = all(imgMap==0,3);
boolBg = cat(3,boolBg,boolBg,boolBg);
imgMap(boolBg) = 255;

% Adjust brightness
imgMap = imlocalbrighten(imgMap,"AlphaBlend",true);

% Calculate the map limits
posMin = min(carPosInv,[],1);
posMax = max(carPosInv,[],1);

hTrimMeter = hTrimMap/m2px;
wTrimMeter = wTrimMap/m2px;

xWorldLimits = [posMin(1)-wTrimMeter/2 posMax(1)+wTrimMeter/2];
yWorldLimits = [posMin(2)-hTrimMeter/2 posMax(2)+hTrimMeter/2];
RA = imref2d(size(imgMap),xWorldLimits,yWorldLimits);
end
