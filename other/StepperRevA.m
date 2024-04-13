classdef StepperRevA
    %   Stepper class
    %   This runs an Adafruit unipolar stepper motor from Matlab
    %   
    
    properties
        
        arduinoObject     % The Arduino object
        stepsPerRev       % Number of steps in one shaft revolution
        motorPin1         % Pin wired to the Blue wire of the stepper
        motorPin2         % Pin wired to the Pink wire of the stepper
        motorPin3         % Pin wired to the Yellow wire of the stepper
        motorPin4         % Pin wired to the Orange wire of the stepper
        motorSpeed        % Speed in shaft revolutions per minute
        stepsToMove       % The number of steps to move at motorSpeed
    
    end
    
    methods
       
        function obj = StepperRevA(ArduinoObject, StepsPerRev, MotorPin1, MotorPin2, MotorPin3, MotorPin4)
            
            %Store the objects key data values
            obj.arduinoObject = ArduinoObject;
            obj.stepsPerRev  = StepsPerRev;
            obj.motorPin1    = MotorPin1;
            obj.motorPin2    = MotorPin2;
            obj.motorPin3    = MotorPin3;
            obj.motorPin4    = MotorPin4;
            
            % Initialize the Arduino pins as outputs
            configurePin(ArduinoObject,MotorPin1,'DigitalOutput');
            configurePin(ArduinoObject,MotorPin2,'DigitalOutput');
            configurePin(ArduinoObject,MotorPin3,'DigitalOutput');
            configurePin(ArduinoObject,MotorPin4,'DigitalOutput');
        end
        
        function MoveClockWise(obj, MotorSpeed, StepsToMove)
            if(StepsToMove~=0)
                % Validate and store the data values
                if 0 == MotorSpeed
                    obj.motorSpeed  = 60; %default to 1 RPM
                else
                    obj.motorSpeed  = MotorSpeed;
                end

                if 0 == StepsToMove
                    obj.stepsToMove  = obj.stepsPerRev; %default to 1 Rev
                else
                    obj.stepsToMove = StepsToMove;
                end

                % Compute the speed - This is 'adjusted' to accomodate lag
                StepsPerSecond = (1/4) * obj.stepsPerRev * obj.motorSpeed;
                %Invert it
                SecondsPerStep = 1/StepsPerSecond;

                % Ensure all outputs are off
                writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);

                % Then move the motor
                for index = 1:(obj.stepsToMove/4)
                    writeDigitalPin(obj.arduinoObject, obj.motorPin1, 1);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin2, 1);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin3, 1);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin4, 1);
                    pause(SecondsPerStep/4);
                end

                % Leave all the motor coils de-energized when finished
                writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);  
            end
        end
        
        function MoveCounterClockWise(obj, MotorSpeed, StepsToMove)
            if(StepsToMove~=0)
                % Validate and store the data values
                if 0 == MotorSpeed
                    obj.motorSpeed  = 600;
                     %default to 1 RPM
                else
                    obj.motorSpeed  = MotorSpeed;
                end

                if 0 == StepsToMove
                    obj.stepsToMove  = obj.stepsPerRev; %default to 1 Rev
                else
                    obj.stepsToMove = StepsToMove;
                end

                % Compute the speed - This is 'adjusted' to accomodate lag
                StepsPerSecond = (1/4) * obj.stepsPerRev * obj.motorSpeed;
                %Invert it
                SecondsPerStep = 1/StepsPerSecond;

                % Ensure all outputs are off
                writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);

                % Then move the motor
                for index = 1:(obj.stepsToMove/4)
                    writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin4, 1);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin3, 1);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin2, 1);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                    pause(SecondsPerStep/4);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin1, 1);
                    writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                    pause(SecondsPerStep/4);
                end

                % Leave all the motor coils de-energized when finished
                writeDigitalPin(obj.arduinoObject, obj.motorPin1, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin2, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin3, 0);
                writeDigitalPin(obj.arduinoObject, obj.motorPin4, 0);    
            end
        end
    end
        
end

