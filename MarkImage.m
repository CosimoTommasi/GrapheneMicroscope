%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script per aggiungere un marker di lunghezza data a una o piu' immagini

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

close all
clear all

%% Parametri da regolare
um4pix = 0.43;  % micrometri per pixel nell'immagine
marker = 100;   % lunghezza del marker, in micrometri

%% Ciclo di stampa
flag = true;
while flag
    [fnm, canceled] = imgetfile();
    if canceled
        disp('USER CANCELED');
        return
    end
    img = imread(fnm);
    % Calcolo della posizione del marker
    [H,W,C] = size(img);
    y = round(0.852*H);
    h = round(0.0185*H);
    w = round(marker/um4pix);
    x = round(W*0.9323 - w);
    
    % Applicazione del marker
    f=figure();
    imshow(img);
    rectangle('Position',[x, y, w, h],'FaceColor','r','EdgeColor','r');
    text(x+h, y-2*h, [num2str(marker),' um'], 'FontSize', 24, 'Color','r','FontName','Calibri');
    
    imwrite(getframe(f).cdata,strcat(fnm,'_MARKED.bmp'));
    
    repeat = questdlg('Do you want to mark another image?','','Yes','No','Yes');
    switch repeat
        case 'No'
            flag = false;
    end
    close(f);
end