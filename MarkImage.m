close all
clear all

flag = true;
while flag
    [fnm, canceled] = imgetfile();
    img = imread(fnm);
    f=figure();
    imshow(img);
    rectangle('Position',[1550, 920, 240, 20],'FaceColor','r','EdgeColor','r');
    text(1570, 880, '100 um', 'FontSize', 24, 'Color','r','FontName','Calibri');
    
    imwrite(getframe(f).cdata,strcat(fnm,'_MARKED.bmp'));
    
    repeat = questdlg('Do you want to mark another image?','','Yes','No','Yes');
    switch repeat
        case 'No'
            flag = false;
    end
    close(f);
end