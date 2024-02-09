% Wildzach - An AprilTag image detection script.
% Author(s):  Zachary Bratten
% Assignment: EGR 101-005 Week 14; Final Project
% Changed:    November 28th, 2023
% Purpose:
%   This script can detect AprilTags using image detection and machine
%   learning. I chose this for my project because machine learning will
%   play a major role in my career going forward. Whether I work on AI or
%   research brain-machine interfaces, I will use machine learning as a
%   computer scientist.
% 
% Additional Notes:
%   This script is made possible by the power of blood, sweat, and tears.
% 
%   Make sure the AprilTag is upright! Else, the tracking is off.
%   Make sure that the AprilTag is not even slightly obstructed!
% 
%   This is by far the most complicated code I have ever written in MATLAB.
%   Even though I have taken steps against it, this script will probably
%   not work on devices other than mine.
% 
%   P.S. MATLAB stores pixel coordinates for images as (y, x).
%   Who does that?
% 
% 
% 
%   _____              _                       _    _                 
%  |_   _|            | |                     | |  (_)                
%    | |   _ __   ___ | |_  _ __  _   _   ___ | |_  _   ___   _ __   ___ 
%    | |  | '_ \ / __|| __|| '__|| | | | / __|| __|| | / _ \ | '_ \ / __|
%   _| |_ | | | \\__ \\ |_ | |   | |_| || (__ | |_ | || (_) || | | \\__ \
%  |_____||_| |_||___/ \__||_|    \__,_| \___| \__||_| \___/ |_| |_||___/
% 
% YOUTUBE VIDEO: https://youtu.be/Vck66jXTtSQ
% 
% 1.) Print out the AprilTags:
% https://drive.google.com/file/d/1PkqGuDfVzx3a7IQNXvlJt00seDHg3iqa/view
% 
% 2.) Download the project folder in MATLAB's working directory.
%   (Basically, don't put this project's folder "Wildzach" inside
%   another folder inside MATLAB)
%
% 3.) Add the "Wildzach" folder and subfolders to MATLAB's path
% 
% 4.) Install all the requirements (listed after the instructions)
%
% 5.) Run the script and choose a webcam.
%
% 6.) Hold up the AprilTag to the webcam until the battery aligns with the
%   AprilTag. 
% 
% 7.) Move the AprilTag to move the battery. Move the battery into the
%   battery holder to power the TV (and see the answer to the question
%   above the AprilTag). If the battery is too big/small, move the AprilTag
%   closer or farther from the webcam.
% 
% 8.) Each AprilTag has a different question and answer. The 6th AprilTag
%   is the roadmap.
% 
% 9.) The script will automatically shut off after ten minutes. Using the
%   keybind Ctrl + C in MATLAB will terminate the script.
%
%
% Requirements:
%   MATLAB R2023b or higher
%   Computer Vision Toolbox v23.2 or higher
%   Image Processing Toolbox v23.2 or higher
%   MATLAB Support Package for USB Webcams v23.2.0 or higher
% 



% Link start!
clear; % Clears the workspace
clc; % Clears the terminal

% Define variables here
webcamNum = 99; % The webcam index number choosen by the user. Dummy value of 99

% If you remove the coconut image, the script will crash.
% (If you get the meme, thats awesome)
% (Makes sure the user properly imported the script folder)
if ~isfile("Wildzach\Coconut\coconut.jpg")
    fprintf(2, "Wildzach is not properly imported.\n");
    fprintf(1, "You can view the instructions for importation\n" + ...
               "By running 'help Wildzach'\n");
    return; % Terminates itself
end

camList = string(webcamlist); % Creates a list of all valid cameras
camList(2) = "Dummy Webcam";

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

% I don't know why, but these variables MUST be defined here
elapsedFPS = 0; % FPS that the detector has run for
runtime_s = 1800; % Runtime of detector in seconds
fps = 60; % FPS to run the detector at. Will be limited to webcam FPS

camImage = imshow(snapshot(cam)); % Constructs initial Figure to display images
aTag_Img = camImage; % Adds initial image (incase no AprilTag is found)
aTagCenterLast = [0, 0];
aTagSizeLast = size(snapshot(cam));
aTagIDLast = -1;

tic; % Starts ElapsedTime

% Until the detector has ran for the wanted time...
while toc <= (runtime_s)
    pause(1 / fps); % Waits for one frame

    currentImg = snapshot(cam); % Saves the current frame to an array

     % Finds AprilTag locations
    [outputImageATag, aTagCenter, aTagSize, aTagID] = findAprilTags(currentImg, aTagCenterLast, aTagSizeLast);

    if (aTagID ~= -1)
        aTagIDLast = aTagID;
    end

    outputImageTV = addBackground(outputImageATag); % Adds TV

    outputImageScreen = addScreen(outputImageTV, aTagCenter, aTagIDLast); % Adds answers

    outputImageBattery = addBattery(outputImageScreen, aTagCenter, aTagSize, aTagIDLast); % Adds battery

    imshow(outputImageBattery);

    aTagCenterLast = aTagCenter;
    aTagSizeLast = aTagSize;
    elapsedFPS = elapsedFPS + 1;
end

stopScript();

%{

███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
█████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

%}

% Finds all AprilTags within the given image
function [outputImage, aTagCenter, aTagSize, aTagID] = findAprilTags(inputImage, aTagCenterLast, aTagSizeLast)
    % Finds all AprilTags within the frame
    [aTag_ID, aTag_loc] = readAprilTag(inputImage, "tag36h11");
    % aTag_loc
    % Bottom Left Y, Bottom Left X
    % Bottom Right Y, Bottom Right X
    % Top Right Y, Top Right X
    % Top Left Y, Top Left X
    
    if ~isempty(aTag_ID)

        % https://www.mathworks.com/help/vision/ref/readapriltag.html
        for i=1 : length(aTag_ID)
            % Display the ID and tag family
            % fprintf("Detected Tag! ID: %.0f\n", aTag_ID(i));
     
            % Insert markers to indicate the corners of the AprilTags
            markerRadius = 8;
            numCorners = size(aTag_loc,1);
            markerPosition = [aTag_loc(:,:,i),repmat(markerRadius,numCorners,1)];
            aTag_Img = inputImage;
            aTag_Img = insertShape(aTag_Img,"FilledCircle",markerPosition,ShapeColor="red",Opacity=1);

            % Finds the center (y, x) coordinate of the AprilTag
            aTagCenter = [
                round(abs((aTag_loc(2,2) - aTag_loc(4,2)) / 2) + aTag_loc(4,2)), ...
                round(abs((aTag_loc(2,1) - aTag_loc(4,1)) / 2) + aTag_loc(4,1))];
            
            % Finds the size of the AprilTag
            % The AprilTag can never have a size of 0.
            aTagSize = [
                max(round(abs((aTag_loc(2,2) - aTag_loc(4,2)))),1), ...
                max(round(abs((aTag_loc(2,1) - aTag_loc(4,1)))),1)];
        end
        outputImage = aTag_Img;
        aTagID = aTag_ID(1);
    else
        % If no AprilTag is found, it uses the last found values.
        outputImage = inputImage;
        aTagCenter = aTagCenterLast;
        aTagSize = aTagSizeLast;
        aTagID = -1;
    end
end

% Transposes the battery onto the AprilTag
function [outputImage] = addBattery(inputImage, aTagCenter, aTagSize, aTagIDLast)
    % Imports Battery image
    switch aTagIDLast
        case 1
            batteryImage = "Wildzach\Battery\Battery1.png";
        case 2
            batteryImage = "Wildzach\Battery\Battery2.png";
        case 3
            batteryImage = "Wildzach\Battery\Battery3.png";
        case 4
            batteryImage = "Wildzach\Battery\Battery4.png";
        case 5
            batteryImage = "Wildzach\Battery\Battery5.png";
        otherwise
            batteryImage = "Wildzach\Battery\Battery0.png";
    end

    [batteryPNG,~,batteryPNGAlpha] = imread(batteryImage);

    % Finds y and x size of image
    inputImageSize = size(inputImage);
    batterySize = size(batteryPNG);

    % Resizes the Battery to the size of the AprilTag
    imageScale = aTagSize(1) / batterySize(2);
    batteryPNG = imresize(batteryPNG, imageScale, 'nearest');
    batteryPNGAlpha = imresize(batteryPNGAlpha, imageScale, 'nearest');
    batterySize = size(batteryPNG); % Finds new size

    % Finds the top left corner position to place image.
    % The entire image of the battery WILL ALWAYS be inside the frame.
    % First, it finds the theoretical (y, x) for the top corner.
    % Then, it shifts the corner to the nearest actual value.
    batteryCorner = [
        min(max(aTagCenter(1) - round(batterySize(1) / 2), 1), (inputImageSize(1) - batterySize(1))), ...
        min(max(aTagCenter(2) - round(batterySize(2) / 2), 1), (inputImageSize(2) - batterySize(2)))];

    outputImage = transCal(batteryPNG, batteryPNGAlpha, inputImage, batteryCorner(1), batteryCorner(2));
end

% Transposes the background onto an image
function [outputImage] = addBackground(inputImage)
    [TVPNG,~,TVPNGAlpha] = imread("Wildzach\TV\TV.png");
    outputImage = transCal(TVPNG, TVPNGAlpha, inputImage, 1, 1);
end

function [outputImage] = addScreen(inputImage, aTagCenter, aTagIDLast)
% Only displays the image when a battery is over the battery holder
    if ((aTagCenter(1) < 545) || (aTagCenter(1) > 650) && ...
       (aTagCenter(2) < 878) || (aTagCenter(2) > 1050))
        outputImage = inputImage;
        return;
    end
    switch aTagIDLast
        case 0
            screenAnswer = "Wildzach\Answers\Answer0.png";
        case 1
            screenAnswer = "Wildzach\Answers\Answer1.png";
        case 2
            screenAnswer = "Wildzach\Answers\Answer2.png";
        case 3
            screenAnswer = "Wildzach\Answers\Answer3.png";
        case 4
            screenAnswer = "Wildzach\Answers\Answer4.png";
        case 5
            screenAnswer = "Wildzach\Answers\Answer5.png";
    end

    screenPNG = imread(screenAnswer);
    screenSize = size(screenPNG);

    tempImage = inputImage;
    y = 184; % Top left coords
    x = 83;

    tempImage( ...
        y : (y + (screenSize(1) - 1)), ...
        x : (x + (screenSize(2) - 1)), ...
        :) = ...
        screenPNG(:, :, :);

    outputImage = tempImage;
end


% Simulates transparency
% Both images are uint8.
% Requires Alpha channel of transparent image.
% Top left y and x coords to place image on.
function [outputImage] = transCal(transImage, alphaChan, bgImage, y, x)
    % Finds the size of the transparent image
    transImageSize = size(transImage);

    % Flips the alpha channel since it is reveresed for some reason
    alphaChan = 255 - alphaChan;

    tempImage = bgImage;

    % Transposes transparent image onto input image
    tempImage( ...
        y : (y + (transImageSize(1) - 1)), ...
        x : (x + (transImageSize(2) - 1)), ...
        :) ...
        = ...
        (1 - alphaChan / 255) .* transImage(:, :, :) + ...
        (alphaChan ./ 255) .* bgImage( ...
        y : (y + (transImageSize(1) - 1)), ...
        x : (x + (transImageSize(2) - 1)), ...
        :);
    outputImage = tempImage;
end

function stopScript()
    clear("cam"); % Safely terminates the webcam construct. (Turns off the webcam)
    close all; % Terminates all figures.
end
