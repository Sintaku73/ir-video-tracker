%%
clear
close all

%%
load("input/sample_telemetry_ref.mat", ...
    "Lap","Lap_Distance","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
    "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");

%%
samplingRate = 1/mean(diff(Lap.Time));
lapN = Lap.Value./max(Lap.Value);
distN = Lap_Distance.Value./max(Lap_Distance.Value);

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
