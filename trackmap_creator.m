%%
close all
clear

%%
load("input\line_6Hz.mat");
cumPixel = cumPixel .* [1 -1];
v = VideoReader("input\2024-11-03 00-20-27_0_0.mp4");

%%
function imgTrimmed = trimImg(imgOrig,hTrim,wTrim)
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg - hTrim)/2 + 1;
wIdxStart = (wImg - wTrim)/2 + 1;
imgTrimmed = imgOrig(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
end

function imgHollow = deleteAroundCar(imgOrig,hCut,wCut)
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg - hCut)/2 + 1;
wIdxStart = (wImg - wCut)/2 + 1;
imgOrig(hIdxStart:hIdxStart+hCut-1, wIdxStart:wIdxStart+wCut-1, :) = 0;
imgHollow = imgOrig;
end

%%
hTrim = 300;
wTrim = hTrim;
hCut = 80;
wCut = hCut;

posInt = round(cumPixel);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrim wTrim]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = cumPixel+flip(shiftMap,2)+([wTrim hTrim]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:length(listFrame),"UpdateRate",2)
    nFrame = listFrame(i);
    frameCurrent = trimImg(read(v,nFrame),hTrim,wTrim);
    frameCurrent = deleteAroundCar(frameCurrent,hCut,wCut);
    idxStart = posFlip(i,:)+shiftMap;
    idxEnd = idxStart+[hTrim wTrim]-1;
    imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
    boolHollow = (frameCurrent==0);
    imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
end

%%
% imwrite(imgMap,"temp\trackmap_suzuka.png")

f = figure;
imshow(imgMap)
hold on
ylim([0.5 sizeMap(2)*3/4+0.5])
plot(posShifted(:,1),posShifted(:,2))
axis on
f.Position(2:4)=[360 800 600];
