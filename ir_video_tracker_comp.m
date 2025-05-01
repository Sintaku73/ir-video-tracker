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

% [carPos,~,listFrame] = irvtUtils.getCarPos(v,iFrameStart,iFrameEnd);

%%
% save("temp\carpos_sfl.mat","carPos","carYaw","listFrame");
load("temp/carpos_sfl.mat");

%%
lapDistRef = cumsum([0; vecnorm(diff(dataRef.carPos),2,2)]);
lapDistPctRef = lapDistRef./max(lapDistRef).*100;
lapDist = cumsum([0; vecnorm(diff(carPos),2,2)]);
lapDistPct = lapDist./max(lapDist).*100;

%%
hTrim = 720;
wTrim = 1790;
carCoG = [wTrim/2+0.5 hTrim/2+0.5];
carPos = zeros(length(listFrame),2);
carYaw = zeros(length(listFrame),1);
iTemp = zeros(length(listFrame),1);
% for i = progress(1:length(listFrame),"UpdateRate",2)
for i = progress(901:1000,"UpdateRate",2)
    [~,idxRefNearest] = min(abs(lapDistPctRef-lapDistPct(i)));
    iFrameRef = dataRef.listFrame(idxRefNearest);
    iFrameCurrent = listFrame(i);
    iTemp(i) = idxRefNearest;

    frameRef = read(dataRef.v,iFrameRef);
    frameCurrent = read(v,iFrameCurrent);
    trimmedRef = irvtUtils.trimImg(frameRef,hTrim,wTrim);
    trimmedCurrent = irvtUtils.trimImg(frameCurrent,hTrim,wTrim);
    grayRef = rgb2gray(trimmedRef);
    grayCurrent = rgb2gray(trimmedCurrent);

    tform = irvtUtils.getImgMove(grayCurrent,grayRef);
    diffTranslation = irvtUtils.getCarMove(tform,carCoG)/dataRef.m2px;
    carPos(i,:) = dataRef.carPos(idxRefNearest,:)+...
        (irvtUtils.rot(rad2deg(dataRef.yawValid(idxRefNearest)))*diffTranslation.').';
    carYaw(i) = dataRef.yawValid(idxRefNearest)+deg2rad(tform.RotationAngle);
end

%% visualize the result
vectorYaw = [cos(carYaw) sin(carYaw)];
vectorYaw = vectorYaw./vecnorm(vectorYaw,2,2);

figure("WindowStyle","docked")
plot(carPos(:,1),carPos(:,2));
axis equal
grid on
hold on
plot(dataRef.carPos(:,1),dataRef.carPos(:,2))
scatter(dataRef.carPos(:,1),dataRef.carPos(:,2),30,dataRef.listFrame,"filled")
quiver(carPos(:,1),carPos(:,2),vectorYaw(:,1),vectorYaw(:,2),"off")
% scatter(carPos(:,1),carPos(:,2),5,rad2deg(carYaw))
scatter(carPos(:,1),carPos(:,2),30,iTemp,"filled")
clim([min(iTemp(iTemp>0)) max(iTemp(iTemp>0))])
colorbar
