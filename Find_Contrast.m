clear all
close all


% Importazione file di correzione uniformità background
% corrfile = 'Ccorr.bmp';
corrfile = 'Ccorr_x3.bmp';    %zoom x3
Ccorr = double(imread(corrfile));
[Cx,Cy,Cz] = size(Ccorr);
Ccenter = Ccorr(round(Cx/2),round(Cy/2),:);
Ccorr = Ccorr./Ccenter;

Ccorr_HSV = double(rgb2hsv(imread(corrfile)));
Ccorr_HSV = Ccorr_HSV./Ccorr_HSV(round(Cx/2),round(Cy/2),:);

% Richiedo di inserire i dati
disp('SELEZIONARE FILE PER CALCOLO DEL BACKGROUND');
[bgndFNM, bgndcancel] = imgetfile();
if bgndcancel
    return
end
disp('SELEZIONARE FILE DA ANALIZZARE');
[flakeFNM, flakecancel] = imgetfile();
if flakecancel
    return
end


%% Importo immagine per stima background
imbg=(imread(bgndFNM));

%%%%%%%%%%%%%%%%%%%%% Selezione manuale dell'area %%%%%%%%%%%%%%%%%%%%%%%%%
f=figure();
imagesc(imbg);
title('Selezionare un''area con la quale stimare il background');
rect=getrect;
rectangle('Position',[rect(1),rect(2),rect(3),rect(4)]);

%% Ritaglio e mostro la zona ritagliata
imgry=imcrop(imbg, rect);

%Stimo l'intensità del background e approssimo il valore a 3 cifre
%decimali (RGB e HSV)
Int_bg = round(mean(imgry,[1,2]),3);    %vettore a 3 componenti
Int_bg_HSV = round(mean(rgb2hsv(imgry),[1,2]),3);

close(f);

%% Analizzo il grafene
f=figure();
flakeimg = double(imread(flakeFNM));
C = (flakeimg./Int_bg + (1-Ccorr) ); %calcolo la matrice contrasto RGB

flakeimg_HSV = double(rgb2hsv(imread(flakeFNM)));
S = (flakeimg_HSV./Int_bg_HSV + (1-Ccorr_HSV) ); %calcolo la matrice contrasto HSV

imshow(imread(flakeFNM));
title('Selezionare SOLO grafene');
pos=getrect;
rectangle('Position', pos);
C = imcrop(C, pos);
S = imcrop(S, pos);

tol = 0;   %tolerance parameter, ADJUST, can be zero

MLminR = min(C(:,:,1),[],'all') - tol;
MLmaxR = max(C(:,:,1),[],'all') + tol;
MLminG = min(C(:,:,2),[],'all') - tol;
MLmaxG = max(C(:,:,2),[],'all') + tol;
VarmaxR = std2(C(:,:,1)) + tol;
VarmaxG = std2(C(:,:,2)) + tol;

MLminS = min(S(:,:,2),[],'all') - tol;
MLmaxS = max(S(:,:,2),[],'all') + tol;
VarmaxS = std2(S(:,:,2)) + tol;

fprintf(1,'MLminR: %.3f \nMLmaxR: %.3f \nVarmaxR: %.3f \n', [MLminR, MLmaxR, VarmaxR]);
fprintf(1,'MLminG: %.3f \nMLmaxG: %.3f \nVarmaxG: %.3f \n', [MLminG, MLmaxG, VarmaxG]);
fprintf(1,'MLminS: %.3f \nMLmaxS: %.3f \nVarmaxS: %.3f \n', [MLminS, MLmaxS, VarmaxS]);

close(f);