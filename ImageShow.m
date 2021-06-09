%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script per scorrere immagini RGB e nei singoli canali R e G

% I comandi per la navigazione sono i seguenti:
%     →/←: scorrimento immagini
%     ↑/↓: ciclo colori (RGB, solo R, solo G)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;


global img  f fn i c color shown;

fnv = dir('img-*.bmp');
num_image = length(fnv);
for ii=1:num_image
   fn{ii} = fnv(ii).name; 
end

i=1;
c=1;
img{1} = imread(fn{i});
img{2} = img{1}(:,:,1);
img{3} = img{1}(:,:,2);
color = {'', ' RED', ' GREEN'};

f = figure(1);
shown = imshow(img{c});
title('1');
f.NextPlot = 'replacechildren';
f.WindowState = 'maximized';
f.WindowKeyPressFcn = @eKeyPress;

function eKeyPress(sou,eve)
    global img f fn i c color shown;
    switch eve.Key
        case 'uparrow'
            c = mod(c,3)+1;
            shown.CData = img{c};
            title(strcat(num2str(i),color{c}));
            drawnonw
        case 'downarrow'
            c = c-1;
            if c == 0
                c=3;
            end
            shown.CData = img{c};
            title(strcat(num2str(i),color{c}));
            drawnonw
        case 'leftarrow'
            if i == 1
                return
            else
                i = i-1;
                img{1} = imread(fn{i});
                img{2} = img{1}(:,:,1);
                img{3} = img{1}(:,:,2);
                shown.CData = img{c};
                title(strcat(num2str(i),color{c}));
                drawnonw
            end
        case 'rightarrow'
            if i == length(fn)
                return
            else
                i = i+1;
                img{1} = imread(fn{i});
                img{2} = img{1}(:,:,1);
                img{3} = img{1}(:,:,2);
                shown.CData = img{c};
                title(strcat(num2str(i),color{c}));
                drawnonw
            end
    end
end
    
