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
