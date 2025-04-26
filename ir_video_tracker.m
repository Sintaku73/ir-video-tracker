clear
close all

%%
addpath(fullfile(pwd,"utils"));

v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

hImg = v.Height;
wImg = v.Width;
hTrim = 720;
wTrim = 1790;

carCoG = [wTrim/2+0.5 hTrim/2+0.5];

hIdxStart = (hImg - hTrim)/2 + 1;
wIdxStart = (wImg - wTrim)/2 + 1;

%%
iFrameStart = 185;
iFrameEnd = 6230;
intervalFrame = 1;
listFrame = iFrameStart:intervalFrame:iFrameEnd;
nFrame = length(listFrame);
frameCurrent = read(v, iFrameStart);
trimmedCurrent = trimImg(frameCurrent,hTrim,wTrim);
grayCurrent = rgb2gray(trimmedCurrent);
diffTranslation = zeros(nFrame, 2);
diffAngle = zeros(nFrame,1);

%%
for i=progress(2:nFrame, "UpdateRate", 2)
    frameNext = read(v, listFrame(i));
    trimmedNext = trimImg(frameNext,hTrim,wTrim);
    grayNext = rgb2gray(trimmedNext);

    tform = getImgMove(grayCurrent,grayNext);
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

trimmedStart = trimImg(frameStart,hTrim,wTrim);
trimmedEnd = trimImg(frameEnd,hTrim,wTrim);

grayStart = rgb2gray(trimmedStart);
grayEnd = rgb2gray(trimmedEnd);

tform = getImgMove(grayStart,grayEnd);
diffS2E = getCarMove(tform,carCoG);

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
