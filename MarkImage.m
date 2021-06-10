%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script to add a marker of given length to one or more images

% Marker length can be modified as a parameter in the script; also pay
% attention to the conversion factor of your image (um4pix). The marker is
% added in the bottom right corner, with reasonable proportions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear all

%% Adjustable parameters
um4pix = 0.43;  % micrometers per pixel in the image
marker = 100;   % marker length, in micrometers

%% Printing cycle
flag = true;
while flag
    % Image selection
    [fnm, canceled] = imgetfile();
    if canceled
        disp('USER CANCELED');
        return
    end
    img = imread(fnm);
    
    % Marker position calculation
    [H,W,C] = size(img);
    y = round(0.852*H);
    h = round(0.0185*H);
    w = round(marker/um4pix);
    x = round(W*0.9323 - w);
    
    % Marker application
    f=figure();
    imshow(img);
    rectangle('Position',[x, y, w, h],'FaceColor','r','EdgeColor','r');
    text(x+h, y-2*h, [num2str(marker),' um'], 'FontSize', 24, 'Color','r','FontName','Calibri');
    
    % Save image with _MARKED label
%     imwrite(getframe(f).cdata,strcat(fnm,'_MARKED.bmp'));     % this has white border
    exportgraphics(f, strcat(fnm,'_MARKED.png'));   %this has not 
    
    % Ask to repeat and close previous figure
    repeat = questdlg('Do you want to mark another image?','','Yes','No','Yes');
    switch repeat
        case 'No'
            flag = false;
    end
    close(f);
end