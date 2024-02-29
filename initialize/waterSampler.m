% The primary parent script for the water sample project.
close all;
clear;
clc;

camList = string(webcamlist); % Creates a list of all valid cameras
camList(2) = "Dummy Webcam";

webcamNum = 99; % The webcam index number choosen by the user. Dummy value of 99
% Loops until the user chooses a valid webcam
while (webcamNum > length(camList)) || (webcamNum < 0)
    % These 4 lines are rerun to update the list of webcams
    clear;
    clc;
    camList = string(webcamlist);
    % camList(2) = "Dummy Webcam";

    fprintf("Please select a webcam:\n");
    
    % Displays a list of all webcams to terminal
    for i=1 : length(camList)
        fprintf("%2.0f.) %s\n", i, camList(i));
    end
    
    webcamNum = floor(input("Select the webcam by entering it's number: "));
end

cam = webcam(camList(webcamNum)); % Constructs a webcam object
img = snapshot(cam); % Gets a snapshot of the camera
imgSize = size(img); % Gets the size of the image from the camera

runtime_s = 15; % Time to run the script for.

stopSafe = false;
stopNow = false;

% Constructs the uifigure to display everything
wS_GUI = uifigure("Name","Water Sampler", "Icon","other/WaterDrop.png");
wS_GUI.Position(3:4) = [imgSize(2), imgSize(1)]; % Expands the figure to fit everything
wS_GUI.WindowState = 'maximized'; % Maximizes the uifigure window

ax = uiaxes(wS_GUI, 'Position', [0, 0, imgSize(2), imgSize(1)]); % Constructs camera image
% btn = uibutton(fig, 'push', 'Text', 'Stop', 'Position', [100, 100, 100, 30]);
% btn.ButtonPushedFcn = @(~, ~) appStart(stopSafe);

tic; % Declares timer and starts it.

while (toc <= runtime_s) && (~stopSafe && ~stopNow)
    % Keeps taking an image for the remainder of runtime_s
    img = snapshot(cam);
    
    imshow(img, 'Parent', ax); % Updates the uifigure
    pause(0.1);
end