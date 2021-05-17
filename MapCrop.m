%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%       Version 1.0
%       Updated 31/03/2021
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

defanswer = {'P1W1','1000','20'};
inputdata = inputdlg({'Nome del file della mappa senza estensione','Numero totale di immagini', 'Numero di colonne'}, 'Inserire dati', [1 50],defanswer);
mapfile = inputdata{1};
num_images = str2num(inputdata{2});
nx = str2num(inputdata{3});

ny = num_images/nx;

imgOverview = imread(mapfile);
sizeO = size(imgOverview);
stepX = floor(sizeO(2)/(nx));
stepY = floor(sizeO(1)/(ny));

f=figure();
imshow(imgOverview);
hold on;
for row = 1 : stepY : sizeO(1)
    line([1, sizeO(2)], [row, row], 'Color', 'k', 'LineWidth', 1);
end
for col = 1 : stepX : sizeO(2)
    line([col, col], [1, sizeO(1)], 'Color', 'k', 'LineWidth', 1);
end

ii = 64;
for xx = 1 : nx
    posX = stepX*(xx-1)+10;
    ii=ii+1;
    text(posX,20,char(ii),'Color','k','FontSize',14);
end
ii=1;
for yy = 2 : ny
    posY = (stepY*(yy-1)+20);
    ii=ii+1;
    text( 30, posY, int2str(ii), 'Color', 'k','FontSize',14);
end

OverviewGrid = getframe(f).cdata;
imwrite(OverviewGrid,imsave);
close(f);