%{
██████╗  ██████╗  ███████╗ ██╗   ██╗ ██╗ ███████╗ ██╗    ██╗
██╔══██╗ ██╔══██╗ ██╔════╝ ██║   ██║ ██║ ██╔════╝ ██║    ██║
██████╔╝ ██████╔╝ █████╗   ██║   ██║ ██║ █████╗   ██║ █╗ ██║
██╔═══╝  ██╔══██╗ ██╔══╝   ╚██╗ ██╔╝ ██║ ██╔══╝   ██║███╗██║
██║      ██║  ██║ ███████╗  ╚████╔╝  ██║ ███████╗ ╚███╔███╔╝
╚═╝      ╚═╝  ╚═╝ ╚══════╝   ╚═══╝   ╚═╝ ╚══════╝  ╚══╝╚══╝ 

This script is a PREVIEW ONLY and should not be run.
This script is a preview of "GUI_POC.mlapp"
%}





%classdef GUI_POC < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure            matlab.ui.Figure
        Grid                matlab.ui.container.GridLayout
        Lights              matlab.ui.control.StateButton
        ArduinoConnect      matlab.ui.control.Button
        DropdownGrid        matlab.ui.container.GridLayout
        Dropdown            matlab.ui.control.DropDown
        UnitsDropDownLabel  matlab.ui.control.Label
        LoadDataButton      matlab.ui.control.Button
        LightLevel          matlab.ui.control.UIAxes
        Flowrate            matlab.ui.control.UIAxes
        Temperature         matlab.ui.control.UIAxes
    end

    properties (Access = private)
        a;
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % Clear out Arduino
            clear app.a
            % Connect the Arduino
            app.a = arduino();
            %Change Button Color
            app.ArduinoConnect.BackgroundColor = [0.30, 0.75, 0.93];
            %Change Button Text
            app.ArduinoConnect.Text = "Arduino Connected";
        end

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            %Bring Excel Data into App
            data=readtable("ExampleHydroponicData.xlsx");
            %Assign Duration with Values in TimeStamp Column
            Duration = table2array (data(:,"TimeStamp"));
            %Assign TempFah with Values in TempF Column
            TempFah = table2array (data(:,"TempF"));
            %Assign Duration with Values in WaterFlow Column
            Flow = table2array (data(:,"WaterFlow"));
            %Assign Duration with Values in LightIntensity Column
            Light = table2array (data(:,"LightIntensity"));
            
            switch app.Dropdown.Value
                case "Imperial"
                    %Plot TempFah by Duration in app.Temperature
                    plot(app.Temperature,Duration,TempFah);
                    %Modify Ylabel
                    app.Temperature.YLabel.String = "Temperature (F)";
                    %Plot Flow by Duration in app.Temperature
                    plot(app.Flowrate,Duration,Flow);
                    %Modify Ylabel
                    app.Flowrate.YLabel.String = "Water Flow (in/min)";
                    %Plot LightLevel by Duration in app.Temperature
                    plot(app.LightLevel,Duration,Light);
                    
 	            case 'Metric'
		            %Convert Temps to Celsius
                    TempCel=(5/9)*(TempFah-32);
                    %Plot TempCel by Duration in app.Temperature
                    plot(app.Temperature,Duration,TempCel);
                    %Modify Ylabel
                    app.Temperature.YLabel.String = "Temperature (C)";
                    
                    WaterFlowcm=Flow*2.54; %Convert Flow to centimeters
                    %Plot Flow by Duration in app.Flowrate
                    plot(app.Flowrate,Duration,WaterFlowcm);
                    %Modify Ylabel
                    app.Flowrate.YLabel.String = "Water Flow (cm/min)";
 		            
                    %Plot LightLevel by Duration in app.Temperature
                    plot(app.LightLevel,Duration,Light);
            end
        end

        % Value changed function: Lights
        function LightsValueChanged(app, event)
            % Toggle Value when button pressed
            value = app.Lights.Value; 
            
            if value == 1 % Change Action with Button Press
                % Change Button Text
                app.Lights.Text = "Lights On"; 
                % Change Button Color
                app.Lights.BackgroundColor = [1,1,0]; 
                % Turn on Pin 13
                writeDigitalPin (app.a,'D13',1) ; 
         	else 
                % Change Button Text
                app.Lights.Text = "Lights Off"; 
                % Change Button Color
                app.Lights.BackgroundColor = [0,.45,.74]; 
                % Turn off Pin 13
 		        writeDigitalPin (app.a,'D13',0) ; 
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create Grid
            app.Grid = uigridlayout(app.UIFigure);
            app.Grid.RowHeight = {'5x', '5x', '5x', '1x', '1x'};
            app.Grid.ColumnSpacing = 80;
            app.Grid.RowSpacing = 5;
            app.Grid.Padding = [100 25 100 25];

            % Create Temperature
            app.Temperature = uiaxes(app.Grid);
            title(app.Temperature, 'Recent Temperature Readings')
            xlabel(app.Temperature, 'Date')
            ylabel(app.Temperature, 'Temperature (F)')
            zlabel(app.Temperature, 'Z')
            app.Temperature.FontSize = 10;
            app.Temperature.Layout.Row = 1;
            app.Temperature.Layout.Column = [1 2];

            % Create Flowrate
            app.Flowrate = uiaxes(app.Grid);
            title(app.Flowrate, 'Recent Flowrate Readings')
            xlabel(app.Flowrate, 'Date')
            ylabel(app.Flowrate, 'Water Flowrate (in/min)')
            zlabel(app.Flowrate, 'Z')
            app.Flowrate.FontSize = 10;
            app.Flowrate.Layout.Row = 2;
            app.Flowrate.Layout.Column = [1 2];

            % Create LightLevel
            app.LightLevel = uiaxes(app.Grid);
            title(app.LightLevel, 'Recent Light Level Readings')
            xlabel(app.LightLevel, 'Date')
            ylabel(app.LightLevel, 'Light Levels in Volts')
            zlabel(app.LightLevel, 'Z')
            app.LightLevel.FontSize = 10;
            app.LightLevel.Layout.Row = 3;
            app.LightLevel.Layout.Column = [1 2];

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.Grid, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.BackgroundColor = [0 1 0];
            app.LoadDataButton.Layout.Row = 4;
            app.LoadDataButton.Layout.Column = 1;
            app.LoadDataButton.Text = 'Load and Plot Data';

            % Create DropdownGrid
            app.DropdownGrid = uigridlayout(app.Grid);
            app.DropdownGrid.ColumnWidth = {'2x', '3x'};
            app.DropdownGrid.RowHeight = {'1x'};
            app.DropdownGrid.Padding = [0 0 0 0];
            app.DropdownGrid.Layout.Row = 5;
            app.DropdownGrid.Layout.Column = 1;

            % Create UnitsDropDownLabel
            app.UnitsDropDownLabel = uilabel(app.DropdownGrid);
            app.UnitsDropDownLabel.HorizontalAlignment = 'right';
            app.UnitsDropDownLabel.Layout.Row = 1;
            app.UnitsDropDownLabel.Layout.Column = 1;
            app.UnitsDropDownLabel.Text = 'Units';

            % Create Dropdown
            app.Dropdown = uidropdown(app.DropdownGrid);
            app.Dropdown.Items = {'Imperial', 'Metric'};
            app.Dropdown.Layout.Row = 1;
            app.Dropdown.Layout.Column = 2;
            app.Dropdown.Value = 'Imperial';

            % Create ArduinoConnect
            app.ArduinoConnect = uibutton(app.Grid, 'push');
            app.ArduinoConnect.BackgroundColor = [1 0 0];
            app.ArduinoConnect.Layout.Row = 4;
            app.ArduinoConnect.Layout.Column = 2;
            app.ArduinoConnect.Text = 'Arduino Not Connected';

            % Create Lights
            app.Lights = uibutton(app.Grid, 'state');
            app.Lights.ValueChangedFcn = createCallbackFcn(app, @LightsValueChanged, true);
            app.Lights.Text = 'Lights Off';
            app.Lights.BackgroundColor = [0 0.4471 0.7412];
            app.Lights.Layout.Row = 5;
            app.Lights.Layout.Column = 2;

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = GUI_POC

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