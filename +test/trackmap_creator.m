%%
close all
clear

%%
load("input/line_60Hz.mat");
carPos = carPos.*[1 -1];
v = VideoReader("input/sample_video_ref.mp4");

%%
hTrim = 300;
wTrim = hTrim;
hCar = 60;
wCar = 30;

posInt = round(carPos);
posFlip = flip(posInt,2);
sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrim wTrim]+1;
shiftMap = min(posFlip,[],1)*(-1)+1;
posShifted = carPos+flip(shiftMap,2)+([wTrim hTrim]+1)/2;

%%
imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
for i = progress(1:length(listFrame),"UpdateRate",2)
    nFrame = listFrame(i);
    frameCurrent = functions.trimImg(read(v,nFrame),hTrim,wTrim);
    frameCurrent = functions.deleteAroundCar(frameCurrent,hCar,wCar);
    frameCurrent = imrotate(frameCurrent,carYaw(i),"crop");
    idxStart = posFlip(i,:)+shiftMap;
    idxEnd = idxStart+[hTrim wTrim]-1;
    imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
    boolHollow = (frameCurrent==0);
    imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
end

%%
% imwrite(imgMap,"temp/trackmap_suzuka.png")

f = figure;
imshow(imgMap)
hold on
ylim([0.5 sizeMap(2)*3/4+0.5])
plot(posShifted(:,1),posShifted(:,2))
axis on
f.Position(2:4)=[360 800 600];
