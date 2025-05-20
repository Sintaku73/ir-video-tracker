%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

dataRef = load("input/reference_lap.mat");
vRef = VideoReader(dataRef.pathVideo);

%%
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-25-11.mp4");
iFrameStart = 156;
iFrameEnd = 7070;
intervalFrame = 1;

% [carPos,~,listFrame] = irvtUtils.getCarPos(v,iFrameStart,iFrameEnd);

%%
% save("temp/carpos_sfl.mat","carPos","listFrame");
load("temp/carpos_sfl.mat");

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
    [~,idxRefNearest] = min(abs(lapDistPctRef-lapDistPct(i)));
    iFrameRef = dataRef.listFrame(idxRefNearest);
    iFrameCurrent = listFrame(i);
    listIdxNearest(i) = idxRefNearest;

    frameRef = read(vRef,iFrameRef);
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
% save("temp/carpos_sfl_comp.mat","carPos","carYaw","listIdxNearest")
load("temp/carpos_sfl_comp.mat")

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
load("input/superformulalights324_suzuka grandprix 2025-04-20 18-37-17_Stint_1.mat", ...
    "Lap","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth","Ground_Speed");

gpsLatLog = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLonLog = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

%%
figure("WindowStyle","docked")
geoplot(gpsLatLog,gpsLonLog)
geobasemap none

%%
lapSelected = 2;
idxValid = Lap.Value==lapSelected;
gpsLatValid = gpsLatLog(idxValid);
gpsLonValid = gpsLonLog(idxValid);
gpsAltValid = GPS_Altitude.Value(idxValid);
yawValidLog = (YawNorth.Value(idxValid)-pi/2).*(-1);
groundSpeedValid = Ground_Speed.Value(idxValid);
timeValid = Ground_Speed.Time(idxValid);
timeValid = timeValid-timeValid(1);

[x,y,~] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,dataRef.lat0,dataRef.lon0,dataRef.h0);
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

%% convert to GPS coordinates
[gpsLat,gpsLon,~] = matmap3d.enu2geodetic(carPos(:,1),carPos(:,2),zeros(length(carPos),1), ...
    dataRef.lat0,dataRef.lon0,dataRef.h0);

figure("WindowStyle","docked")
geoplot(gpsLatValid,gpsLonValid,"DisplayName","log")
hold on
geoplot(gpsLat,gpsLon,"DisplayName","calculated")
legend

%% convert dgrees to DMS
function [dms] = deg2dms(deg)
dms = zeros(length(deg),3);
dms(:,1) = floor(deg);
dms(:,2) = floor((deg-dms(:,1))*60);
dms(:,3) = (deg-dms(:,1)-dms(:,2)/60)*3600;
end

function cdiff = centerdiff(data,dt)
cdiff_ = (data(3:end)-data(1:end-2))/2/dt;
cdiff = [cdiff_(1); cdiff_; cdiff_(end)];
end

%% export to table
gpsLatDms = deg2dms(gpsLat);
gpsLonDms = deg2dms(gpsLon);

posNorm = [0; vecnorm(diff(carPos),2,2)];
lapDist = cumsum(posNorm);

%%
dTime = 1/v.FrameRate;

% Smooth input data
time = transpose(0:dTime:(length(carPos)-1)/v.FrameRate);
[lapDistSmoothed,winSize] = smoothdata(lapDist,"rloess",1,"SamplePoints",time);
% splDist = py.scipy.interpolate.UnivariateSpline(time,lapDist,s=1e2);
% splSpeed = splDist.derivative(int16(1));

g = 9.81;
gLon = 4*del2(lapDist,dTime)./g;

speed = centerdiff(lapDistSmoothed,dTime);
% speedSpl = double(splSpeed(time));

figure("WindowStyle","docked")
plot(time,gLon)
hold on
plot(time(1:end-2),diff(lapDist,2)./dTime^2./g)

%%
speedNoSmooth = centerdiff(lapDist,dTime);

% Display results
figure("WindowStyle","docked")
tiledlayout(1,2)
ax1 = nexttile;
plot(time,lapDist,"DisplayName","Input data")
hold on
plot(time,lapDistSmoothed,"DisplayName","Smoothed data")
% plot(time,splDist(time),"DisplayName","Smoothed spline")
grid on
legend

% figure("WindowStyle","docked")
ax2 = nexttile;
plot(time,speedNoSmooth*3.6, ...
    "SeriesIndex",6,"DisplayName","Without smoothing")
hold on
plot(time,speed*3.6,"SeriesIndex",1,"LineWidth",1.5, ...
    "DisplayName","Smoothed data")
% plot(time,speedSpl*3.6,"SeriesIndex",3,"LineWidth",1.5, ...
%     "DisplayName","Smoothed spline")
plot(timeValid,groundSpeedValid,"SeriesIndex",2,"LineWidth",1.5, ...
    "DisplayName","Logged data")
grid on
hold off
title("Moving window size: " + string(winSize));
legend
xlabel("Time (s)")
linkaxes([ax1 ax2],"x")

%%
tableExport = table;
tableExport.("Time (s)") = time;
tableExport.("Ground Speed (km/h)") = speed*3.6;
tableExport.("Latitude Degrees ()") = gpsLatDms(:,1);
tableExport.("Latitude Minutes ()") = gpsLatDms(:,2);
tableExport.("Latitude Minute fraction ()") = gpsLatDms(:,3);
tableExport.("Longitude Degrees ()") = gpsLonDms(:,1);
tableExport.("Longitude Minutes ()") = gpsLonDms(:,2);
tableExport.("Longitude Minute - fraction ()") = gpsLonDms(:,3);
tableExport.("YawNorth (rad)") = carYaw.*(-1)+pi/2;
tableExport.("AP Info:") = zeros(length(carPos),1);

% writetable(tableExport,"temp/suzuka_sfl.csv")
