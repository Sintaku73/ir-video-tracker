function imgTrimmed = trimImg(imgOrig,hTrim,wTrim)
hImg = size(imgOrig,1);
wImg = size(imgOrig,2);
hIdxStart = (hImg - hTrim)/2 + 1;
wIdxStart = (wImg - wTrim)/2 + 1;
imgTrimmed = imgOrig(hIdxStart:hIdxStart+hTrim-1, wIdxStart:wIdxStart+wTrim-1, :);
end
