%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

dataRef = load("input/reference_lap.mat","RA","carPos","imgMap","listFrame","m2px","yawValid");
dataRef.v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

%%
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-25-11.mp4");
iFrameStart = 156;
iFrameEnd = 7070;
intervalFrame = 1;

[carPos,~,listFrame] = irvtUtils.getCarPos(v,iFrameStart,iFrameEnd);

%%
% save("temp\carpos_sfl.mat","carPos","listFrame");
% load("temp/carpos_sfl.mat");

%%
lapDistRef = cumsum([0; vecnorm(diff(dataRef.carPos),2,2)]);
lapDistPctRef = lapDistRef./max(lapDistRef).*100;
lapDist = cumsum([0; vecnorm(diff(carPos),2,2)]);
lapDistPct = lapDist./max(lapDist).*100;

%%
yawNorthRef = rad2deg(dataRef.yawValid)-90;
hTrim = 720;
wTrim = 960;
carCoG = [wTrim/2+0.5 hTrim/2+0.5];
carPos = zeros(length(listFrame),2);
carYaw = zeros(length(listFrame),1);
listIdxNearest = zeros(length(listFrame),1);
%%
for i = progress(1:length(listFrame),"UpdateRate",2)
% for i = progress(901:1000,"UpdateRate",2)
    [~,idxRefNearest] = min(abs(lapDistPctRef-lapDistPct(i)));
    iFrameRef = dataRef.listFrame(idxRefNearest);
    iFrameCurrent = listFrame(i);
    listIdxNearest(i) = idxRefNearest;

    frameRef = read(dataRef.v,iFrameRef);
    frameCurrent = read(v,iFrameCurrent);
    trimmedRef = irvtUtils.trimImg(frameRef,hTrim,wTrim);
    trimmedCurrent = irvtUtils.trimImg(frameCurrent,hTrim,wTrim);
    grayRef = rgb2gray(trimmedRef);
    grayCurrent = rgb2gray(trimmedCurrent);

    tform = irvtUtils.getImgMove(grayRef,grayCurrent);
    diffTranslation = irvtUtils.getCarMove(tform,carCoG)/dataRef.m2px.*[1 -1];
    carPos(i,:) = dataRef.carPos(idxRefNearest,:)+...
        (irvtUtils.rot(yawNorthRef(idxRefNearest))*diffTranslation.').';
    carYaw(i) = dataRef.yawValid(idxRefNearest)+deg2rad(-tform.RotationAngle);
end

%%
% save("temp\carpos_sfl_comp.mat","carPos","carYaw","listIdxNearest")
% load("temp\carpos_sfl_comp.mat")

%%
figure("WindowStyle","docked")
imshow(dataRef.imgMap,dataRef.RA,"InitialMagnification","fit")
axis ij
hold on
plot(dataRef.carPos(:,1),-dataRef.carPos(:,2),".-")
scatter(dataRef.carPos(:,1),-dataRef.carPos(:,2),10,dataRef.listFrame,"filled")
plot(carPos(:,1),-carPos(:,2),".-")
scatter(carPos(:,1),-carPos(:,2),10,listFrame,"filled")
for i = progress(1:length(carPos))
    tempFrom = [carPos(i,1) dataRef.carPos(listIdxNearest(i),1)];
    tempTo = [-carPos(i,2) -dataRef.carPos(listIdxNearest(i),2)];
    plot(tempFrom,tempTo,"Color","r")
end
colorbar

%% evaluate the result with comparison to GPS data
load("input\superformulalights324_suzuka grandprix 2025-04-20 18-37-17_Stint_1.mat", ...
    "Lap","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");

gpsLat = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLon = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

%%
figure("WindowStyle","docked")
geoplot(gpsLat,gpsLon)
geobasemap none

%%
lapSelected = 2;
idxValid = Lap.Value==lapSelected;
gpsLatValid = gpsLat(idxValid);
gpsLonValid = gpsLon(idxValid);
gpsAltValid = GPS_Altitude.Value(idxValid);
yawValidLog = (YawNorth.Value(idxValid)-pi/2).*(-1);

[x,y,~] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,gpsLatValid(1),gpsLonValid(1),gpsAltValid(1));
carPosLog = [x.' y.'];

%% visualize the result
vectorYawRef = [cos(dataRef.yawValid.') sin(dataRef.yawValid.')];
vectorYawRef = vectorYawRef./vecnorm(vectorYawRef,2,2);
vectorYaw = [cos(carYaw) sin(carYaw)];
vectorYaw = vectorYaw./vecnorm(vectorYaw,2,2);
vectorYawLog = [cos(yawValidLog.') sin(yawValidLog.')];
vectorYawLog = vectorYawLog./vecnorm(vectorYawLog,2,2);

figure("WindowStyle","docked")
plot(dataRef.carPos(:,1),dataRef.carPos(:,2),"DisplayName","reference")
axis equal
grid on
hold on
plot(carPos(:,1),carPos(:,2),"DisplayName","calculated");
plot(carPosLog(:,1),carPosLog(:,2),"DisplayName","log")
quiver(dataRef.carPos(:,1),dataRef.carPos(:,2),vectorYawRef(:,1),vectorYawRef(:,2),"off","DisplayName","v(reference)")
quiver(carPos(:,1),carPos(:,2),vectorYaw(:,1),vectorYaw(:,2),"off","DisplayName","v(calculated)")
quiver(carPosLog(:,1),carPosLog(:,2),vectorYawLog(:,1),vectorYawLog(:,2),"off","DisplayName","v(log)")
% scatter(dataRef.carPos(:,1),dataRef.carPos(:,2),30,dataRef.listFrame,"filled")
% scatter(carPos(:,1),carPos(:,2),30,listIdxNearest,"filled")
% clim([min(listIdxNearest(listIdxNearest>0)) max(listIdxNearest(listIdxNearest>0))])
% colorbar
legend

%%
yawValidLogResampled = interp1(1:length(yawValidLog),yawValidLog,1:length(carYaw));
thDiffOvershoot = 2*pi*0.9;
diffCalcLog = carYaw-yawValidLogResampled.';
diffCalcLog = diffCalcLog(abs(diffCalcLog)<thDiffOvershoot);


figure("WindowStyle","docked")
area(rad2deg(diffCalcLog))

figure("WindowStyle","docked")
plot(rad2deg(carYaw),"DisplayName","calculated")
hold on
plot(rad2deg(yawValidLogResampled),"DisplayName","log")
legend

%%
disp(mean(abs(rad2deg(diffCalcLog))))
