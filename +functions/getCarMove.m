function translation = getCarMove(tform,carCoG)
arguments
    tform (1,1) rigidtform2d
    carCoG (1,2) double
end
% Get the translation of the car in the image
translation = tform.Translation-carCoG+transpose(irvtUtils.rot(tform.RotationAngle)*carCoG.');
end
