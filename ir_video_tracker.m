clear
close all

%%
v = VideoReader("input/2024-11-03 00-20-27_0_0.mp4");

hImg = v.Height;
wImg = v.Width;
hTrim = 720;
wTrim = 1790;

hIdxStart = (hImg - hTrim)/2 + 1;
wIdxStart = (wImg - wTrim)/2 + 1;

%%
iFrameStart = 44;
iFrameEnd = 5854;
intervalFrame = 10;
listFrame = iFrameStart:intervalFrame:iFrameEnd;
nFrame = length(listFrame);
frameCurrent = read(v, iFrameStart);
trimmedCurrent = frameCurrent(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
grayCurrent = rgb2gray(trimmedCurrent);
diffPixel = zeros(nFrame, 2);

%%
for i=progress(2:nFrame, "UpdateRate", 2)
    frameNext = read(v, listFrame(i));
    trimmedNext = frameNext(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
    grayNext = rgb2gray(trimmedNext);

    diffPixel(i, :) = getTranslation(grayCurrent,grayNext);

    grayCurrent = grayNext;
end
carPos = cumsum(diffPixel) .* [1 -1];

%% Fix the defference between start and end
frameStart = read(v,listFrame(1));
frameEnd = read(v,listFrame(end));

trimmedStart = frameStart(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
trimmedEnd = frameEnd(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);

grayStart = rgb2gray(trimmedStart);
grayEnd = rgb2gray(trimmedEnd);

diffS2E = getTranslation(grayStart,grayEnd) .* [1 -1];

%%
shiftEnd = carPos(1,:)-carPos(end,:)+diffS2E;
carPos = carPos+linspace(0,1,nFrame).'.*shiftEnd;

%%
figure
plot(carPos(:,1),carPos(:,2),".-")
axis equal

%%
% save(sprintf("input/line_%dHz.mat",v.FrameRate/intervalFrame),"carPos","listFrame");

%%
function translation = getTranslation(gray1,gray2)
pts1 = detectSURFFeatures(gray1);
pts2 = detectSURFFeatures(gray2);

[features1,validPts1] = extractFeatures(gray1,pts1);
[features2,validPts2] = extractFeatures(gray2,pts2);

indexPairs = matchFeatures(features1,features2);

matched1 = validPts1(indexPairs(:,1));
matched2 = validPts2(indexPairs(:,2));

[tform,~] = estgeotform2d(matched2,matched1,"similarity");

translation = tform.Translation;
end
