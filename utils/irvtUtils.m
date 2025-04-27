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

        function [carPos,yawValid,listFrame,m2px,imgMap,RA] = getTrackMapLog( ...
                v,iFrameStart,pathLog,lapSelected,hTrimMap,wTrimMap,hCut,wCut,hTrimMove,wTrimMove)
            % Load the log file
            load(pathLog,"Lap","Latitude_Degrees","Latitude_Minutes","Latitude_Minute_fraction", ...
                "Longitude_Degrees","Longitude_Minutes","Longitude_Minute___fraction","GPS_Altitude","YawNorth");
            gpsLat = Latitude_Degrees.Value + Latitude_Minutes.Value./60 + Latitude_Minute_fraction.Value./3600;
            gpsLon = Longitude_Degrees.Value + Longitude_Minutes.Value./60 + Longitude_Minute___fraction.Value./3600;

            % Select the lap
            idxValid = Lap.Value==lapSelected;
            gpsLatValid = gpsLat(idxValid);
            gpsLonValid = gpsLon(idxValid);
            gpsAltValid = GPS_Altitude.Value(idxValid);
            yawValid = (YawNorth.Value(idxValid)-pi/2).*(-1);

            [x,y,~] = matmap3d.geodetic2enu(gpsLatValid,gpsLonValid,gpsAltValid,gpsLatValid(1),gpsLonValid(1),gpsAltValid(1));
            carPos = [x.' y.'].*[1 -1];

            nData = sum(idxValid);
            listFrame = iFrameStart:iFrameStart+nData-1;

            % Calculate resolution
            carCoG = [wTrimMove/2+0.5 hTrimMove/2+0.5];
            diffGps = vecnorm(diff(carPos,[],1),2,2);

            frameStart = irvtUtils.trimImg(read(v,listFrame(1)),hTrimMove,wTrimMove);
            frameStartNext =  irvtUtils.trimImg(read(v,listFrame(2)),hTrimMove,wTrimMove);
            frameEnd = irvtUtils.trimImg(read(v,listFrame(end)),hTrimMove,wTrimMove);
            frameEndPrev = irvtUtils.trimImg(read(v,listFrame(end-1)),hTrimMove,wTrimMove);

            tformStart = irvtUtils.getImgMove(rgb2gray(frameStart),rgb2gray(frameStartNext));
            tfotmEnd = irvtUtils.getImgMove(rgb2gray(frameEndPrev),rgb2gray(frameEnd));

            diffFrameStart = norm(irvtUtils.getCarMove(tformStart,carCoG));
            diffFrameEnd = norm(irvtUtils.getCarMove(tfotmEnd,carCoG));

            m2px = mean([diffFrameStart/diffGps(1) diffFrameEnd/diffGps(end)]);
            carPosPixel = carPos.*m2px;

            posInt = round(carPosPixel);
            posFlip = flip(posInt,2);
            sizeMap = max(posFlip,[],1)-min(posFlip,[],1)+[hTrimMap wTrimMap]+1;
            shiftMap = min(posFlip,[],1)*(-1)+1;

            imgMap = zeros(sizeMap(1),sizeMap(2),3,"uint8");
            for i = progress(1:nData,"UpdateRate",2)
                iFrame = listFrame(i);
                frameCurrent = irvtUtils.trimImg(read(v,iFrame),hTrimMap,wTrimMap);
                frameCurrent = irvtUtils.deleteAroundCar(frameCurrent,hCut,wCut);
                frameCurrent = imrotate(frameCurrent,rad2deg(yawValid(i))-90,"crop");
                idxStart = posFlip(i,:)+shiftMap;
                idxEnd = idxStart+[hTrimMap wTrimMap]-1;
                imgTemp = imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:);
                boolHollow = (frameCurrent==0);
                imgMap(idxStart(1):idxEnd(1), idxStart(2):idxEnd(2),:) = imgTemp.*uint8(boolHollow)+frameCurrent;
            end

            % Calculate the map limits
            posMin = min(carPos,[],1);
            posMax = max(carPos,[],1);

            hTrimMeter = hTrimMap/m2px;
            wTrimMeter = wTrimMap/m2px;

            xWorldLimits = [posMin(1)-hTrimMeter/2 posMax(1)+hTrimMeter/2];
            yWorldLimits = [posMin(2)-wTrimMeter/2 posMax(2)+wTrimMeter/2];
            RA = imref2d(size(imgMap),xWorldLimits,yWorldLimits);
        end
    end
end