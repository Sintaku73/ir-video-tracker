function iFrame = detectLapChange(v,rect,thDetectLap,searchBackward)
arguments
    v (1,1) VideoReader
    rect (1,4) double % [x y width height]
    thDetectLap (1,1) double = 5 % threshold for lap change detection in percentage
    searchBackward (1,1) logical = false % whether to backward the search direction
end

if searchBackward
    iFirst = v.NumFrames;
    listFrame = v.NumFrames-1:-1:1; % background
else
    iFirst = 1;
    listFrame = 2:v.NumFrames; % forward
end

framePrev = imcrop(read(v,iFirst),rect);
bwPrev = imbinarize(rgb2gray(framePrev));
for i = progress(listFrame)
    frameLap = imcrop(read(v,i),rect);
    bwLap = imbinarize(rgb2gray(frameLap));
    diffLap = imabsdiff(bwPrev,bwLap);
    ratioDiff = sum(diffLap,"all")/numel(diffLap)*100;
    if ratioDiff > thDetectLap
        iFrame = i;
        break
    end
end
end