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
iFrameEnd = v.NumFrames;
intervalFrame = 10;
listFrame = iFrameStart:intervalFrame:iFrameEnd;
nFrame = length(listFrame);
frameCurrent = read(v, iFrameStart);
trimmedCurrent = frameCurrent(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
grayCurrent = rgb2gray(trimmedCurrent);
diffPixel = zeros(nFrame, 2);
for i=progress(2:nFrame, "UpdateRate", 2)
    frameNext = read(v, listFrame(i));
    trimmedNext = frameNext(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
    grayNext = rgb2gray(trimmedNext);

    ptsOriginal = detectSURFFeatures(grayCurrent);
    ptsDistorted = detectSURFFeatures(grayNext);

    [featuresOriginal,validPtsOriginal] = extractFeatures(grayCurrent,ptsOriginal);
    [featuresDistorted,validPtsDistorted] = extractFeatures(grayNext,ptsDistorted);

    indexPairs = matchFeatures(featuresOriginal,featuresDistorted);

    matchedOriginal = validPtsOriginal(indexPairs(:,1));
    matchedDistorted = validPtsDistorted(indexPairs(:,2));

    [tform,inlierIdx] = estgeotform2d(matchedDistorted,matchedOriginal,"similarity");

    diffPixel(i, :) = tform.Translation;
    grayCurrent = grayNext;
end
cumPixel = cumsum(diffPixel) .* [1 -1];

%%
figure
plot(cumPixel(:, 1), cumPixel(:, 2), ".-")
axis equal

%%
% save("input\line_6Hz.mat","cumPixel","listFrame");