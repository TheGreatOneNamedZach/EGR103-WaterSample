%{
██████╗  ██████╗  ███████╗ ██╗   ██╗ ██╗ ███████╗ ██╗    ██╗
██╔══██╗ ██╔══██╗ ██╔════╝ ██║   ██║ ██║ ██╔════╝ ██║    ██║
██████╔╝ ██████╔╝ █████╗   ██║   ██║ ██║ █████╗   ██║ █╗ ██║
██╔═══╝  ██╔══██╗ ██╔══╝   ╚██╗ ██╔╝ ██║ ██╔══╝   ██║███╗██║
██║      ██║  ██║ ███████╗  ╚████╔╝  ██║ ███████╗ ╚███╔███╔╝
╚═╝      ╚═╝  ╚═╝ ╚══════╝   ╚═══╝   ╚═╝ ╚══════╝  ╚══╝╚══╝ 

This script is a PREVIEW ONLY and should not be run.
This script is a preview of "waterSamplerGUI.mlapp"
%}





%classdef waterSamplerGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainMenu     matlab.ui.Figure
        GridLayout   matlab.ui.container.GridLayout
        Image        matlab.ui.control.Image
        LogsText     matlab.ui.control.TextArea
        LogsPanel    matlab.ui.container.Panel
        WebcamPanel  matlab.ui.container.Panel
        StopButton   matlab.ui.control.Button
        SCRAMButton  matlab.ui.control.Button
        StartButton  matlab.ui.control.Button
    end

    properties (Access = public)
        % Declare null variables here
        a; % Will eventually construct the Arduino
        a2;
        s;
        cam; % Will eventually construct the webcam
        ranFromWaterSamplerScript; % Verifies app was run from script
        centralTimer; % Total time lapsed since "Start" pressed
        internalTimer; % Total time lapsed since last action ended
        outputImage; % Output image for AprilTag detection
        aTagCenter; % Output center locations for AprilTags
        aTagSize; % Output AprilTag sizes
        aTagID; % Output AprilTag ID
        pipetteServo; % Pipette Servo

        % Declare variables here
        stopRequested = false; % When "Stop" is pressed
        wS_State = "Stopped"; % Current state of the Water Sampler
        action = 0; % Current action being executed
        stepper_stepsPerRev = 2048; % Steps per revolution for stepper
        rotationalTravel = 0; % Distance traveled from home
        liftTravel = 0;
        rotationalStepper_pin1 = 'D8';
        rotationalStepper_pin2 = 'D9';
        rotationalStepper_pin3 = 'D10';
        rotationalStepper_pin4 = 'D11';
        pipetteServo_pin = 'D2'; % Pin for pipette servo
        liftStepper_pin1 = 'D7';
        liftStepper_pin2 = 'D8';
        liftStepper_pin3 = 'D12';
        liftStepper_pin4 = 'D13';
        visionUseRGB = true; % Should we use RGB in place of HSV?
        visionPipette_Detected = false; % Did the vision system detect something?
        visionPipette_Distance = 0; % How far the pipette needs to move
        visionPipette_BBLocation = -1;
        visionColor_Detected = false; % Did the vision system detect something?
        visionColor_Hue = 0; % Hue of sample
        visionOCR_Detected = false; % Did the vision system detect something?
        visionOCR_Label = ""; % The OCR label it detected
        pipetteServo_home = 0.30; % Home position for servo
    end

    methods (Access = private)
        
        % A GUIDE TO LOG CODES.
        % (C)   -  This means the timestamp is based on the time elapsed
        %          since the "Start" button was pressed.
        % 
        % (I)   -  This means the timestamp is based on the time elapsed
        %          since the last action ended.
        % 
        % USER  -  This means the USER did something. Any action taken by
        %          the user is logged under this code.
        % 
        % EVNT  -  This means an EVENT was logged. Events are processes
        %          automatatically started by the water sampler.
        % 
        % INFO  -  This means INFOrmation was output by the water sampler.
        %          This is usually required (by the assignment) to be output.
        %
        % WARN  -  This means the water sampler wants to WARN the user.
        %          Usually, suspicious information warrents a warning.
        % 
        % ERR   -  This means an known ERRor occured. An error log was
        %          output to help diagnose the issue.
        % 

        % Sends a log to the log GUI area with the Central Timer
        function wS_LogCentral(app, level, message)
            app.LogsText.Value = [sprintf("(C) %7.3f - [%s] %s", toc(app.centralTimer), level, message); app.LogsText.Value];
        end

        % Sends a log to the log GUI area with
        % Distance and speed the sub-system was requested to run
        % Current elapsed time of Internal Timer
        function wS_LogAction(app, distance, speed, system)
            app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] %s system operating. Distance: %.2f. Speed: %.2f.", toc(app.internalTimer), system, distance, speed); app.LogsText.Value];
        end

        % The code for the vision sub-system to detect the distance
        %   between the pipette and the waste
        % app - passes in the app object for use of variables
        % visionPipette_Detected - Was anything detected?
        % visionPipette_Distance - What is the distance to travel?
        function wS_VisionDistance(app)
            % Logs that the vision system started.
            app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system operating. Calculating pipette distance...", toc(app.internalTimer)); app.LogsText.Value];

            app.Image.ImageSource = snapshot (app.cam);
            % VISION CODE GOES HERE
            %inch to cm ratio
            inch_to_cm = 2.54;
            pixels= 0;
            
            %position of the waste and the pipe
            waste_position = 0;
            pipe_position = 0;
            
            
            %One pixel to cm
            pixel_to_distance = 2.54 / app.aTagSize(2);
            app.visionUseRGB = false;
            detected_pipe = false; 
            detected_waste = false;
            app.visionPipette_Detected = false;
            
            %image to process
            %image = imread(img);
            imtool(app.Image.ImageSource);
            
            %
            if(app.visionUseRGB)
                waste_threshholdn_value = 20;
                pipe_threshholdn_value = 275;
           
                red_color=app.Image.ImageSource(:,:,1);
                green_color=app.Image.ImageSource(:,:,2);
                blue_color=app.Image.ImageSource(:,:,3);
                red_blue_diff = double(red_color)-double(blue_color);
                red_green_diff = double(red_color)-double(green_color);
                blue_green_diff = double(blue_color)-double(green_color);
                red_blue_ratio = double(red_color)/double(blue_color);
                red_green_rato = double(red_color)/double(green_color);
                blue_green_ratio = double(blue_color)/double(green_color);
                
                waste= (red_color <= waste_threshholdn_value);
                pipe = (green_color >= pipe_threshholdn_value);
            else
                waste_threshholdn_value = 0.25;
                
                %initialize all value
                imgHSV_arr = rgb2hsv(app.Image.ImageSource);
                imgHSV_color =  imgHSV_arr(:,:,1);
                imgHSV_brightness = imgHSV_arr(:,:,3);
            
                %check the waste using brightness value
                waste= (imgHSV_brightness <= waste_threshholdn_value);
                %check the pipe using color value
                pipe = (imgHSV_color <= (150/360)& imgHSV_color >= (75/360));
            end
            
            
            % find and locate the waste
            waste_bw = bwareaopen(waste,1000); 
            waste_bw(1:200, :, :) = 0;
            imshow(waste_bw);
            %app.Image.ImageSource = repmat(waste_bw, [1, 1, 3]);
            Bounding_Boxes1 = regionprops('table',waste_bw, 'BoundingBox'); 
            Bounding_Boxes1 = Bounding_Boxes1{:,:}; 
            figure, imshow(app.Image.ImageSource);
            
            %if waste detecteed
            for k = 1:size(Bounding_Boxes1,1) 
                detected_waste = true;
            end
            
            % find and locate the pipe
            pipe_bw = bwareaopen(pipe,1000); 
            imshow(pipe_bw);
            %app.Image.ImageSource = repmat(pipe_bw, [1, 1, 3]);
            Bounding_Boxes2 = regionprops('table',pipe_bw, 'BoundingBox'); 
            Bounding_Boxes2 = Bounding_Boxes2{:,:}; 
            %figure, imshow(app.Image.ImageSource);
            
            %if pipe detected 
            for k = 1:size(Bounding_Boxes2,1) 
                detected_pipe = true;
            end
            
            
            %check if anything is detected
            if(detected_pipe && detected_waste)
                app.visionPipette_Detected = true;
                app.visionPipette_Distance = pixel_to_distance * (Bounding_Boxes1(2)  - (Bounding_Boxes2(2)+ Bounding_Boxes2(4)));
            end
            
            % Logs if the vision system detected something.
            % Also logs what the pipette distance will be
            if(app.visionPipette_Detected)
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system calculated a pipette distance of %.2f", toc(app.internalTimer), app.visionPipette_Distance); app.LogsText.Value];
            else
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system could not calculate a pipette distance. Fall back distance: %.2f", toc(app.internalTimer), app.visionPipette_Distance); app.LogsText.Value];
            end

            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "Pipette distance is: " + app.visionPipette_Distance);
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
        end

        % The code for the vision sub-system to detect the hue
        %   of the sample
        % app - passes in the app object for use of variables
        % visionColor_Detected - Was anything detected?
        % visionColor_Hue - What is the distance to travel?
        function wS_VisionColor(app)
            % Logs that the vision system started.
            app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system operating. Calculating sample color...", toc(app.internalTimer)); app.LogsText.Value];

            app.Image.ImageSource = snapshot(app.cam);

            % VISION CODE GOES HERE

            red_color=app.Image.ImageSource(:,:,1);

            app.visionColor_Hue = red_color(app.visionPipette_BBLocation(1)-25, app.visionPipette_BBLocation(2)+25);
            app.visionColor_Detected = true;
            
            % Logs if the vision system detected something.
            % Also logs what the pipette distance will be
            if(app.visionPipette_Detected)
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system calculated a sample color of %.2f", toc(app.internalTimer), app.visionColor_Hue); app.LogsText.Value];
            else
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system could not calculate a sample color. Fall back color: %.2f", toc(app.internalTimer), app.visionColor_Hue); app.LogsText.Value];
            end

            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "Sample color is: " + app.visionColor_Hue);
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
        end

        % The code for the vision sub-system to detect the OCR label
        % app - passes in the app object for use of variables
        % visionOCR_Detected - Was anything detected?
        % visionOCR_Label - The label detected
        function wS_VisionOCR(app)
            % Logs that the vision system started.
            app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system operating. Calculating OCR label...", toc(app.internalTimer)); app.LogsText.Value];

            picture = snapshot(app.cam);
            
            % VISION CODE GOES HERE

            %read text in the image
            ocrResults = ocr(app.Image.ImageSource);
            app.visionOCR_Label = ocrResults.Text;

            % TODO: If no label is detected, DO NOT return a label.
            %   This is so we can use the last label detected (if any).




            % Logs if the vision system detected something.
            % Also logs what the OCR label will be
            if(app.visionOCR_Detected)
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system detected an OCR label of '%s'", toc(app.internalTimer), app.visionOCR_Label); app.LogsText.Value];
            else
                app.LogsText.Value = [sprintf("(I) %7.3f - [EVNT] Vision system could not detect an OCR label. Fall back label is '%s'", toc(app.internalTimer), app.visionOCR_Label); app.LogsText.Value];
            end

            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "OCR label is: " + app.visionOCR_Label);
            wS_LogCentral(app, "INFO", " ");
            wS_LogCentral(app, "INFO", "------------------------------------");
            wS_LogCentral(app, "INFO", " ");
        end

        function findAprilTags(app, inputImage, aTagCenterLast, aTagSizeLast)
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
                    app.aTagCenter = [
                        round(abs((aTag_loc(2,2) - aTag_loc(4,2)) / 2) + aTag_loc(4,2)), ...
                        round(abs((aTag_loc(2,1) - aTag_loc(4,1)) / 2) + aTag_loc(4,1))];
                    
                    % Finds the size of the AprilTag
                    % The AprilTag can never have a size of 0.
                    app.aTagSize = [
                        max(round(abs((aTag_loc(2,2) - aTag_loc(4,2)))),1), ...
                        max(round(abs((aTag_loc(2,1) - aTag_loc(4,1)))),1)];
                end
                wS_LogCentral(app, "INFO", "Size is: " + app.aTagSize(1) + ", " + app.aTagSize(2));
                app.outputImage = aTag_Img;
                app.aTagID = aTag_ID(1);
            else
                % If no AprilTag is found, it uses the last found values.
                app.outputImage = inputImage;
                app.aTagCenter = aTagCenterLast;
                app.aTagSize = aTagSizeLast;
                app.aTagID = -1;
                try
                    wS_LogCentral(app, "INFO", "No AprilTag found. Defaulting to an ID of " + app.aTagID + " with a size of (" + app.aTagSize(1) + ", " + app.aTagSize(2) + ")");
                catch ignored
                    wS_LogCentral(app, "INFO", "No AprilTag found. Values possibly null.");
                end
            end
        end
        
        % The code for the rotational base sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to rotate clockwise IN DEGREES
        % speed - the speed at which to travel (1.00 = 100% power)
        function wS_Rotational(app, distance, speed)
            if (app.wS_State == "SCRAM")
                return;
            end

            % Logs that the rotational base system was told to move.
            wS_LogAction(app, distance, speed, "Rotational");

            steps = stepper_degreesToRev(app, ((distance/360) * 972));
            %rotateStepper(app, app.a2, steps, speed, app.rotationalStepper_pin1, app.rotationalStepper_pin2, app.rotationalStepper_pin3, app.rotationalStepper_pin4);
            write(app.s, int2str(steps), 'string');
            pause((((distance/360)*((972/360)*60)/10))+3);
            app.rotationalTravel = app.rotationalTravel + distance; % Distance traveled
        end

        % The code for the pipette sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to move towards the pipette
        % speed - the speed at which to travel (1.00 = 100% power)
        function wS_Pipette(app, distance, speed)
            if (app.wS_State == "SCRAM")
                return;
            end

            % Logs that the pipette system was told to move.
            wS_LogAction(app, distance, speed, "Pipette");

            writePosition(app.pipetteServo, distance);
        end

        % The code for the rotational base sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to travel upwards
        % speed - the speed at which to travel (1.00 = 100% power)
        function wS_Lift(app, distance, speed)
            if (app.wS_State == "SCRAM")
                return;
            end

            % Logs that the lift system was told to move.
            wS_LogAction(app, distance, speed, "Lift");

            radius = 2.00; % radius of interior spool in cm
            circumference = 2 * pi * radius;
            steps = stepper_degreesToRev(app, ((distance/circumference) * 360));
            rotateStepper(app, app.a, steps, speed, app.liftStepper_pin1, app.liftStepper_pin2, app.liftStepper_pin3, app.liftStepper_pin4);
            app.liftTravel = app.liftTravel + steps;
        end

        % Converts degrees into steps for stepper motor
        % app - passes in the app object for use of variables
        % degrees - inputed degrees
        % steps - outputed steps
        function steps = stepper_degreesToRev(app, degrees)
            steps = ((degrees/360) * app.stepper_stepsPerRev);
        end

        function rotateStepper(app, arduino, steps, speed, pin1, pin2, pin3, pin4)
            if(steps~=0)

                % Compute the speed - This is 'adjusted' to accomodate lag
                StepsPerSecond = (1/4) * steps * speed;
                %Invert it
                SecondsPerStep = 1/StepsPerSecond;

                % Ensure all outputs are off
                writeDigitalPin(arduino, pin1, 0);
                writeDigitalPin(arduino, pin2, 0);
                writeDigitalPin(arduino, pin3, 0);
                writeDigitalPin(arduino, pin4, 0);

                if (steps > 0)
                    % Clockwise

                    for index = 1:(steps/4)
                        if (app.wS_State == "SCRAM")
                            return;
                        end
                        writeDigitalPin(arduino, pin1, 1);
                        writeDigitalPin(arduino, pin4, 0);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin1, 0);
                        writeDigitalPin(arduino, pin2, 1);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin2, 0);
                        writeDigitalPin(arduino, pin3, 1);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin3, 0);
                        writeDigitalPin(arduino, pin4, 1);
                        pause(SecondsPerStep/4);
                    end
                else
                    % Counterclockwise
                    steps = abs(steps);

                    for index = 1:(steps/4)
                        if (app.wS_State == "SCRAM")
                            return;
                        end
                        writeDigitalPin(arduino, pin1, 0);
                        writeDigitalPin(arduino, pin4, 1);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin3, 1);
                        writeDigitalPin(arduino, pin4, 0);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin2, 1);
                        writeDigitalPin(arduino, pin3, 0);
                        pause(SecondsPerStep/4);
                        writeDigitalPin(arduino, pin1, 1);
                        writeDigitalPin(arduino, pin2, 0);
                        pause(SecondsPerStep/4);
                    end
                end

                % Leave all the motor coils de-energized when finished
                writeDigitalPin(arduino, pin1, 0);
                writeDigitalPin(arduino, pin2, 0);
                writeDigitalPin(arduino, pin3, 0);
                writeDigitalPin(arduino, pin4, 0); 
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.centralTimer = tic; % Starts the timer

            % Changes the button colors to default
            app.StartButton.BackgroundColor = [0.39, 0.83, 0.07];
            app.SCRAMButton.BackgroundColor = [1.00, 0.00, 0.00];
            app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];

            % Tries to evaluate a variable in the workspace
            try
                app.ranFromWaterSamplerScript = evalin("base", "ranFromWaterSamplerScript");
            catch exception
                % If it fails, the app was not run from the script.
                % Nicely rethrows the exception
                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_LogCentral(app, "ERR", "GUI ran without script. Run the script 'waterSampler.m' instead.");
                rethrow(exception);
            end

            try
                % Evaluates the value of the variable called "cam" in the workspace.
                % Then, assigns that value to app.cam
                % It does this for every variable below...

                app.cam = evalin("base", "cam");
                app.a = evalin("base", "a");
                %app.a2 = evalin("base", "a2");
                app.s = evalin("base", "s");
            catch exception
                % If one of them fails, it logs it in the app

                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_LogCentral(app, "ERR", "Failed to evaluate one or more variables from Workshop. (Do they exist before evaluation?)");
                rethrow(exception);
            end

            % Configure Stepper pins
            
            try

                % Rotational base
                %{
                configurePin(app.a, app.rotationalStepper_pin1, 'DigitalOutput');
                configurePin(app.a, app.rotationalStepper_pin2, 'DigitalOutput');
                configurePin(app.a, app.rotationalStepper_pin3, 'DigitalOutput');
                configurePin(app.a, app.rotationalStepper_pin4, 'DigitalOutput');
                %}
    
                % Lift with Stand
                configurePin(app.a, app.liftStepper_pin1, 'DigitalOutput');
                configurePin(app.a, app.liftStepper_pin2, 'DigitalOutput');
                configurePin(app.a, app.liftStepper_pin3, 'DigitalOutput');
                configurePin(app.a, app.liftStepper_pin4, 'DigitalOutput');
            catch exception

                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_LogCentral(app, "ERR", "Failed to configure Stepper pins. (Are they plugged in?)");
                rethrow(exception);
            end
            
            % Trys to initalize the servos
            try
                app.pipetteServo = servo(app.a, app.pipetteServo_pin, 'MinPulseDuration', 700*10^-6, 'MaxPulseDuration', 2300*10^-6);
                writePosition(app.pipetteServo, app.pipetteServo_home);
            catch exception

                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_LogCentral(app, "ERR", "Failed to initialize a servo. (Are they plugged in?)");
                rethrow(exception);
            end

        end

        % Button pushed function: StartButton
        function StartButtonPushed(app, event)
            if ~(app.wS_State == "Started")
                app.wS_State = "Started"; % If not already, then do so

                % Sets the background color to dark green
                app.GridLayout.BackgroundColor = [0.00, 0.72, 0.00];
                % Sets the button colors to normal & pressed for "Start"
                app.StartButton.BackgroundColor = [0.47, 0.47, 0.47];
                app.SCRAMButton.BackgroundColor = [1.00, 0.00, 0.00];
                app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];
    
                wS_LogCentral(app, "USER", "Starting the water sampler...");

                wS_LogCentral(app, "EVNT", "Restarting the timer...");
                app.centralTimer = tic; % Restarts the Central Timer
    
                app.internalTimer = tic; % Restarts the Internal Timer
                app.action = app.action + 1; % app.action++;

                % Tries to run the while loop
                try
                    while ((~app.stopRequested) && (~app.MainMenu.BeingDeleted) && ((toc(app.centralTimer)) < 300) && (app.action < 100))
                        if (app.action == 1)
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            findAprilTags(app, app.Image.ImageSource, app.aTagCenter, app.aTagSize);

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 2) && (toc(app.internalTimer) > 1.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            wS_Rotational(app, 90, 1.00); % Rotate to waste with dye in it

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 3) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);
    
                            wS_VisionDistance(app); % Detect distance to lower lift
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 4) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            % If something seems wrong...
                            if (~app.visionPipette_Detected || (app.visionPipette_Distance < 0))
                                wS_LogCentral(app, "WARN", "Either the pipette was not detected, or the distance is negative.");
                                pause(3.000);
                            end
    
                            wS_Lift(app, app.visionPipette_Distance, 1.00); % Lower the lift
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 5) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);
    
                            wS_Pipette(app, 0.9, 1.00); % Squeeze in
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 6) && (toc(app.internalTimer) > 1.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            wS_Pipette(app, app.pipetteServo_home, 1.00); % Go home (squeeze out)

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 7) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);
    
                            wS_Lift(app, app.visionPipette_Distance * -1, 1.00); % Raises back up
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 8) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);
    
                            wS_Rotational(app, 90, 1.00);
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 9) && (toc(app.internalTimer) > 3.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);
    
                            wS_Pipette(app, 0.9, 1.00); % Squeeze in
    
                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 10) && (toc(app.internalTimer) > 1.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            wS_Pipette(app, app.pipetteServo_home, 1.00); % Go home (squeeze out)

                            wS_LogCentral(app, "INFO", "Waiting two minutes...");

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        elseif ((app.action == 11) && (toc(app.internalTimer) > 120.000))
                            wS_LogCentral(app, "EVNT", "Action " + app.action + " starting...");
                            app.Image.ImageSource = snapshot(app.cam);

                            wS_VisionColor(app);

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        end

                        app.Image.ImageSource = snapshot(app.cam); % Gets a snapshot of the webcam
                        pause(0.100);
                    end
                catch exception
                    % If it crashes, rethrow the exception
                    % UNLESS it is the invalid handle error
                    if ~(strcmp(exception.identifier, "MATLAB:class:InvalidHandle"))
                        rethrow(exception);
                    end
                end
            end
        end

        % Button pushed function: StopButton
        function StopButtonPushed(app, event)
            if ~(app.wS_State == "Stopped")
                app.stopRequested = true; % Declares a request to stop
                pause(1.000); % Waits for the while loop to stop
                app.wS_State = "Stopped"; % If not already, then do so

                % Sets the background color to dark blue
                app.GridLayout.BackgroundColor = [0.00, 0.34, 0.56];

                % Sets the button colors to normal & "Stop" to pressed
                app.StartButton.BackgroundColor = [0.39, 0.83, 0.07];
                app.SCRAMButton.BackgroundColor = [1.00, 0.00, 0.00];
                app.StopButton.BackgroundColor = [0.47, 0.47, 0.47];

                wS_LogCentral(app, "USER", "Stopping the water sampler...");
    
                % Stops the webcam
                wS_LogCentral(app, "EVNT", "Stopping webcam...");
                pause(0.250); % Pause to ensure it does not call a deleted object
                delete(app.cam); % Closes the webcam (turns off the camera)
    
                % Returns motors to home
                wS_LogCentral(app, "EVNT", "Moving motors home...");
                writePosition(app.pipetteServo, app.pipetteServo_home);
                wS_Lift(app, (app.liftTravel * -1), 1.00);
                wS_Rotational(app, (app.rotationalTravel * -1), 1.00);

                wS_LogCentral(app, "EVNT", "Stopping app...");
                pause(3.000);
                delete(app); % Closes the app
            end
        end

        % Button pushed function: SCRAMButton
        function SCRAMButtonPushed(app, event)
            if ~(app.wS_State == "SCRAM")
                app.stopRequested = true; % Declares a request to stop
                app.wS_State = "SCRAM"; % If not already, then do so
                pause(1.000); % Waits for the while loop to stop

                % Tell all motors to stop moving

                % TODO: Write directly to the motors and tell them to move
                % 0 distance. DO NOT CALL THE FUNCTIONS!



                wS_LogCentral(app, "USER", "SCRAMing the water sampler...");

                % Sets the background color to red
                app.GridLayout.BackgroundColor = [0.80, 0.00, 0.00];

                % Sets the button colors to normal & "SCRAM" to pressed
                app.StartButton.BackgroundColor = [0.39, 0.83, 0.07];
                app.SCRAMButton.BackgroundColor = [0.47, 0.47, 0.47];
                app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];
            end
        end

        % Close request function: MainMenu
        function MainMenuCloseRequest(app, event)
            % When the red "X" is pressed, the water sampler returns to
            % a reusable position, then closes.
            if (app.wS_State == "Stopped")
                delete(app); % If already stopped, close the app
            else
                StopButtonPushed(app); % Stop, then close the app
            end
        end

        % Key press function: MainMenu
        function MainMenuKeyPress(app, event)
            % This function executes when a button is PRESSED

            key = event.Key; % Stores the name of the key in a variable

            % Logs the key press to the logs
            wS_LogCentral(app, "USER", "The key '" + key + "' was pressed.");
            
            if (key == "space")
                SCRAMButtonPushed(app, event);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MainMenu and hide until all components are created
            app.MainMenu = uifigure('Visible', 'off');
            app.MainMenu.Color = [0.9412 0.9412 0.9412];
            app.MainMenu.Position = [100 100 640 480];
            app.MainMenu.Name = 'Water Sampler  -  EGR 103-005-005';
            app.MainMenu.Icon = 'WaterDrop.png';
            app.MainMenu.CloseRequestFcn = createCallbackFcn(app, @MainMenuCloseRequest, true);
            app.MainMenu.KeyPressFcn = createCallbackFcn(app, @MainMenuKeyPress, true);
            app.MainMenu.WindowState = 'maximized';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.MainMenu);
            app.GridLayout.ColumnWidth = {'0.33x', '0.25x', '0.25x', '0.25x', '0.33x'};
            app.GridLayout.RowHeight = {'1x', '0.75x', '0.4x', '1x', '1.6x', '1x', '0.4x', '1x'};
            app.GridLayout.ColumnSpacing = 20;
            app.GridLayout.RowSpacing = 20;
            app.GridLayout.Padding = [20 20 20 20];
            app.GridLayout.BackgroundColor = [0 0.3412 0.5608];

            % Create StartButton
            app.StartButton = uibutton(app.GridLayout, 'push');
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);
            app.StartButton.BackgroundColor = [0.3882 0.8314 0.0706];
            app.StartButton.FontName = 'Franklin Gothic Demi';
            app.StartButton.FontSize = 18;
            app.StartButton.Tooltip = {'Starts the water sampler'};
            app.StartButton.Layout.Row = 2;
            app.StartButton.Layout.Column = 2;
            app.StartButton.Text = 'Start';

            % Create SCRAMButton
            app.SCRAMButton = uibutton(app.GridLayout, 'push');
            app.SCRAMButton.ButtonPushedFcn = createCallbackFcn(app, @SCRAMButtonPushed, true);
            app.SCRAMButton.BackgroundColor = [1 0 0];
            app.SCRAMButton.FontName = 'Franklin Gothic Demi';
            app.SCRAMButton.FontSize = 18;
            app.SCRAMButton.FontWeight = 'bold';
            app.SCRAMButton.Tooltip = {'Stops the water sampler instantly without resetting motor positions'};
            app.SCRAMButton.Layout.Row = 2;
            app.SCRAMButton.Layout.Column = 3;
            app.SCRAMButton.Text = 'SCRAM';

            % Create StopButton
            app.StopButton = uibutton(app.GridLayout, 'push');
            app.StopButton.ButtonPushedFcn = createCallbackFcn(app, @StopButtonPushed, true);
            app.StopButton.BackgroundColor = [0 0.451 0.7412];
            app.StopButton.FontName = 'Franklin Gothic Demi';
            app.StopButton.FontSize = 18;
            app.StopButton.Tooltip = {'Stops the water sampler and resets to default position'};
            app.StopButton.Layout.Row = 2;
            app.StopButton.Layout.Column = 4;
            app.StopButton.Text = 'Stop';

            % Create WebcamPanel
            app.WebcamPanel = uipanel(app.GridLayout);
            app.WebcamPanel.Title = 'Webcam';
            app.WebcamPanel.BackgroundColor = [0.902 0.902 0.902];
            app.WebcamPanel.Layout.Row = [3 7];
            app.WebcamPanel.Layout.Column = [1 3];
            app.WebcamPanel.FontName = 'Franklin Gothic Demi';

            % Create LogsPanel
            app.LogsPanel = uipanel(app.GridLayout);
            app.LogsPanel.Title = 'Logs';
            app.LogsPanel.BackgroundColor = [0.902 0.902 0.902];
            app.LogsPanel.Layout.Row = [3 7];
            app.LogsPanel.Layout.Column = [4 5];
            app.LogsPanel.FontName = 'Franklin Gothic Demi';

            % Create LogsText
            app.LogsText = uitextarea(app.GridLayout);
            app.LogsText.Editable = 'off';
            app.LogsText.FontName = 'TI Uni';
            app.LogsText.Layout.Row = [4 6];
            app.LogsText.Layout.Column = [4 5];
            app.LogsText.Value = {'Tip: Press ''space'' to SCRAM.'};

            % Create Image
            app.Image = uiimage(app.GridLayout);
            app.Image.Layout.Row = [4 6];
            app.Image.Layout.Column = [1 3];

            % Show the figure after all components are created
            app.MainMenu.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = waterSamplerGUI

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MainMenu)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MainMenu)
        end
    end
end