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

%%
hTrim = 300;
wTrim = hTrim;

posInt = round(cumPixel);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrim wTrim]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = cumPixel+flip(shiftMap,2)+([wTrim hTrim]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:length(listFrame))
    nFrame = listFrame(i);
    frameCurrent = trimImg(read(v,nFrame),hTrim,wTrim);
    idxCurrent = posFlip(i,:)+shiftMap;
    imgMap(idxCurrent(1):idxCurrent(1)+hTrim-1, idxCurrent(2):idxCurrent(2)+wTrim-1,:) = frameCurrent;
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
