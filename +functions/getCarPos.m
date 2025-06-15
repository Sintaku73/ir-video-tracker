function [carPos,carYaw,listFrame] = getCarPos(v,iFrameStart,iFrameEnd,hTrim,wTrim,intervalFrame)
arguments
    v (1,1) VideoReader
    iFrameStart (1,1) double
    iFrameEnd (1,1) double
    hTrim (1,1) double = 720
    wTrim (1,1) double = 1790
    intervalFrame (1,1) double = 1
end
% Get the car position and yaw from the video
listFrame = iFrameStart:intervalFrame:iFrameEnd;
nFrame = length(listFrame);
frameCurrent = read(v,iFrameStart);
trimmedCurrent = functions.trimImg(frameCurrent,hTrim,wTrim);
grayCurrent = rgb2gray(trimmedCurrent);
diffTranslation = zeros(nFrame,2);
diffAngle = zeros(nFrame,1);

for i=progress(2:nFrame,"UpdateRate",2)
    frameNext = read(v,listFrame(i));
    trimmedNext = functions.trimImg(frameNext,hTrim,wTrim);
    grayNext = rgb2gray(trimmedNext);

    tform = functions.getImgMove(grayCurrent,grayNext);
    diffTranslation(i,:) = tform.Translation;
    diffAngle(i) = tform.RotationAngle;

    grayCurrent = grayNext;
end

carCoG = [wTrim/2+0.5 hTrim/2+0.5];
carYaw = cumsum(diffAngle);
diffRotated=zeros(size(diffTranslation));
for i=2:nFrame
    diffRotated(i,:)=transpose(functions.rot(carYaw(i-1))*diffTranslation(i,:).' ...
        -functions.rot(carYaw(i-1))*carCoG.'+functions.rot(carYaw(i))*carCoG.');
end
carPos = cumsum(diffRotated);

% Fix the difference between start and end
frameStart = read(v,listFrame(1));
frameEnd = read(v,listFrame(end));

trimmedStart = functions.trimImg(frameStart,hTrim,wTrim);
trimmedEnd = functions.trimImg(frameEnd,hTrim,wTrim);
grayStart = rgb2gray(trimmedStart);
grayEnd = rgb2gray(trimmedEnd);

tform = functions.getImgMove(grayStart,grayEnd);
diffS2E = functions.getCarMove(tform,carCoG);

shiftPos = carPos(1,:)-carPos(end,:)+diffS2E;
carPos = (carPos+linspace(0,1,nFrame).'.*shiftPos).*[1 -1];

shiftAngle = tform.RotationAngle-carYaw(end);
carYaw = (carYaw+linspace(0,1,nFrame).'.*shiftAngle).*(-1);
end
