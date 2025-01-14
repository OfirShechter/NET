classdef VS_mrDenseNoise < VStim
    properties
        %all these properties are modifiable by user and will appear in visual stim GUI
        %Place all other variables in hidden properties
        %test
        brtIntensity    = 255; %white
        drkIntensity    = 0; %black
        scrIntensity    = 0; %background
        noiseColor      = [1 1 1]; %black/white
        popDNscrColor   = [1 1 1]; %background
        duration        = 10; %300sec = 5min
        tmpFrq          = 30; %hz
        nPxls_x         = 100;
        nPxls_y         = 75;
        padRows              = 0;
        padColumns           = 0;
%         maskRect        = false;
%         rectWidth       = 264;
%         rectHeight      = 264;
%         maskRadius      = 2000;
        preStimWait     = 1;
        postStimWait     = 1;
        makeBWnoise          = true;
        noiseType            = 'sparse';    %sparse / single / full
        percentChange        = 20;
        indicator_row        = false;

    end
    properties (Hidden,Constant)
        defaultTrialsPerCategory=50; %number of gratings to present
        defaultBackground=0;
        defaultITI=0;
        meanLuminosityTxt='luminance value for grey pixels';
        contrastTxt='% of dynamic range to use';
        largeRectNumTxt='How many rectangles to put onto each spatial dimension (not counting the mask)';
        smallRectNumTxt='make it a multiple of largeRectNum';
        smallRectFrameRateTxt='temporal frequency (Hz)';
        largeRectSparsityTxt='%of non grey squares';
        smallRectSparsityTxt='%of non grey squares';
        makeBWnoiseTxt = 'check for BW, uncheck for gaussian noise';
        noiseTypeTxt = 'text: sparse - change only X% of the pixels, single - change 1 pixel, full - change 50% of the pixels';
        percentChangeTxt = 'in sparse noise: how many pixels should change in each frame';
        brtIntensityTxt = 'scalar, between 0 and 255, the color of the bright noise';            
        drkIntensityTxt = 'scalar, between 0 and 255, the color of the dark noise';
        scrIntensityTxt = 'scalar, between 0 and 255, the color of the screen between intervals and of non-noise pixels'
        noiseColorTxt = 'color of the noise pixels, in RGB values of 0 to 1';
        scrColorTxt = 'color of the non-noise pixels, in RGB values of 0 to 1';
        durationTxt = 'Duration of the stimulus, in seconds';
        tmpFrqTxt = 'Temporal Frequency of the frames (frames/s)';
        nPxls_xTxt = 'Number of noise pixels in the x axis';
        nPxls_yTxt = 'Number of noise pixels in the y axis';
        padRowsTxt = 'add zeros to fix dimentions of pixels in x axis';
        padColumnsTxt = 'add zeros to fix dimentions of pixels in y axis';
        %     maskRect
        %     rectWidth
        %     rectHeight
        %     maskRadius
        preStimWaitTxt = 'time (s) to wait before the stimulation';
        postStimWaitTxt = 'time (s) to wait after the stimulation';
        indicator_rowTxt = 'check to use the first row as a frame indicator';
        %     saveImageTime
        %     saveImage
        %     btnDNdebug            Debug mode when there in no parallel connection
        remarks={''};
    end
    properties (Hidden, SetAccess=protected)
        stim
        stimOnset
        flipOffsetTimeStamp
        flipMiss
        flipOnsetTimeStamp
        syncTime
        prelim_presentation_error = 0;
        vbl = [];
    end
    methods
        function obj=run(obj)
            %find pixels that can be presented through the optics
            screenProps=Screen('Resolution',obj.PTB_win);
            
            %generate stimulus
            brtColor = obj.brtIntensity*obj.noiseColor;
            drkColor = obj.drkIntensity*obj.noiseColor;
            scrColor  = obj.scrIntensity*obj.popDNscrColor;
            screenRect = obj.rect;
            frame_rate = obj.fps;
            
%             if obj.maskRect
%                 obj.maskRadius = max(ceil(obj.rectWidth/2),ceil(obj.rectHeight/2));
%                 mask = makeRectangularMaskForGUI(obj.rectWidth,obj.rectHeight);
%                 masktex=Screen('MakeTexture', obj.PTB_win, mask);
%             end
            
            [screenXpixels, screenYpixels] = Screen('WindowSize', obj.PTB_win);
            
            % Get the centre coordinate of the obj.PTB_win
            xNoisePxls = obj.nPxls_x;% 2.*round(nPxls/2)/2; %num cells x %for mightex
            yNoisePxls = obj.nPxls_y; %num cells y
            nNoisePxls = xNoisePxls * yNoisePxls;
            blankScreen = repmat(scrColor',1,nNoisePxls);
            colorsArraySize = obj.duration*obj.tmpFrq; % number of frames
            colorsArray = [];
            
            % calculate Gaussian noise parameters
            if ~obj.makeBWnoise
                mu = mean([brtColor;drkColor]);
                sigma = (mu - drkColor) / 5.5;
                %with 5.5sigma all values will hopefully fall into 0-255,
                %but this is really not foolproof!
            end
            
            % run test Flip (sometimes this first flip is slow and so it is not included in the anlysis
            obj.visualFieldBackgroundLuminance=obj.visualFieldBackgroundLuminance;
            
            % build noise array (color*pixelNum*frames)
            disp('Building noise array');
            for frames = 1:colorsArraySize
                
                switch obj.noiseType
                    case 'sparse'
                        %here exactly X% of the pixels are white
                        nPxls=round(nNoisePxls*obj.percentChange/100);
                        pxl = randperm(nNoisePxls,nPxls*2);
                        
                        noisePxlBrt = pxl(:,1:nPxls);
                        noisePxlDrk = pxl(:,nPxls+1:end);
                        
                        noiseColorsMat = blankScreen;
                        noiseColorsMat(:,noisePxlBrt) = repmat(brtColor',1,nPxls);
                        noiseColorsMat(:,noisePxlDrk) = repmat(drkColor',1,nPxls);
                        
                    case 'single'
                        %single pxls
                        pxl = Shuffle([true,false(1,nNoisePxls-1)]);
                        noiseColorsMat = blankScreen;
                        noiseColorsMat(:,pxl) = brtColor';
                        
                    case 'full'
                        if obj.makeBWnoise %here each pixel is sampled independently
                            noisePxlsBrt = rand(1,nNoisePxls) > 0.5;
                            nPxlsBrt = sum(noisePxlsBrt);
                            nPxlsDrk = nNoisePxls - nPxlsBrt;
                            noiseColorsMat(:,noisePxlsBrt) = repmat(brtColor',1,nPxlsBrt);
                            noiseColorsMat(:,~noisePxlsBrt) = repmat(drkColor',1,nPxlsDrk);
                        else % make "true" (gaussian) white noise
                            noiseColorsMat = randn(1,nNoisePxls) .* sigma' + mu';
                        end
                end
                
                % optional padding of the stimulation area
                sqMat = reshape(permute(noiseColorsMat,[2,3,1]),obj.nPxls_y,obj.nPxls_x,3);
                sqMat = padarray(sqMat,[obj.padRows obj.padColumns]);
                
                if obj.indicator_row
                    sqMat(1,:) = mod(frames,2)*brtColor(1);
                end
                
                newNoiseColorsMat = reshape(permute(sqMat,[3,1,2]),3,[],1);
                if frames==1
                    colorsArray = zeros([size(newNoiseColorsMat),colorsArraySize],'uint8');
                end
                colorsArray(:,:,frames) = newNoiseColorsMat;
%                 colorsArray = cat(3, colorsArray, newNoiseColorsMat);
            end
            
            % save a more compact matrix
            if all(obj.noiseColor == [1 1 1])
                noiseArray = colorsArray(1,:,:);
            else
                noiseArray = colorsArray;
            end
            
            realXNoisePxls = obj.nPxls_x+(obj.padColumns*2); %including padding
            realYNoisePxls = obj.nPxls_y+(obj.padRows*2);
                       
            ySizeNoisePxls=(screenYpixels/realYNoisePxls);
            xSizeNoisePxls=(screenXpixels/realXNoisePxls);
            baseRect = [0 0 xSizeNoisePxls ySizeNoisePxls];
            
            xPos = repelem(0:realXNoisePxls-1,realYNoisePxls);
            yPos = repmat(0:realYNoisePxls-1,1,realXNoisePxls);
            
            % Scale the grid spacing to the size of our squares and centre
            xPosRight = xPos .* xSizeNoisePxls + xSizeNoisePxls * .5;  %checkkkk!!!!!!
            yPosRight = yPos .* ySizeNoisePxls + ySizeNoisePxls * .5;
            
            % Make our rectangle coordinates
            allRectsRight = CenterRectOnPointd(baseRect,xPosRight',yPosRight')';

            % start stimulation
            disp('Starting Stimulation');
            Screen('FillRect', obj.PTB_win, scrColor, []);
            Screen('Flip',obj.PTB_win);
            
            waitFrame = frame_rate / obj.tmpFrq;
            obj.sendTTL(1,true);
            WaitSecs(obj.preStimWait);
            obj.sendTTL(2,true);
            for i = 1:colorsArraySize
<<<<<<< HEAD
                % Draw the rect to the screen
                Screen('FillRect', obj.PTB_win, colorsArray(:,:,i), allRectsRight);
                %Screen('DrawTexture',obj.PTB_win,masktex);
                Screen('DrawingFinished', obj.PTB_win);
                obj.sendTTL(3,true);
                vbl(i) = Screen('Flip', obj.PTB_win,vbl(end)+1/obj.txtDNtmpFrq - presentation_error);
                obj.sendTTL(3,false);
            end           
            Priority(0);
=======
                for j = 1:waitFrame
                    % Draw the rect to the screen
                    Screen('FillRect', obj.PTB_win, colorsArray(:,:,i), allRectsRight);
                    %Screen('DrawTexture',obj.PTB_win,masktex);
                    Screen('DrawingFinished', obj.PTB_win);
                    if j==1
                        obj.sendTTL(3,true);
                        Screen('Flip',obj.PTB_win);
                        obj.sendTTL(3,false);
                    else
                        Screen('Flip',obj.PTB_win);
                    end
                end
            end
>>>>>>> 34c95d87528d22b4225ac7ae753729809683d581
            
            Screen('FillRect', obj.PTB_win, scrColor, []);
            Screen('Flip',obj.PTB_win);
            obj.sendTTL(2,false);
<<<<<<< HEAD
            obj.applyBackgound;
            Screen('Flip', obj.PTB_win);
=======
            WaitSecs(obj.postStimWait);
>>>>>>> 34c95d87528d22b4225ac7ae753729809683d581
            obj.sendTTL(1,false);
            disp('Session ended');
            filename = sprintf('C:\\MATLAB\\user=ND\\SavedStimulations\\VS_mrDenseNoise_%s.mat', datestr(now,'mm_dd_yyyy_HHMM'));
            save(filename, 'noiseArray', 'obj', '-v7.3');
        end
        
        %class constractor
        function obj=VS_mrDenseNoise(w,~)
            obj = obj@VStim(w); %ca
            %get the visual stimulation methods
            obj.trialsPerCategory=obj.defaultTrialsPerCategory;
            obj.visualFieldBackgroundLuminance=obj.defaultBackground;
            obj.interTrialDelay=obj.defaultITI;
        end
        
    end
end %EOF
