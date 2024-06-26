% The primary parent script for the water sample project.
close all;
clear all;
clc;

camList = string(webcamlist); % Creates a list of all valid cameras

webcamNum = 99; % The webcam index number choosen by the user. Dummy value of 99
% Loops until the user chooses a valid webcam
while (webcamNum > length(camList)) || (webcamNum < 0)
    % These 4 lines are run multiple times to update the list of webcams
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

a = arduino('COM5'); % Initializes the Arduino
%a2 = arduino('COM3', 'Uno');
s = serialport('COM3', 9600);

ranFromWaterSamplerScript = true; % Verifies app was ran from script

waterSamplerGUI; % Opens the app
