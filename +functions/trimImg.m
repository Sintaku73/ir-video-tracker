function imgTrimmed = trimImg(imgOrig,hTrim,wTrim)
arguments
    imgOrig (:,:,3) uint8
    hTrim (1,1) double
    wTrim (1,1) double
end
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg-hTrim)/2+1;
wIdxStart = (wImg-wTrim)/2+1;
imgTrimmed = imgOrig(hIdxStart:hIdxStart+hTrim-1,wIdxStart:wIdxStart+wTrim-1,:);
end
