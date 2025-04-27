clear
close all

%%
addpath(fullfile(pwd,"utils"));

%%
load("input\superformulasf23 toyota_suzuka grandprix 2025-04-20 18-23-54_Stint_3.mat", ...
    "Lap","Lap_Distance","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");

%%
samplingRate = 1/mean(diff(Lap.Time));
lapN = Lap.Value./max(Lap.Value);
distN = Lap_Distance.Value./max(Lap_Distance.Value);

% figure
% area(distN,"FaceAlpha",0.5)
% hold on
% area(lapN,"FaceAlpha",0.5)

lapSelected = 3;
idxValid = Lap.Value==lapSelected;

%%
gpsLat = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLon = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

gpsLatValid = gpsLat(idxValid);
gpsLonValid = gpsLon(idxValid);
gpsAltValid = GPS_Altitude.Value(idxValid);
yawValid = (YawNorth.Value(idxValid)-pi/2).*(-1);

% geoplot(gpsLatValid,gpsLonValid)
% geobasemap satellite

%%
nData = sum(idxValid);
iFrameStart = 185;
listFrame = iFrameStart:iFrameStart+nData-1;

%%
vectorYaw = [cos(yawValid); sin(yawValid)];
vectorYaw = vectorYaw./vecnorm(vectorYaw,2,1);

diffYaw = diff(yawValid);
diffYaw = [diffYaw diffYaw(end)];
idxJump = abs(rad2deg(diffYaw))>355;

figure("WindowStyle","docked")
[x,y,z] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,gpsLatValid(1),gpsLonValid(1),gpsAltValid(1));
plot(x,y);
axis equal
grid on
hold on
quiver(x,y,vectorYaw(1,:),vectorYaw(2,:),"off")
scatter(x,y,5,rad2deg(yawValid))
scatter(x(idxJump),y(idxJump),"red")

%%


%%
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

hImg = v.Height;
wImg = v.Width;
hTrim = 720;
wTrim = 1790;

carCoG = [wTrim/2+0.5 hTrim/2+0.5];

hIdxStart = (hImg - hTrim)/2 + 1;
wIdxStart = (wImg - wTrim)/2 + 1;

%%
iFrameEnd = 6230;
intervalFrame = 1;
nFrame = length(listFrame);
frameCurrent = read(v, iFrameStart);
trimmedCurrent = irvtUtils.trimImg(frameCurrent,hTrim,wTrim);
grayCurrent = rgb2gray(trimmedCurrent);
diffTranslation = zeros(nFrame, 2);
diffAngle = zeros(nFrame,1);

%%
for i=progress(2:nFrame, "UpdateRate", 2)
    frameNext = read(v, listFrame(i));
    trimmedNext = irvtUtils.trimImg(frameNext,hTrim,wTrim);
    grayNext = rgb2gray(trimmedNext);

    tform = irvtUtils.getImgMove(grayCurrent,grayNext);
    diffTranslation(i,:) = tform.Translation;
    diffAngle(i) = tform.RotationAngle;

    grayCurrent = grayNext;
end

%%
rot = @(theta) [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

cumAngle = cumsum(diffAngle);
diffRotated=zeros(size(diffTranslation));
for i=2:nFrame
    diffRotated(i,:)=transpose(rot(cumAngle(i-1))*diffTranslation(i,:).' ...
        -rot(cumAngle(i-1))*carCoG.'+rot(cumAngle(i))*carCoG.');
end

%%
carPos = cumsum(diffRotated);

%% Fix the defference between start and end
frameStart = read(v,listFrame(1));
frameEnd = read(v,listFrame(end));

trimmedStart = irvtUtils.trimImg(frameStart,hTrim,wTrim);
trimmedEnd = irvtUtils.trimImg(frameEnd,hTrim,wTrim);

grayStart = rgb2gray(trimmedStart);
grayEnd = rgb2gray(trimmedEnd);

tform = irvtUtils.getImgMove(grayStart,grayEnd);
diffS2E = irvtUtils.getCarMove(tform,carCoG);

%%
shiftPos = carPos(1,:)-carPos(end,:)+diffS2E;
carPos = (carPos+linspace(0,1,nFrame).'.*shiftPos).*[1 -1];

shiftAngle = tform.RotationAngle-cumAngle(end);
cumAngle = cumAngle+linspace(0,1,nFrame).'.*shiftAngle;

%%
str = num2cell(listFrame);
figure
plot(carPos(:,1),carPos(:,2),".-")
axis equal
grid on
% hold on
% text(carPos(:,1),carPos(:,2),str)

%%
% save(sprintf("input/line_%dHz.mat",v.FrameRate/intervalFrame),"carPos","cumAngle","listFrame");
