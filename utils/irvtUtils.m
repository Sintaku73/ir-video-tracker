classdef irvtUtils
    properties
        Translation
        RotationAngle
    end

    methods(Static)
        function translation = getCarMove(tform,carCoG)
            rot = @(theta) [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
            translation = tform.Translation-carCoG+transpose(rot(tform.RotationAngle)*carCoG.');
        end

        function tform = getImgMove(gray1,gray2)
            pts1 = detectSURFFeatures(gray1);
            pts2 = detectSURFFeatures(gray2);

            [features1,validPts1] = extractFeatures(gray1,pts1);
            [features2,validPts2] = extractFeatures(gray2,pts2);

            indexPairs = matchFeatures(features1,features2);

            matched1 = validPts1(indexPairs(:,1));
            matched2 = validPts2(indexPairs(:,2));

            [tform,~] = estgeotform2d(matched2,matched1,"rigid");
        end

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
    end
end