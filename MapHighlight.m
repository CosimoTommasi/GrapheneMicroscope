%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%       Version 1.0
%       Updated 30/03/2021
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc


fnv = dir('img-*.bmp');
for ii = 1:length(fnv)
    fn = fnv(ii).name;
    k = strfind(fn,'_');
    num(ii) = str2num(fn(5:k-1));
end

k = strfind(fn,'_');
j = strfind(fn,'.');
cols = str2num(fn(k+6:j-1));

defanswer = {'PMMA_Davide','4002'};
inputdata = inputdlg({'Nome del file della mappa senza estensione','Numero totale di immagini'}, 'Inserire dati', [1 50],defanswer);
mapfile = [inputdata{1},'.bmp'];
num_images = str2num(inputdata{2});

f=figure();
mapimage = imread(mapfile);
imshow(mapimage);
title('Selezionare immagine senza bordi');
rect=getrect();
close(f);
mapimage=imcrop(mapimage,rect);
f=figure();
imshow(mapimage);
hold on;

mapsize = size(mapimage);
rows = num_images/cols;
tileY = mapsize(1)/rows;
tileX = mapsize(2)/cols;    

for ii = 1:length(num)
    imgrow = rows - mod(num(ii)-1,rows);
    imgcol = ceil(num(ii)/rows);
    imgX = 1 + (imgcol-1)*tileX;
    imgY = 1 + (imgrow-1)*tileY;

    pos = [imgX, imgY, tileX, tileY];
    rectangle('Position', pos, 'LineWidth', 2, 'EdgeColor' , 'r');
end