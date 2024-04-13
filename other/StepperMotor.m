clear; % Clears all variables from current workspace
clc; % Clears all text from the command line window

clear s;
s = serialport('COM3', 9600);
pause(2);

dist = 420;
write(s, int2str(dist), 'string');

%{
a = arduino(); % Constructs Arduino

stepsPerRevolution = 2048; % Steps per revolution of stepper motor

% Indicates variables used for stepper motor
thisStepper = StepperRevA(a,stepsPerRevolution,'D8', 'D9','D10','D11');

fprintf("Moving clockwise.\n");
tic;
MoveClockWise(thisStepper, 100, stepsPerRevolution / 4); % Moves stepper motor clockwise
fprintf("Finished moving clockwise in %.3f seconds.\n", toc);

fprintf("Moving counterclockwise\n");
tic;
MoveCounterClockWise(thisStepper, 100, stepsPerRevolution / 4); % Moves stepper motor counterclockwise
fprintf("Finished moving counterclockwise in %.3f seconds.\n", toc);

disp('Program is done.');
%}
