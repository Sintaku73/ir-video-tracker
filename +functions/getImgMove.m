function tform = getImgMove(gray1,gray2)
arguments
    gray1 (:,:) uint8
    gray2 (:,:) uint8
end
% Adjust brightness
gray1 = imlocalbrighten(gray1,"AlphaBlend",true);
gray2 = imlocalbrighten(gray2,"AlphaBlend",true);

pts1 = detectSURFFeatures(gray1,"MetricThreshold",500);
pts2 = detectSURFFeatures(gray2,"MetricThreshold",500);

[features1,validPts1] = extractFeatures(gray1,pts1);
[features2,validPts2] = extractFeatures(gray2,pts2);

indexPairs = matchFeatures(features1,features2);

matched1 = validPts1(indexPairs(:,1));
matched2 = validPts2(indexPairs(:,2));

[tform,~] = estgeotform2d(matched2,matched1,"rigid");
end
