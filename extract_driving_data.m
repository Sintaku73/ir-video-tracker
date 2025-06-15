%%
close all
clear

%%
dataRef = load("output/sample_ref_lap.mat");
vRef = VideoReader(dataRef.pathVideo);

%%
v = VideoReader("input/sample_video_tgt.mp4");
iFrameStart = 159;
iFrameEnd = 7073;
intervalFrame = 1;

[carPos,~,listFrame] = functions.getCarPos(v,iFrameStart,iFrameEnd);

%%
% save("temp/carpos_sfl.mat","carPos","listFrame");
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
    [~,idxRefNearest] = min(abs(lapDistPctRef-lapDistPct(i)));
    iFrameRef = dataRef.listFrame(idxRefNearest);
    iFrameCurrent = listFrame(i);
    listIdxNearest(i) = idxRefNearest;

    frameRef = read(vRef,iFrameRef);
    frameCurrent = read(v,iFrameCurrent);
    trimmedRef = functions.trimImg(frameRef,hTrim,wTrim);
    trimmedCurrent = functions.trimImg(frameCurrent,hTrim,wTrim);
    grayRef = rgb2gray(trimmedRef);
    grayCurrent = rgb2gray(trimmedCurrent);

    tform = functions.getImgMove(grayRef,grayCurrent);
    diffTranslation = functions.getCarMove(tform,carCoG)/dataRef.m2px.*[1 -1];
    carPos(i,:) = dataRef.carPos(idxRefNearest,:)+...
        (functions.rot(yawNorthRef(idxRefNearest))*diffTranslation.').';
    carYaw(i) = dataRef.yawValid(idxRefNearest)+deg2rad(-tform.RotationAngle);
end

%%
% save("temp/carpos_sfl_comp.mat","carPos","carYaw","listIdxNearest")
% load("temp/carpos_sfl_comp.mat")

%%
figure("WindowStyle","docked")
imshow(dataRef.imgMap,dataRef.RA,"InitialMagnification","fit")
axis ij
hold on
for i = progress(1:length(carPos))
    tempFrom = [carPos(i,1) dataRef.carPos(listIdxNearest(i),1)];
    tempTo = [-carPos(i,2) -dataRef.carPos(listIdxNearest(i),2)];
    if i == 1
        h(3) = plot(tempFrom,tempTo,"SeriesIndex",3);
    else
        plot(tempFrom,tempTo,"SeriesIndex",3)
    end
end
h(1) = plot(dataRef.carPos(:,1),-dataRef.carPos(:,2),".-","MarkerSize",10,"LineWidth",0.75);
% scatter(dataRef.carPos(:,1),-dataRef.carPos(:,2),10,dataRef.listFrame,"filled")
h(2) = plot(carPos(:,1),-carPos(:,2),".-","MarkerSize",10,"LineWidth",0.75);
% scatter(carPos(:,1),-carPos(:,2),10,listFrame,"filled")
ax = gca;
ax.TickDir = "in";
title("Reference Lap vs. Extracted Lap")
xlabel("x (m)")
ylabel("y (m)")
% colorbar
legend(h,{"reference","extracted from replay","pair"})

%% evaluate the result with comparison to GPS data
load("input/sample_telemetry_tgt_for_eval.mat", ...
    "Lap","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth","Ground_Speed");

gpsLatLog = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
gpsLonLog = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

%%
figure("WindowStyle","docked")
geoplot(gpsLatLog,gpsLonLog)
geobasemap satellite

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
legend

%%
yawValidLogResampled = interp1(1:length(yawValidLog),yawValidLog,1:length(carYaw));
thDiffOvershoot = 2*pi*0.9;
diffCalcLog = carYaw-yawValidLogResampled.';
diffCalcLog = diffCalcLog(abs(diffCalcLog)<thDiffOvershoot);

figure("WindowStyle","docked")
plot(rad2deg(carYaw),"DisplayName","calculated")
hold on
plot(rad2deg(yawValidLogResampled),"DisplayName","log")
legend
title("Comparison of yaw North (deg)");
xlabel("Frame")
ylabel("Yaw North (deg)")

%%
disp("Mean absolute error (deg): " + mean(abs(rad2deg(diffCalcLog))))

%% convert to GPS coordinates
[gpsLat,gpsLon,~] = matmap3d.enu2geodetic(carPos(:,1),carPos(:,2),zeros(length(carPos),1), ...
    dataRef.lat0,dataRef.lon0,dataRef.h0);

figure("WindowStyle","docked")
geoplot(gpsLatValid,gpsLonValid,"DisplayName","log")
hold on
geoplot(gpsLat,gpsLon,"DisplayName","calculated")
legend

%% convert degrees to DMS
gpsLatDms = functions.deg2dms(gpsLat);
gpsLonDms = functions.deg2dms(gpsLon);

%% calculate speed
dTime = 1/v.FrameRate;
time = transpose(0:dTime:(length(carPos)-1)/v.FrameRate);
posNorm = vecnorm(diff(carPos),2,2);
speed = [posNorm; posNorm(end)]./dTime;

% Fill outliers before smoothing
speedInliers = filloutliers(speed,"center","movmedian",1,"ThresholdFactor",5,"SamplePoints",time);
% Smooth input data
speedSmoothed = smoothdata(speedInliers,"gaussian",0.5,"SamplePoints",time);

%% display results
figure("WindowStyle","docked")
plot(time,speed*3.6,"LineWidth",1.5,"DisplayName","Raw data")
hold on
plot(time,speedSmoothed*3.6,"LineWidth",1.5,"DisplayName","Smoothed data")
plot(timeValid,groundSpeedValid,"LineWidth",1.5,"DisplayName","Logged data")
grid on
title("Comparison of ground speed (km/h)");
legend
xlabel("Time (s)")
ylabel("Ground Speed (km/h)")

%% export to table
tableExport = table;
tableExport.("Time (s)") = time;
tableExport.("Lap Distance (m)") = cumtrapz(time,speedSmoothed);
tableExport.("Ground Speed (km/h)") = speedSmoothed*3.6;
tableExport.("Latitude Degrees ()") = gpsLatDms(:,1);
tableExport.("Latitude Minutes ()") = gpsLatDms(:,2);
tableExport.("Latitude Minute fraction ()") = gpsLatDms(:,3);
tableExport.("Longitude Degrees ()") = gpsLonDms(:,1);
tableExport.("Longitude Minutes ()") = gpsLonDms(:,2);
tableExport.("Longitude Minute - fraction ()") = gpsLonDms(:,3);
tableExport.("YawNorth (rad)") = carYaw.*(-1)+pi/2;
tableExport.("X (m)") = carPos(:,1);
tableExport.("Y (m)") = carPos(:,2);
tableExport.("AP Info:") = zeros(length(carPos),1);

writetable(tableExport,"output/sample_result.csv")
