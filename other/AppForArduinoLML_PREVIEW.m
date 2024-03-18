%{
██████╗  ██████╗  ███████╗ ██╗   ██╗ ██╗ ███████╗ ██╗    ██╗
██╔══██╗ ██╔══██╗ ██╔════╝ ██║   ██║ ██║ ██╔════╝ ██║    ██║
██████╔╝ ██████╔╝ █████╗   ██║   ██║ ██║ █████╗   ██║ █╗ ██║
██╔═══╝  ██╔══██╗ ██╔══╝   ╚██╗ ██╔╝ ██║ ██╔══╝   ██║███╗██║
██║      ██║  ██║ ███████╗  ╚████╔╝  ██║ ███████╗ ╚███╔███╔╝
╚═╝      ╚═╝  ╚═╝ ╚══════╝   ╚═══╝   ╚═╝ ╚══════╝  ╚══╝╚══╝ 

This script is a PREVIEW ONLY and should not be run.
This script is a preview of "AppForArduinoLML.mlapp"
%}





%classdef AppForArduinoLML < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure           matlab.ui.Figure
        GridLayout         matlab.ui.container.GridLayout
        Label              matlab.ui.control.Label
        Image              matlab.ui.control.Image
        ResultField        matlab.ui.control.NumericEditField
        ResultLabel        matlab.ui.control.Label
        DropDown           matlab.ui.control.DropDown
        TakeReadingButton  matlab.ui.control.Button
        TMLabel            matlab.ui.control.Label
    end

    
    properties (Access = private)
        a; % Later used to construct the Arduino
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
             app.a = arduino(); % Connects the Arduino

             % Changes color of button after connection
             app.TakeReadingA0Button.BackgroundColor = [0.30,0.75,0.93];
        end

        % Button pushed function: TakeReadingButton
        function TakeReadingButtonPushed(app, event)
            % Get value from the digital pin and store it in digital pin
            volts = readVoltage(app.a, "A0");

            R2=10000; % The value of the precision resistor
            temp0 = 298.15; % Reference temperature (25 C), in Kelvin
            res0 = 10000; % Resistance at reference temperature, in Ohms
            B = 3950; % Thermistor B parameter, in Kelvin
            current=volts/R2; % Calculate the current using Ohm's law
            Resistance=(5-volts)/current; % Find the resistance of the thermistor
            recip_temp = 1/temp0 + log(Resistance/res0)/B; % Calculate the reciprocal of the TempK
            TempK = 1./recip_temp; % Calculate Temp in Kelvin
            
            % Type of code switches based on value in dropdown menu
            switch app.DropDown.Value
                case "Voltage" % When voltage is selected...

                    % Tells the output field to use the value of volts
                    app.ResultEditField.Value = volts;

                case "Celsius" % When Celsius is selected... 
                    TempC = TempK -273.15; % Convert to Celsius 

                    % Tells the output field to use the value of TempC
                    app.ResultEditField.Value=TempC; 

                case "Fahrenheit" % When Fahrenheit is selected...
                    TempF = (((TempK - 273.15) * 1.8) + 32); % Convert to Fahrenheit

                    % Tells the output field to use the value of TempF 
                    app.ResultEditField.Value=TempF;
           end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 617 200];
            app.UIFigure.Name = 'MATLAB App';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'0.1x', '0.1x', '0.1x', '0.1x', '0.1x'};
            app.GridLayout.RowHeight = {'0.2x', '0.2x', '0.2x', '0.2x'};
            app.GridLayout.Padding = [30 30 30 30];

            % Create TMLabel
            app.TMLabel = uilabel(app.GridLayout);
            app.TMLabel.FontSize = 18;
            app.TMLabel.FontWeight = 'bold';
            app.TMLabel.FontColor = [1 0 0];
            app.TMLabel.Layout.Row = 1;
            app.TMLabel.Layout.Column = [1 3];
            app.TMLabel.Text = 'Temperature Measurement';

            % Create TakeReadingButton
            app.TakeReadingButton = uibutton(app.GridLayout, 'push');
            app.TakeReadingButton.ButtonPushedFcn = createCallbackFcn(app, @TakeReadingButtonPushed, true);
            app.TakeReadingButton.Layout.Row = 2;
            app.TakeReadingButton.Layout.Column = 2;
            app.TakeReadingButton.Text = 'Take Reading A0';

            % Create DropDown
            app.DropDown = uidropdown(app.GridLayout);
            app.DropDown.Items = {'Voltage', 'Fahrenheit', 'Celsius'};
            app.DropDown.Layout.Row = 4;
            app.DropDown.Layout.Column = 2;
            app.DropDown.Value = 'Voltage';

            % Create ResultLabel
            app.ResultLabel = uilabel(app.GridLayout);
            app.ResultLabel.HorizontalAlignment = 'right';
            app.ResultLabel.Layout.Row = 3;
            app.ResultLabel.Layout.Column = 3;
            app.ResultLabel.Text = 'Result';

            % Create ResultField
            app.ResultField = uieditfield(app.GridLayout, 'numeric');
            app.ResultField.Editable = 'off';
            app.ResultField.Layout.Row = 3;
            app.ResultField.Layout.Column = 4;

            % Create Image
            app.Image = uiimage(app.GridLayout);
            app.Image.Layout.Row = [1 3];
            app.Image.Layout.Column = 5;
            app.Image.ImageSource = 'ColdHot.jpg';

            % Create Label
            app.Label = uilabel(app.GridLayout);
            app.Label.FontColor = [0.8902 0.8902 0.8902];
            app.Label.Layout.Row = 4;
            app.Label.Layout.Column = 5;
            app.Label.Text = {'Made by'; 'Zachary Bratten'};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = AppForArduinoLML

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end