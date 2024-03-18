%{
██████╗  ██████╗  ███████╗ ██╗   ██╗ ██╗ ███████╗ ██╗    ██╗
██╔══██╗ ██╔══██╗ ██╔════╝ ██║   ██║ ██║ ██╔════╝ ██║    ██║
██████╔╝ ██████╔╝ █████╗   ██║   ██║ ██║ █████╗   ██║ █╗ ██║
██╔═══╝  ██╔══██╗ ██╔══╝   ╚██╗ ██╔╝ ██║ ██╔══╝   ██║███╗██║
██║      ██║  ██║ ███████╗  ╚████╔╝  ██║ ███████╗ ╚███╔███╔╝
╚═╝      ╚═╝  ╚═╝ ╚══════╝   ╚═══╝   ╚═╝ ╚══════╝  ╚══╝╚══╝ 

This script is a PREVIEW ONLY and should not be run.
This script is a preview of "GUI_BuildGUI.mlapp"
%}





%classdef GUI_BuildGUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MainMenu     matlab.ui.Figure
        GridLayout   matlab.ui.container.GridLayout
        LogsText     matlab.ui.control.TextArea
        LogsPanel    matlab.ui.container.Panel
        ImagesPanel  matlab.ui.container.Panel
        Images       matlab.ui.control.UIAxes
        StopButton   matlab.ui.control.Button
        StartButton  matlab.ui.control.Button
    end

    properties (Access = public)
        % Declare null variables here
        a; % Will eventually construct the Arduino
        s; % Will eventually construct the servo
        thisStepper; % Will eventually construct the stepper
        cam; % Will eventually construct the webcam
        ranFromWaterSamplerScript; % Verifies app was run from script
        internalTimer; % Total time lapsed since last action ended
        digital; % An array for the graph
        stepsPerRevolution; % Will eventually hold steps per rev

        % Declare variables here
        stopRequested = false; % When "Stop" is pressed
        wS_State = "Stopped"; % Current state of the Water Sampler
        action = 0; % Current action being executed
    end

    methods (Access = private)
        
        % Sends a log to the log GUI area
        function wS_Log(app, message)
            app.LogsText.Value = [sprintf("%s", message); app.LogsText.Value];
        end

        % The code for the many tests we perform.
        % app - passes in the app object for use of variables
        function wS_Tests(app)
            wS_Log(app, "LED Check Begin");

            writeDigitalPin(app.a, 'D13', 1); % Send 5 volts to pin 13
            pause(1); % Pause for one second
            writeDigitalPin(app.a, 'D13', 0); % Send 0 volts to pin 13
            pause(1); % Pause for one second
            writeDigitalPin(app.a, 'D12', 1); % Send 5 volts to pin 12
            pause(1); % Pause for one second
            writeDigitalPin(app.a, 'D12', 0); % Send 0 volts to pin 12
            pause(1); % Pause for one second

            wS_Log(app, "LED Check Complete");
            wS_Log(app, "Stepper start");

            MoveClockWise(app.thisStepper, 100, 200); % Move the stepper clockwise
            pause(1); % Pause for one second
            MoveCounterClockWise(app.thisStepper, 100, 200); % Move the stepper counterclockwise

            wS_Log(app, "Program is done.");
            wS_Log(app, "Momentary Switch Check Begin");

            app.digital = zeros(1,30);  % Develop an array of zeros 30 long 0,0,0...

            wS_Log(app, "Press button on and off every second");

            % Run the portion of the code for each integer between 1 and the total
            % number of values in the array digital

            for index = 1:length(app.digital)
                % Get value from the digital pin and store it in digital
                app.digital(index) = readDigitalPin(app.a, 'D11');
                pause(0.2); % Pause .2 seconds
                plot(app.Images, app.digital); % Graph the digital data
                app.Images.YLimMode = "manual";
                app.Images.YLim = [-0.5, 1.5]; % Set y limits of plot
                app.Images.YLabel.String = "Voltage"; % Label y axis
            end % End of the for loop

            wS_Log(app, "Momentary Switch Check Complete");
            wS_Log(app, "Servo Check Begin");

            % Run this section of code for each integer between 1 and 3
            for i = 1:3
                % Send the smallest pulse to the servo to set it to the "lowest" postion
                writePosition(app.s, 0); 
                pause(1.5) % Pause for 1.5 seconds
                % Send the middle sized pulse to the servo to set it to the "middle" postion
                writePosition(app.s, 0.5);
                pause(1.5) % Pause for 1.5 seconds
                % Send the largest pulse to the servo to set it to the "highest" postion
                writePosition(app.s, 1);
                pause(1.5); % Pause for 1.5 seconds
            end

            wS_Log(app, "Servo Check Complete");
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            % Changes the button colors to default
            app.StartButton.BackgroundColor = [0.39, 0.83, 0.07];
            app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];

            % Tries to evaluate a variable in the workspace
            try
                app.ranFromWaterSamplerScript = evalin("base", "ranFromWaterSamplerScript");
            catch exception
                % If it fails, the app was not run from the script.
                % Nicely rethrows the exception
                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_Log(app, "GUI ran without script. Run the script 'waterSampler.m' instead.");
                rethrow(exception);
            end

            try
                % Evaluates the value of the variable called "cam" in the workspace.
                % Then, assigns that value to app.cam
                % It does this for every variable below...
                app.cam = evalin("base", "cam");
                app.a = evalin("base", "a");
                app.thisStepper = evalin("base", "thisStepper");
                app.s = evalin("base", "s");
                app.stepsPerRevolution = evalin("base", "stepsPerRevolution");

            catch exception
                % If one of them fails, it logs it in the app
                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_Log(app, "Failed to evaluate one or more variables from Workshop. (Do they exist before evaluation?)");
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
                app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];
    
                wS_Log(app, "Starting the water sampler...");

                wS_Log(app, "Restarting the timer...");
    
                app.internalTimer = tic; % Restarts the Internal Timer
                app.action = app.action + 1; % app.action++;

                % Tries to run the while loop
                try
                    while ((~app.stopRequested) && (~app.MainMenu.BeingDeleted) && (app.action < 100))
                        if (app.action == 1)
                            % Action 1. Delay of 0.000 seconds
                            wS_Tests(app); % Runs the tests

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer

                        elseif ((app.action == 2) && (toc(app.internalTimer) > 6.000))
                            % Action 2. Delay of 6.000 seconds
                            wS_Log(app, "Taking picture...");

                            app.Images.YLimMode = "auto";
                            app.Images.YLabel.String = "";
                            imshow(app.cam.snapshot(), "Parent", app.Images);

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer
                        end
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
                app.StopButton.BackgroundColor = [0.47, 0.47, 0.47];

                wS_Log(app, "Stopping the water sampler...");
    
                % Stops the webcam
                wS_Log(app, "Stopping webcam...");
                pause(0.250); % Pause to ensure it does not call a deleted object
                delete(app.cam); % Closes the webcam (turns off the camera)
    
                % Returns motors to home

                wS_Log(app, "Stopping app...");
                pause(3.000);
                delete(app); % Closes the app
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
            wS_Log(app, "The key '" + key + "' was pressed.");
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

            % Create ImagesPanel
            app.ImagesPanel = uipanel(app.GridLayout);
            app.ImagesPanel.Title = 'Images';
            app.ImagesPanel.BackgroundColor = [0.902 0.902 0.902];
            app.ImagesPanel.Layout.Row = [3 7];
            app.ImagesPanel.Layout.Column = [1 3];
            app.ImagesPanel.FontName = 'Franklin Gothic Demi';

            % Create Images
            app.Images = uiaxes(app.ImagesPanel);
            ylabel(app.Images, 'Y')
            app.Images.Position = [0 37 346 183];

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

            % Show the figure after all components are created
            app.MainMenu.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI_BuildGUI

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