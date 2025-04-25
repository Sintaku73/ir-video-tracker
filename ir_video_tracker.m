clear
close all

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
iFrameStart = 185;
iFrameEnd = 6230;
intervalFrame = 30;
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
% carPos = cumsum(diffTranslation).*[1 -1];
cumAngle = cumsum(diffAngle);

%%
rot = @(theta) [cosd(theta) -sind(theta); sind(theta) cosd(theta)];

diffRotated=zeros(size(diffTranslation));
for i=2:nFrame
    diffRotated(i,:)=transpose(rot(cumAngle(i-1))*diffTranslation(i,:).' ...
        -rot(cumAngle(i-1))*carCoG.'+rot(cumAngle(i))*carCoG.');
end

%%
carPos = cumsum(diffRotated).*[1 -1];

%% Fix the defference between start and end
frameStart = read(v,listFrame(1));
frameEnd = read(v,listFrame(end));

trimmedStart = trimImg(frameStart,hTrim,wTrim);
trimmedEnd = trimImg(frameEnd,hTrim,wTrim);

grayStart = rgb2gray(trimmedStart);
grayEnd = rgb2gray(trimmedEnd);

diffS2E = getImgMove(grayStart,grayEnd).Translation.*[1 -1];

%%
shiftEnd = carPos(1,:)-carPos(end,:)+diffS2E;
carPos = carPos+linspace(0,1,nFrame).'.*shiftEnd;

%%
str = num2cell(listFrame);
figure
plot(carPos(:,1),carPos(:,2),".-")
axis equal
hold on
text(carPos(:,1),carPos(:,2),str)

%%
save(sprintf("input/line_%dHz.mat",v.FrameRate/intervalFrame),"carPos","cumAngle","listFrame");

%%
function tform = getImgMove(gray1,gray2)
pts1 = detectSURFFeatures(gray1);
pts2 = detectSURFFeatures(gray2);

[features1,validPts1] = extractFeatures(gray1,pts1);
[features2,validPts2] = extractFeatures(gray2,pts2);

indexPairs = matchFeatures(features1,features2);

matched1 = validPts1(indexPairs(:,1));
matched2 = validPts2(indexPairs(:,2));

[tform,~] = estgeotform2d(matched2,matched1,"rigid");
end
