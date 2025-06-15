function imgHollow = deleteAroundCar(imgOrig,hCut,wCut)
arguments
    imgOrig (:,:,3) uint8
    hCut (1,1) double
    wCut (1,1) double
end
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg-hCut)/2+1;
wIdxStart = (wImg-wCut)/2+1;
imgOrig(hIdxStart:hIdxStart+hCut-1,wIdxStart:wIdxStart+wCut-1,:) = 0;
imgHollow = imgOrig;
end
