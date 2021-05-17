%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%       Version 4.2
%       Updated 28/04/2021
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc
%% Inizializzazione parametri vari
index=0;
%Dimensione dei box in cui verrà fatta l'integrazione espressa in pixel.
box=10;
% box = 5;    %(zoom x3)?

% umforpx = 0.183; %micrometri per pixel nella nostra immagine (zoom x7)
umforpx = 0.427; %(zoom x3)

%% Inizializzazione file di output
outputfile={'Img #', '# of ML','max area [um^2]'};

%%  Importazione file di correzione uniformità background
% corrfile = 'Ccorr.bmp';
corrfile = 'Ccorr_x3.bmp';    %zoom x3
Ccorr = double(rgb2gray(imread(corrfile)));
[Cx,Cy] = size(Ccorr);
Ccenter = Ccorr(round(Cx/2),round(Cy/2),:);
Ccorr = Ccorr/Ccenter;

Ccorr_HSV = double(rgb2hsv(imread(corrfile)));
Ccenter_HSV = Ccorr_HSV./Ccorr_HSV(round(Cx/2),round(Cy/2),:);
Ccorr_HSV = Ccorr_HSV./Ccenter_HSV;

%% Definizione valori di contrasto per ML e area dei flake (ZOOM DEPENDENT)
% Per i valori relativi allo zoom x7 consultare il file Cvalues_light30.txt
% nella cartella Ccalculation
MLminR = 0.911;
MLmaxR = 0.956;
VarmaxR = 0.008;
MLminG = 0.916;
MLmaxG = 0.973;
VarmaxG = 0.009;

MLminS = 1.027; 
MLmaxS = 1.076; 
VarmaxS = 0.009;

areamax = 10000;

%% Richiedo di inserire i dati
defanswer = {'img-','11','275','68','10'};
totinput=inputdlg({'Nome parziale del file senza numero immagine', 'Numero di colonne',...
    'Numero totale di immagini', 'Numero del file per il calcolo del background','Dimensione minima dei flake [um]'},...
    'Inserire dati', [1 50], defanswer);
disp(' ');

input0 = totinput{1};   %nome parziale del file
cols = totinput{2};     %numero di colonne
num_image = str2double(totinput{3});   %numero totale di immagini
input2 = totinput{4};   %immagine per stima del bgnd
flakedim = str2double(totinput{5});   %dimensione minima dei flake

areamin = (flakedim/umforpx)^2;   %183 nm per pixel, area in pixel

%% Importo immagine per stima background
fileinput2 = strcat(input0,input2,'_cols-',cols,'.bmp');
imbg=imread(fileinput2);

%% Selezione manuale dell'area

figure(1)
imagesc(imbg);
title('Selezionare con il cursore un''area con la quale stimare il background');
rect=getrect;
rectangle('Position',[rect(1),rect(2),rect(3),rect(4)]);

%% Ritaglio e mostro la zona ritagliata
imgry=imcrop(imbg, rect);

%Stimo l'intensità del background e approssimo il valore a 3 cifre
%decimali (RGB e HSV)
Int_bg = round(mean(imgry,[1,2]),3);    %vettore a 3 componenti
Int_bg_HSV = round(mean(rgb2hsv(imgry),[1,2]),3);

close Figure 1

%% Analisi delle singole immagini
f = waitbar(0,strcat('0/',num2str(num_image)),'Name','Analisi delle immagini',...
    'CreateCancelBtn','setappdata(gcbf,''Annulla'',1)');
setappdata(f,'Annulla',0);

for i=1:num_image
    % importo le singole immagini
    num=num2str(i);
    file=strcat(input0,num,'_cols-',cols,'.bmp');
    fileflake=double(imread(file));
    fileflake_HSV=double(rgb2hsv(imread(file)));
    
    C = ((fileflake./Int_bg) + (1-Ccorr));  %matrice contrasto RGB
    S = ((fileflake_HSV./Int_bg_HSV) + (1-Ccorr_HSV));  %matrice contrasto HSV
    
    
    % calcolo la matrice contrasto mediata
    s1  = size(C, 1);
    s2  = size(C, 2);
    MLCbin = zeros([s1/box,s2/box]);
    for k=1:s2/box
        for t=1:s1/box
            subC = C((1+(box*t-box)):box*t,(1+(box*k-box)):box*k,:);
            medC = round(mean(subC,[1,2]),3);
            varC = round(std(subC,0,[1,2]), 3);
            
            subS = S((1+(box*t-box)):box*t,(1+(box*k-box)):box*k,2);
            medS = round(mean2(subS),3);
            varS = round(std2(subS), 3);
            
 % converto l'immagine di contrasto medio in 0 e 1, dove 1 sono quei pixel
 % aventi contrasto entro MLmin e MLmax e gradiente inferiore a Gradmax
            
            if (medC(1) <= MLmaxR) && (medC(1) >= MLminR) && (varC(1) <= VarmaxR)
                if (medC(2) <= MLmaxG) && (medC(2) >= MLminG) && (varC(2) <= VarmaxG)
                    if (medS <= MLmaxS) && (medS >= MLminS) && (varS <= VarmaxS)
                        MLCbin(t,k)=1;
                    end
                end
            end
        end                                                                                                                                                            
    end
    
    % identificazione possibili flake monolayer, calcando le aree di pixel connessi spazialmente aventi dimensioni
    % entro il range definito: [min max] espresso in numero totale di pixel che compongono l'area
    areaMLCin = bwareafilt(logical(MLCbin),[areamin/box^2, areamax/box^2]);
%     imagesc(areaMLCin)
    areaoutput=bwconncomp(areaMLCin);
    areaoutput_cell=struct2cell(areaoutput);

    % Memorizzo i dati
    if areaoutput_cell{3}>0
        areas = cellfun(@numel, areaoutput.PixelIdxList);
        MAXarea = max(areas);
        fprintf('Immagine %u - area massima %u', i, MAXarea);
        disp(' ');
        
        index=index+1;
        outputfile{index+1,1}=num;
        outputfile{index+1,2}=areaoutput_cell{3};
        outputfile{index+1,3}=round(MAXarea*(box*umforpx)^2);
        
        % Mostra le singole immagini
        fig0 = figure(index);
        montage({MLCbin,imread(file)});
        title(num);
    end
    
    if getappdata(f,'Annulla')
        delete(f);
        break
    end
    waitbar(i/num_image,f,strcat(num2str(i),'/',num2str(num_image)));
end
delete(f);

operation=['xlswrite(','''Results_v4p1', '.xls''',',' ' outputfile' ')'];
eval(operation);
