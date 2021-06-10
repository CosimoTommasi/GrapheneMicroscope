%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script to visualize RGB images and switch between RGB, R and G channels

% Navigation commands:
%   →/←: change picture
%   ↑/↓: change color (RGB, R only, G only)
%   Esc: close image and exit

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

i=1;    %image index
c=1;    %color index

img{1} = imread(fn{i});
img{2} = repmat(img{1}(:,:,1), [1,1,3]);    % repmat is needed to display as grayscale
img{3} = repmat(img{1}(:,:,2), [1,1,3]);
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
            c = mod(c,3)+1;     %cycles on 1, 2, 3
            shown.CData = img{c};
            title(strcat(num_image(i),color{c}));
        case 'downarrow'
            c = c-1+3*floor(1/c);    %cycles on 1, 2, 3
            shown.CData = img{c};
            title(strcat(num_image(i),color{c}));
        case 'leftarrow'
            if i == 1
                return
            else
                i = i-1;
                c = 1;
                img{1} = imread(fn{i});
                img{2} = repmat(img{1}(:,:,1), [1,1,3]);
                img{3} = repmat(img{1}(:,:,2), [1,1,3]);
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
                img{2} = repmat(img{1}(:,:,1), [1,1,3]);
                img{3} = repmat(img{1}(:,:,2), [1,1,3]);
                shown.CData = img{c};
                title(strcat(num_image(i),color{c}));
            end
        case 'escape'
            close
    end
end
    
