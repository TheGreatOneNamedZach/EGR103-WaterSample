clear; % Clears the workspace
clc; % Clears the command window/terminal
close all; % Closes all open Figures

% Creates an 3D array to hold the image.
% Every pixel (first two dimensions) and their RGB values (the third dimension)
imgRGB_arr = imread("EGR103_WaterSample\other\Cyan_Pink_Stickers.jpg");

% Converts the image from RGB to HSV
imgHSV_arr = rgb2hsv(imgRGB_arr);

% Limits the image to Hues between 324 degrees and 342 degrees
% OR (it does both)
% Limits the image to Hues between 162 degrees and 189 degrees
imgHSV_arr = (...
    (imgHSV_arr(:,:,1) >= 0.9) & (imgHSV_arr(:,:,1) <= 0.95) | ...
    (imgHSV_arr(:,:,1) >= 0.45) & (imgHSV_arr(:,:,1) <= 0.525));

% You can get a Hue value from RGB here
% https://www.rapidtables.com/convert/color/rgb-to-hsv.html
% Take the hue value in degrees and divide by 360. Use that.

% Finds the area of every white "blob" in the image.
% If the area is less than 75 000 square pixels, they turn black.
imgHSV_arr = bwareaopen(imgHSV_arr, 75000);

% Makes a bounding box array. It also finds all boxes to bind
imgBB_arr = regionprops('table', imgHSV_arr, 'BoundingBox');
imgBB_arr = imgBB_arr{:,:}; % Converts to an array

% Creates a figure
figure, imshow(imgRGB_arr), title('Bounding Box Around Colored Squares')

% Declares that all figure modification from now on is for ONLY
% the last figure called
hold on

% Cycles through every row in the bounding box array
for k=1 : size(imgBB_arr,1)

    % Stores the current bounding box dimensions in an array
    currentBB_arr = imgBB_arr(k,:);

    % Draws a rectangle for the current bounding box
    rectangle('Position', currentBB_arr, 'EdgeColor', 'r', 'LineWidth', 2)
end

% Declares that all figure modification from now on is RELATIVE
% to the last figure called
hold off
