%%
addpath(fullfile(pwd,"utils"));

%%
dataRef = load("input/reference_lap.mat");

v = VideoReader("input/iRacing.com Simulator 2025-04-21 00-25-11.mp4");
iFrameStart = 156;
iFrameEnd = 7070;
intervalFrame = 1;

listFrame = iFrameStart:intervalFrame:iFrameEnd;

%%
tableResult = readtable("temp/suzuka_sfl.csv","VariableNamingRule","preserve");

%%
hShowPx = 272;
wShowPx = 480;
hShowMeter = hShowPx/dataRef.m2px;
wShowMeter = wShowPx/dataRef.m2px;

arrowLength = 5;

yawAdjusted = (tableResult.("YawNorth (rad)")-pi/2).*(-1);
vectorYaw = [cos(yawAdjusted) sin(yawAdjusted)];
vectorYaw = vectorYaw./vecnorm(vectorYaw,2,2);

xCurrent = tableResult.("X (m)")(1);
yCurrent = -tableResult.("Y (m)")(1);

vOut = VideoWriter("temp/demo.mp4","MPEG-4");
vOut.FrameRate = 60;
open(vOut);

f = figure("Visible","off","Position",[100 100 1280 720]);

ax1 = subplot(2,2,1);
frame = read(v,listFrame(1));
frameTrimmed = irvtUtils.trimImg(frame,hShowPx,wShowPx);
im1 = imshow(frameTrimmed);
title("Input Replay (Trimmed)")

ax2 = subplot(2,2,2);
imshow(dataRef.imgMap,dataRef.RA)
hold on
plot(tableResult.("X (m)"),-tableResult.("Y (m)"),"LineWidth",2)
q2 = quiver(xCurrent,yCurrent,vectorYaw(1,1),-vectorYaw(1,2),"Color","red","LineWidth",2, ...
    "AutoScaleFactor",arrowLength,"MaxHeadSize",arrowLength/2);
q2.Marker = "o";
q2.MarkerFaceColor = "#D95319";
xlabel("x (m)")
ylabel("y (m)")
xlim([xCurrent-wShowMeter/2 xCurrent+wShowMeter/2])
ylim([yCurrent-hShowMeter/2 yCurrent+hShowMeter/2])
ax2.TickDir = "in";
title("Output Result (Racing Line & Yaw Angle)")

ax3 = subplot(2,2,[3,4]);
plot(tableResult.("Time (s)"),tableResult.("Ground Speed (km/h)"),"LineWidth",1.5)
hold on
p3 = plot(tableResult.("Time (s)")(1),tableResult.("Ground Speed (km/h)")(1), ...
    'o','MarkerFaceColor','red');
xl3 = xline(tableResult.("Time (s)")(1),"black","LineWidth",1.5,"Layer","bottom");
grid on
xlabel("Time (sec)")
ylabel("Speed (km/h)")
titleSpeed = "Ground Speed : %.1f km/h";
title(sprintf(titleSpeed,tableResult.("Ground Speed (km/h)")(1)))

hold off
fontsize(14,"points")
sgtitle("Extraction of Driving Data from Replays","FontSize",18)

% f.Visible = "on";
frameWrite = getframe(gcf);
writeVideo(vOut,frameWrite);
for i = progress(2:length(listFrame),"UpdateRate",2)
    frame = read(v,listFrame(i));
    frameTrimmed = irvtUtils.trimImg(frame,hShowPx,wShowPx);
    im1.CData = frameTrimmed;

    xCurrent = tableResult.("X (m)")(i);
    yCurrent = -tableResult.("Y (m)")(i);
    q2.XData = xCurrent;
    q2.YData = yCurrent;
    q2.UData = vectorYaw(i,1);
    q2.VData = -vectorYaw(i,2);
    ax2.XLim = [xCurrent-wShowMeter/2 xCurrent+wShowMeter/2];
    ax2.YLim = [yCurrent-hShowMeter/2 yCurrent+hShowMeter/2];

    p3.XData = tableResult.("Time (s)")(i);
    p3.YData = tableResult.("Ground Speed (km/h)")(i);
    xl3.Value = tableResult.("Time (s)")(i);
    ax3.Title.String = sprintf(titleSpeed,tableResult.("Ground Speed (km/h)")(i));

    drawnow
    frameWrite = getframe(gcf);
    writeVideo(vOut,frameWrite);
end
close(vOut);
