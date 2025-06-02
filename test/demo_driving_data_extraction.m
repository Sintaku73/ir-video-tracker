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

xCurrent = tableResult.("X (m)")(1);
yCurrent = -tableResult.("Y (m)")(1);

vOut = VideoWriter("temp/demo.mp4","MPEG-4");
vOut.FrameRate = 60;
open(vOut);

f = figure("Visible","off");

ax1 = subplot(2,2,1);
frame = read(v,listFrame(1));
frameTrimmed = irvtUtils.trimImg(frame,hShowPx,wShowPx);
im1 = imshow(frameTrimmed);

ax2 = subplot(2,2,2);
imshow(dataRef.imgMap,dataRef.RA)
hold on
plot(tableResult.("X (m)"),-tableResult.("Y (m)"),"LineWidth",2)
p2 = plot(xCurrent,yCurrent,'o','MarkerFaceColor','red');
xlabel("x (m)")
ylabel("y (m)")
xlim([xCurrent-wShowMeter/2 xCurrent+wShowMeter/2])
ylim([yCurrent-hShowMeter/2 yCurrent+hShowMeter/2])
ax2.TickDir = "in";

ax3 = subplot(2,2,[3,4]);
plot(tableResult.("Time (s)"),tableResult.("Ground Speed (km/h)"))
hold on
p3 = plot(tableResult.("Time (s)")(1),tableResult.("Ground Speed (km/h)")(1), ...
    'o','MarkerFaceColor','red');
xl3 = xline(tableResult.("Time (s)")(1),"red");

hold off
% f.Visible = "on";
cdata = print(f,"-RGBImage","-r150");
writeVideo(vOut,cdata);
for i = progress(2:length(listFrame),"UpdateRate",2)
    frame = read(v,listFrame(i));
    frameTrimmed = irvtUtils.trimImg(frame,hShowPx,wShowPx);
    im1.CData = frameTrimmed;

    xCurrent = tableResult.("X (m)")(i);
    yCurrent = -tableResult.("Y (m)")(i);
    p2.XData = xCurrent;
    p2.YData = yCurrent;
    ax2.XLim = [xCurrent-wShowMeter/2 xCurrent+wShowMeter/2];
    ax2.YLim = [yCurrent-hShowMeter/2 yCurrent+hShowMeter/2];

    p3.XData = tableResult.("Time (s)")(i);
    p3.YData = tableResult.("Ground Speed (km/h)")(i);
    xl3.Value = tableResult.("Time (s)")(i);

    drawnow
    cdata = print(f,"-RGBImage","-r150");
    writeVideo(vOut,cdata);
end
close(vOut);
