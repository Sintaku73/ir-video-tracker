clear
close all

%%
addpath(fullfile(pwd,"utils"));

%%
vRef = VideoReader("input/iRacing.com Simulator 2025-04-21 00-14-39.mp4");
v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-25-11.mp4");
iFrame1 = 895;
iFrame2 = 979;
frame1 = read(vRef,iFrame1);
frame2 = read(v,iFrame2);

% figure("WindowStyle","docked")
% imshowpair(frame1,frame2,"montage");

%%
hImg = vRef.Height;
wImg = vRef.Width;
hTrim = 720;
wTrim = 960;

%%
trimmed1 = irvtUtils.trimImg(frame1,hTrim,wTrim);
trimmed2 = irvtUtils.trimImg(frame2,hTrim,wTrim);

figure("WindowStyle","docked")
imshowpair(trimmed1,trimmed2,"montage")
axis on

%%
gray1 = rgb2gray(trimmed1);
gray2 = rgb2gray(trimmed2);

%% Find Matching Features Between Images
% Detect features in both images.
pts1 = detectSURFFeatures(gray1);
pts2 = detectSURFFeatures(gray2);

%%
% Extract feature descriptors from the original and distorted features.
[features1,validPts1] = extractFeatures(gray1,pts1);
[features2,validPts2] = extractFeatures(gray2,pts2);

%%
% Match features by using their descriptors.
indexPairs = matchFeatures(features1,features2);

%%
% Retrieve locations of corresponding points for each image.
matched1 = validPts1(indexPairs(:,1));
matched2 = validPts2(indexPairs(:,2));

%%
% Show putative point matches.
figure("WindowStyle","docked")
showMatchedFeatures(gray1,gray2,matched1,matched2)
title("Putatively matched points (including outliers)")
axis on

%% Estimate Transformation
% Identify a transformation based on matching point pairs with the
% M-estimator Sample Consensus (MSAC) algorithm, a robust variant of RANSAC.
% This algorithm excludes outliers to compute the transformation matrix accurately.
% Due to its reliance on random sampling, the MSAC algorithm may produce
% varying results in the transformation computation.
[tform,inlierIdx] = estgeotform2d(matched2,matched1,"rigid");
tformUtils = irvtUtils.getImgMove(gray1,gray2);
inlierDistorted = matched2(inlierIdx,:);
inlierOriginal = matched1(inlierIdx,:);

%%
% Display matching point pairs used in the computation of the
% transformation.
figure("WindowStyle","docked")
showMatchedFeatures(trimmed1,trimmed2,inlierOriginal,inlierDistorted)
title("Matching points (inliers only)")
legend("pts1","pts2")
axis on

%% Solve for Scale and Angle
% Use the geometric transform, |tform|, to recover the scale and angle.
% Since the transformation was computed from the distorted to the
% original image, its inverse must be computed to recover the distortion.
%
%  Let sc = s*cos(theta)
%  Let ss = s*sin(theta)
%
%  Then, Ainv = [sc  ss  tx;
%               -ss  sc  ty;
%                 0   0   1]
%
%  where tx and ty are x and y translations, respectively.
%

%% Recover the Original Image
% Recover the original image by transforming the distorted image.
outputView = imref2d(size(trimmed1));
recovered = imwarp(trimmed2,tform,"OutputView",outputView);

%%
% Compare |recovered| to |original| by looking at them side-by-side in a
% montage.
figure("WindowStyle","docked")
imshowpair(trimmed1,recovered,"falsecolor")
axis on
