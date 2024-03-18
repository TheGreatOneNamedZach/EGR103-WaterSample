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
        cam; % Will eventually construct the webcam
        ranFromWaterSamplerScript; % Verifies app was run from script
        centralTimer; % Total time lapsed since "Start" pressed
        internalTimer; % Total time lapsed since last action ended

        % Declare variables here
        stopRequested = false; % When "Stop" is pressed
        wS_State = "Stopped"; % Current state of the Water Sampler
        action = 0; % Current action being executed
    end

    methods (Access = private)
        
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

        % The code for the vision sub-system
        % app - passes in the app object for use of variables
        function wS_Vision(app)
            % Logs that the vision system started.
            wS_LogCentral(app, "INFO", "Vision system took a snapshot.");

            % VISION CODE GOES HERE

        end
        
        % The code for the rotational base sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to rotate clockwise
        % speed - the speed at which to travel (1.00 = top speed)
        function wS_Rotational(app, distance, speed)
            % Logs that the rotational base system was told to move.
            wS_LogAction(app, distance, speed, "Rotational");

            % ROTATIONAL BASE CODE GOES HERE

        end

        % The code for the pipette sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to move towards the pipette
        % speed - the speed at which to travel (1.00 = top speed)
        function wS_Pipette(app, distance, speed)
            % Logs that the pipette system was told to move.
            wS_LogAction(app, distance, speed, "Pipette");

            % PIPETTE SQUEEZE CODE GOES HERE

        end

        % The code for the rotational base sub-system
        % app - passes in the app object for use of variables
        % distance - the distance to travel upwards
        % speed - the speed at which to travel (1.00 = top speed)
        function wS_Lift(app, distance, speed)
            % Logs that the lift system was told to move.
            wS_LogAction(app, distance, speed, "Lift");

            % LIFT WITH STAND CODE GOES HERE

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
                %app.a = evalin("base", "a");

            catch exception
                % If one of them fails, it logs it in the app
                app.LogsText.FontColor = [1.00, 0.00, 0.00];
                wS_LogCentral(app, "ERR", "Failed to evaluate one or more variables from Workshop. (Do they exist before evaluation?)");
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

                wS_LogCentral(app, "INFO", "Restarting the timer...");
                app.centralTimer = tic; % Restarts the Central Timer
    
                app.internalTimer = tic; % Restarts the Internal Timer
                app.action = app.action + 1; % app.action++;

                % Tries to run the while loop
                try
                    while ((~app.stopRequested) && (~app.MainMenu.BeingDeleted) && ((toc(app.centralTimer)) < 300) && (app.action < 100))
                        if (app.action == 1)
                            % Action 1. Delay of 0.000 seconds
                            wS_LogCentral(app, "EVNT", "Action 1 starting...");

                            wS_Pipette(app, 123.45, 0.50); % Tests the pipette

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer

                        elseif ((app.action == 2) && (toc(app.internalTimer) > 5.000))
                            % Action 2. Delay of 5.000 seconds
                            wS_LogCentral(app, "EVNT", "Action 2 starting...");

                            wS_Vision(app); % Tests the vision system
                            wS_Rotational(app, 4, 1); % Tests the rotational system

                            app.action = app.action + 1; % app.action++;
                            app.internalTimer = tic; % Restarts the Internal Timer

                        elseif ((app.action == 3) && (toc(app.internalTimer) > 5.000))
                            % Action 3. Delay of 5.000 seconds
                            wS_LogCentral(app, "EVNT", "Action 3 starting...");

                            wS_Lift(app, -14, -0.32); % Tests the Lift system

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
                wS_LogCentral(app, "INFO", "Stopping webcam...");
                pause(0.250); % Pause to ensure it does not call a deleted object
                delete(app.cam); % Closes the webcam (turns off the camera)
    
                % Returns motors to home

                wS_LogCentral(app, "INFO", "Stopping app...");
                pause(3.000);
                delete(app); % Closes the app
            end
        end

        % Button pushed function: SCRAMButton
        function SCRAMButtonPushed(app, event)
            if ~(app.wS_State == "SCRAM")
                app.stopRequested = true; % Declares a request to stop
                pause(1.000); % Waits for the while loop to stop
                app.wS_State = "SCRAM"; % If not already, then do so
                
                % Sets the background color to red
                app.GridLayout.BackgroundColor = [0.80, 0.00, 0.00];

                % Sets the button colors to normal & "SCRAM" to pressed
                app.StartButton.BackgroundColor = [0.39, 0.83, 0.07];
                app.SCRAMButton.BackgroundColor = [0.47, 0.47, 0.47];
                app.StopButton.BackgroundColor = [0.00, 0.45, 0.74];
                
                wS_LogCentral(app, "USER", "SCRAMing the water sampler...");

                % Tell all motors to stop moving

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