function arrayRotated = rot(theta)
arguments
    theta (1,1) double
end
arrayRotated = [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
end
