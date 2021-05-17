%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%       Version 1.0
%       Updated 06/04/2021
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
close all
clc

%Dimensione dei box in cui verrà fatta l'integrazione espressa in pixel.
box=4;
umforpx = 0.183; %micrometri per pixel nella nostra immagine (1920x1080)

%% Importazione dati contrasto da file di testo
A = importdata('Cvalues_light30.txt','\t',1);
N = A.data(end,1);
MLmaxR = A.data(end,2);
MLminR = A.data(end,3);
VarmaxR = A.data(end,4);
MLmaxG = A.data(end,5);
MLminG = A.data(end,6);
VarmaxG = A.data(end,7);


%%  Importazione file di correzione uniformità background
Ccorr = double(rgb2gray(imread('Ccorr.bmp')));
[Cx,Cy] = size(Ccorr);
Ccenter = Ccorr(round(Cx/2),round(Cy/2));
Ccorr = Ccorr/Ccenter;

%% Importazione di tutte le immagini
fnv = dir('img-*.bmp');
num_image = length(fnv);
for ii=1:num_image
   fn{ii} = fnv(ii).name; 
end

defanswer = {'10'};
inputdata = inputdlg({'Numero di iterazioni'}, 'Inserire dati', [1 50],defanswer);
if isempty(inputdata)
    return
end
iter = str2num(inputdata{1});

for ii=1:num_image
    fileflake=imread(fn{ii});
    f=figure(1);
    imshow(fileflake);
    title('Selezionare area di BACKGROUND');
    rect1 = getrect;
    close(f);
    f=figure(2);
    imshow(fileflake);
    title('Selezionare area di GRAFENE');
    rect2 = getrect;
    close(f);
    imgry = double(imcrop(fileflake,rect1));
    Int_bg = round(mean(imgry,[1,2]),3);

    fileflake = double(fileflake);
    flake = zeros(size(fileflake));
    C = zeros(size(fileflake));

    for j = (1:3)
        flake(:,:,j) = fileflake(:,:,j)+(1-Ccorr).*Int_bg(j);
        C(:,:,j) = flake(:,:,j)./Int_bg(j); %calcolo la matrice contrasto RGB
    end

    C = imcrop(C,rect2);
    vC{ii} = C;
end

NvCmeanR = zeros([num_image,2]);
NvCmeanG = zeros([num_image,2]);
NvCvarR = zeros([num_image,1]);
NvCvarG = zeros([num_image,1]);

for tt=1:iter
    for ii=1:num_image
        C = vC{ii};        

        % calcolo la matrice contrasto mediata
        s1  = size(C, 1);
        s2  = size(C, 2);
        MLCbin = zeros([floor(s1/box),floor(s2/box)]);
        nn=1;
        
        for k=1:floor(s2/box)
            for j=1:floor(s1/box)
                subC = C((1+(box*j-box)):box*j,(1+(box*k-box)):box*k,:);

                medC = round(mean(subC,[1,2]),3);
                varC = round(std(subC,0,[1,2]),3);

     % converto l'immagine di contrasto medio in 0 e 1, dove 1 sono quei pixel
     % aventi contrasto entro MLmin e MLmax e gradiente inferiore a Gradmax

                if (medC(1) <= MLmaxR) && (medC(1) >= MLminR) && (varC(1) <= VarmaxR)
                    if (medC(2) <= MLmaxG) && (medC(2) >= MLminG) && (varC(2) <= VarmaxG)
                        MLCbin(j,k)=1;
                        
                        vCmeanR(nn) = medC(1);
                        vCmeanG(nn) = medC(2);
                        vCvarR(nn)= std(subC(:,:,1),0,'all');
                        vCvarG(nn)= std(subC(:,:,2),0,'all');
                        
                        nn = nn+1;
                    end
                end
            end                                                                                                                                                            
        end
        
        NvCmeanR(ii,1) = max(vCmeanR);
        NvCmeanR(ii,2) = min(vCmeanR);
        NvCmeanG(ii,1) = max(vCmeanG);
        NvCmeanG(ii,2) = min(vCmeanG);
        NvCvarR(ii) = max(vCvarR);
        NvCvarG(ii) = max(vCvarG);
    end
    
    tol = 0.001;
    MLmaxR = (tt*MLmaxR + (max(NvCmeanR(:,1)) + tol))/(tt+1);
    MLminR = (tt*MLminR + (min(NvCmeanR(:,2)) - tol))/(tt+1);
    VarmaxR = (tt*VarmaxR + (max(NvCvarR) + tol))/(tt+1);
    tol = 0.001;
    MLmaxG = (tt*MLmaxG + (max(NvCmeanG(:,1)) + tol))/(tt+1);
    MLminG = (tt*MLminG + (min(NvCmeanG(:,2)) - tol))/(tt+1);
    VarmaxG = (tt*VarmaxG + (max(NvCvarG) + tol))/(tt+1);
    
    clear vCmeanR vCmeanG vCvarR vCvarG
end

values = [N+num_image, MLmaxR, MLminR, VarmaxR, MLmaxG, MLminG, VarmaxG];

fid = fopen('Cvalues_light30.txt','a+');
fprintf(fid, '%d \t %.3f \t %.3f \t %.3f \t %.3f \t %.3f \t %.3f\n', values);
fclose(fid);

disp(values);

% movefile img* used