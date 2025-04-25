%%
close all
clear

%%
addpath(fullfile(pwd,"utils"));

load("input\line_60Hz.mat");
carPos = carPos.*[1 -1];
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");

%%
hTrim = 300;
wTrim = hTrim;
hCut = 60;
wCut = 30;

posInt = round(carPos);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrim wTrim]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = carPos+flip(shiftMap,2)+([wTrim hTrim]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:length(listFrame),"UpdateRate",2)
    nFrame = listFrame(i);
    frameCurrent = trimImg(read(v,nFrame),hTrim,wTrim);
    frameCurrent = deleteAroundCar(frameCurrent,hCut,wCut);
    frameCurrent = imrotate(frameCurrent,-cumAngle(i),"crop");
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

%%
function imgHollow = deleteAroundCar(imgOrig,hCut,wCut)
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg - hCut)/2 + 1;
wIdxStart = (wImg - wCut)/2 + 1;
imgOrig(hIdxStart:hIdxStart+hCut-1, wIdxStart:wIdxStart+wCut-1, :) = 0;
imgHollow = imgOrig;
end
