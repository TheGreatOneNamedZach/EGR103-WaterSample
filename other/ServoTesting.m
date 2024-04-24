clear;
clc;

fprintf("Init... (1/4)\n");
a=arduino();
s1 = servo(a, 'D3', 'MinPulseDuration', 700*10^-6, 'MaxPulseDuration', 2300*10^-6);
fprintf("Init... (2/4)\n");
global servo_position
servo_position = 0.30;
fprintf("Init... (3/4)\n");
global servo_frequency; % Seconds to wait to push
servo_frequency = 1.000;
fprintf("Init... (4/4)\n");
global stopRequested;
stopRequested = false;
fprintf("Init complete.\n");

fprintf("Running while loop...\n")
while (~stopRequested)
    writePosition(s1, servo_position);
    pause(servo_frequency);
end
fprintf("Complete.\n");

function stop()
    fprintf("Stop requested...\n");
    global stopRequested;
    stopRequested = true;
end

function rotate(percent)
    fprintf("Set position to " + percent + "...");
    global servo_position;
    servo_position = percent;
end
