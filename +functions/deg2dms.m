function [dms] = deg2dms(deg)
dms = zeros(length(deg),3);
dms(:,1) = floor(deg);
dms(:,2) = floor((deg-dms(:,1))*60);
dms(:,3) = (deg-dms(:,1)-dms(:,2)/60)*3600;
end
