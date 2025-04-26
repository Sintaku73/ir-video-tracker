function translation = getCarMove(tform,carCoG)
rot = @(theta) [cosd(theta) -sind(theta); sind(theta) cosd(theta)];
translation = tform.Translation-carCoG+transpose(rot(tform.RotationAngle)*carCoG.');
end
