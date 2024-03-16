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

stepsPerRevolution = 2048; % Stepper steps per 1 revolution

cam = webcam(camList(webcamNum)); % Constructs a webcam object

a = arduino(); % Initializes the Arduino

% Setup a stepper with the following pins
thisStepper = StepperRevA(a, stepsPerRevolution, 'D4', 'D5', 'D6', 'D7');

% Initialize a servo with Pin 3
s = servo(a, 'D3', 'MinPulseDuration', 700*10^-6, 'MaxPulseDuration', 2300*10^-6);

ranFromWaterSamplerScript = true; % Verifies app was ran from script

GUI_BuildGUI; % Opens the app
