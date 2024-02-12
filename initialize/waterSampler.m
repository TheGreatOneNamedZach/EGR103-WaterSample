% The primary parent script for the water sample project.
% 2 hours & 6:00
clear;
clc;

stopSafe = false;
stopNow = false;

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



fig = uifigure("Name","Water Sampler", "Icon","peppers.png");
ax = uiaxes(fig, 'Position', [0, 0, 300, 200]);

while (true)
    %https://www.mathworks.com/help/matlab/ref/matlab.ui.figureappd-properties.html
    img = snapshot(cam);
    
    imshow(img, 'Parent', ax);
    pause(0.1);
end