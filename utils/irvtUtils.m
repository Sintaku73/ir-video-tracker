classdef irvtUtils
    properties
        Translation
        RotationAngle
    end

    methods(Static)
        function arrayRotated = rot(theta)
            arrayRotated = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
        end

        function translation = getCarMove(tform,carCoG)
            translation = tform.Translation-carCoG+transpose(irvtUtils.rot(tform.RotationAngle)*carCoG.');
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
            hIdxStart = (hImg-hTrim)/2+1;
            wIdxStart = (wImg-wTrim)/2+1;
            imgTrimmed = imgOrig(hIdxStart:hIdxStart+hTrim-1,wIdxStart:wIdxStart+wTrim-1,:);
        end

        function imgHollow = deleteAroundCar(imgOrig,hCut,wCut)
            hImg = size(imgOrig,1);
            wImg = size(imgOrig,2);
            hIdxStart = (hImg-hCut)/2+1;
            wIdxStart = (wImg-wCut)/2+1;
            imgOrig(hIdxStart:hIdxStart+hCut-1,wIdxStart:wIdxStart+wCut-1,:) = 0;
            imgHollow = imgOrig;
        end

        function [carPos,carYaw,listFrame] = getCarPos(v,hTrim,wTrim,iFrameStart,iFrameEnd,intervalFrame)
            listFrame = iFrameStart:intervalFrame:iFrameEnd;
            nFrame = length(listFrame);
            frameCurrent = read(v,iFrameStart);
            trimmedCurrent = irvtUtils.trimImg(frameCurrent,hTrim,wTrim);
            grayCurrent = rgb2gray(trimmedCurrent);
            diffTranslation = zeros(nFrame,2);
            diffAngle = zeros(nFrame,1);

            for i=progress(2:nFrame,"UpdateRate",2)
                frameNext = read(v,listFrame(i));
                trimmedNext = irvtUtils.trimImg(frameNext,hTrim,wTrim);
                grayNext = rgb2gray(trimmedNext);

                tform = irvtUtils.getImgMove(grayCurrent,grayNext);
                diffTranslation(i,:) = tform.Translation;
                diffAngle(i) = tform.RotationAngle;

                grayCurrent = grayNext;
            end

            carCoG = [wTrim/2+0.5 hTrim/2+0.5];
            carYaw = cumsum(diffAngle);
            diffRotated=zeros(size(diffTranslation));
            for i=2:nFrame
                diffRotated(i,:)=transpose(irvtUtils.rot(carYaw(i-1))*diffTranslation(i,:).' ...
                    -irvtUtils.rot(carYaw(i-1))*carCoG.'+irvtUtils.rot(carYaw(i))*carCoG.');
            end
            carPos = cumsum(diffRotated);

            % Fix the difference between start and end
            frameStart = read(v,listFrame(1));
            frameEnd = read(v,listFrame(end));

            trimmedStart = irvtUtils.trimImg(frameStart,hTrim,wTrim);
            trimmedEnd = irvtUtils.trimImg(frameEnd,hTrim,wTrim);
            grayStart = rgb2gray(trimmedStart);
            grayEnd = rgb2gray(trimmedEnd);

            tform = irvtUtils.getImgMove(grayStart,grayEnd);
            diffS2E = irvtUtils.getCarMove(tform,carCoG);

            shiftPos = carPos(1,:)-carPos(end,:)+diffS2E;
            carPos = (carPos+linspace(0,1,nFrame).'.*shiftPos).*[1 -1];

            shiftAngle = tform.RotationAngle-carYaw(end);
            carYaw = carYaw+linspace(0,1,nFrame).'.*shiftAngle;
        end
    end
end