%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script per scorrere immagini RGB e nei singoli canali R e G

% I comandi per la navigazione sono i seguenti:
%     →/←: scorrimento immagini
%     ↑/↓: ciclo colori (RGB, solo R, solo G)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all;
close all;


global img fn i c color shown num_image;

fnv = dir('img-*.bmp');
N = length(fnv);
for ii=1:N
   fn{ii} = fnv(ii).name;
   j = strfind(fn{ii},'_cols');
   num_image{ii} = fn{ii}(5:j-1);
end

i=1;
c=1;
img{1} = imread(fn{i});
img{2} = img{1}(:,:,1);
img{3} = img{1}(:,:,2);
color = {'', ' RED', ' GREEN'};

f = figure(1);
shown = imshow(img{c});
f.NextPlot = 'replacechildren';
f.WindowState = 'maximized';
f.WindowKeyPressFcn = @eKeyPress;
title('1');

function eKeyPress(sou,eve)
    global img fn i c color shown num_image;
    switch eve.Key
        case 'uparrow'
            c = mod(c,3)+1; %cicla su 1, 2 e 3
            shown.CData = img{c};
            title(strcat(num_image(i),color{c}));
        case 'downarrow'
            c = c-1+3*floor(1/c);    %cicla su 1, 2 e 3
            shown.CData = img{c};
            title(strcat(num_image(i),color{c}));
        case 'leftarrow'
            if i == 1
                return
            else
                i = i-1;
                c = 1;
                img{1} = imread(fn{i});
                img{2} = img{1}(:,:,1);
                img{3} = img{1}(:,:,2);
                shown.CData = img{c};
                title(strcat(num_image(i),color{c}));
            end
        case 'rightarrow'
            if i == length(fn)
                return
            else
                i = i+1;
                c = 1;
                img{1} = imread(fn{i});
                img{2} = img{1}(:,:,1);
                img{3} = img{1}(:,:,2);
                shown.CData = img{c};
                title(strcat(num_image(i),color{c}));
            end
    end
end
    
