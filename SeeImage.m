%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Script per scorrere immagini RGB e nei singoli canali R e G

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global img imgR imgG f fn i color;


fnv = dir('img-*.bmp');
num_image = length(fnv);
for ii=1:num_image
   fn{ii} = fnv(ii).name; 
end

i=1;
img = imread(fn{i});
imgR = img(:,:,1);
imgG = img(:,:,2);

f = figure(1);
f.NextPlot = 'replacechildren';
f.WindowKeyPressFcn = @eKeyPress;

imshow(img);



function eKeyPress(sou,eve)
    global img imgR imgG f fn i color;
    switch eve.Key
        case 'r'
            imshow(imgR, 'Parent', f);
            color = 'r';
        case 'g'
            imshow(imgG, 'Parent', f);
            color = 'g';
        case 'c'
            imshow(img, 'Parent', f);
            color = 'c';
        case 'leftarrow'
            if i == 1
                return
            else
                img = imread(fn{i-1});
                imgR = img(:,:,1);
                imgG = img(:,:,2);
                imshow(img, 'Parent', f);
            end
        case 'rightarrow'
            if i == length(fn)
                return
            else
                img = imread(fn{i+1});
                imgR = img(:,:,1);
                imgG = img(:,:,2);
                imshow(img, 'Parent', f);
            end
    end
end
    
