% =========================================================================
%  Microscope
% -------------------------------------------------------------------------
% Versione 210430

clear timScope;

% Parameters
global cam;
global imgBackgnd;
global uscope_mm4pix uscope_sizex uscope_sizey;
global overview_pix4mm overview_sizex overview_sizey;
global cropsize;
global ncolor;
global flag_background bgndfile;
global overlayColor textColor dnx dny;
global tau valmax;
global timScope;

tau              = 1; 
% uscope_mm4pix    = 1.85e-4; % Zoom 7 (fondoscala)
uscope_mm4pix    = 4.3e-4; % Zoom 3
uscope_sizex     = 1920;
uscope_sizey     = 1080;
overview_pix4mm  = 400; % pixel per mm on overview
overview_sizex   = floor((25+uscope_sizex*uscope_mm4pix)*overview_pix4mm);
overview_sizey   = floor((25+uscope_sizey*uscope_mm4pix)*overview_pix4mm);
overlayColor     = [1 1 1]; 
%overlayColor     = [0.8500 0.3250 0.0980];
textColor        = [0 0 0]; 
%textColor        = [0.8500 0.3250 0.0980];
cropsize         = 3;
valmax           = 200;
ncolor           = 0;

% -------------------------------------------------------------------------
%  Create camera and motor objects, if not initialized yet
%
if length(cam)==0
    cam = webcam(1);
end
if ~exist('hfmotor')
    APT_init;
end
% -------------------------------------------------------------------------
%  Load background image
bgndfile = 'imgBackgnd.mat';
flag_background = exist(bgndfile);
if flag_background
    load('imgBackgnd.mat');
end
imgBackgnd = double(imgBackgnd);

dnx = uscope_sizex/2.4;
dny = uscope_sizey/2.4;
winInit();
focusCoeffCalc();

timScope = timer;
timScope.StartDelay = 0.1;
timScope.StartFcn = @eScopeStart;
timScope.TimerFcn = @eScopeRefresh;
timScope.Period = 0.1;
timScope.TasksToExecute = inf;
timScope.ExecutionMode = 'fixedRate';
timScope.start();


return;

% -------------------------------------------------------------------------
%  Init functions
function winInit()
    global hf1 ha1main ha1z hImage hInfo hCross hzCurs h1WinSq h1WinBL h1WinTR h1WinInfo;
    global hf2 ha2main hhist hhist2;
    global hf3 ha3main hOverview hActPos hfpts h3WinSq h3WinBL h3WinTR h3WinInfo;
    global uscope_sizex uscope_sizey overlayColor textColor;
    global overview_sizex overview_sizey;
    global focuspts flag_background XYZ hx hy hz;    
    XYZ(1) = hx.GetPosition_Position(0);
    XYZ(2) = hy.GetPosition_Position(0);
    XYZ(3) = hz.GetPosition_Position(0);
% -------------------------------------------------------------------------
% [FIGURE1: main uscope window]
    hf1 = figure(1); clf; hold on;
    hf1.Color = [1 1 1];
    hf1.Pointer = 'crosshair';
    hf1.MenuBar = 'none';
    hf1.NumberTitle = 'off';
    hf1.Name = 'uScope - press ESCAPE to stop';
    hf1.PointerShapeCData = zeros(16,16)+NaN;
    hf1.WindowButtonMotionFcn = [];
    hf1.WindowKeyPressFcn = @eKeyPress;
    hf1.WindowScrollWheelFcn = @eScroll;
    hImage = image(zeros(uscope_sizey,uscope_sizex,3));
    hImage.ButtonDownFcn = @eClick;  
    colormap hot;    
    ha1main = gca;
    hInfo = text(10+uscope_sizex/2,uscope_sizey/2-5,'','Color',overlayColor);
    hInfo.VerticalAlignment='top';
    hInfo.FontWeight = 'bold';
    hInfo.FontName = 'Courier';
    hCross = plot(0,0,'Color',overlayColor);
    hCross.ButtonDownFcn = @eClick;
    crossUpdatePos(0,0);   
    h1WinInfo = text(0,0,'size','VerticalAlignment','bottom');
    h1WinSq = plot([-1 +1 +1 -1 -1]*uscope_sizex/4+uscope_sizex/2,...
                   [-1 -1 +1 +1 -1]*uscope_sizey/4+uscope_sizey/2,'Color',overlayColor);
    h1WinBL = plot(-uscope_sizex/4+uscope_sizex/2,...
                   -uscope_sizey/4+uscope_sizey/2,'o','Color',overlayColor,...
                  'MarkerFaceColor',overlayColor,'MarkerSize',10);
    h1WinTR = plot(+uscope_sizex/4+uscope_sizex/2,...
                   +uscope_sizey/4+uscope_sizey/2,'o','Color',overlayColor,...
                  'MarkerFaceColor',overlayColor,'MarkerSize',10);
    h1WinInfo.Color = overlayColor;
    h1WinInfo.FontWeight = 'bold';
    h1WinInfo.FontName = 'Courier';
    box1UpdateLabel();
    h1WinBL.ButtonDownFcn = @eClick;
    h1WinTR.ButtonDownFcn = @eClick;
    h1WinSq.ButtonDownFcn = @eClick;
    cm1w = uicontextmenu(hf1);
    m1w0 = uimenu(cm1w,'Text','    Info','MenuSelected',@eBoxInfo);
    h1WinSq.ContextMenu = cm1w;    
    axis equal; axis tight; axis off;
    ha1z = axes; hold on;
    ha1z.XColor = overlayColor;
    ha1z.YColor = overlayColor;
    hzCurs = text(0,0,'','HorizontalAlignment','center');
    zcursorUpdate(0,0);
    hzCurs.Color = textColor;
    hzCurs.ButtonDownFcn = @eClick;
    hzCurs.EdgeColor = overlayColor;
    hzCurs.BackgroundColor = overlayColor;
    hzCurs.FontName = 'Courier';
    ha1z.Color = 'none';
    ha1z.Box = 'on';
    ha1z.XTick = [];
    ha1z.YTick = [];
    ha1z.XLim = [-1 1];
    ha1z.YLim = [-1 1];
    figureSizeReset(hf1);
% -------------------------------------------------------------------------
%  Context menu
    cm1 = uicontextmenu(hf1);
    m0 = uimenu(cm1,'Text','[C] Full &Color','MenuSelected',@eRGBSelect);
    m1 = uimenu(cm1,'Text','[R] Red Channel','MenuSelected',@eRGBSelect);
    m2 = uimenu(cm1,'Text','[G] Green Channel','MenuSelected',@eRGBSelect);
    m3 = uimenu(cm1,'Text','[B] Blue Channel','MenuSelected',@eRGBSelect);
    m4 = uimenu(cm1,'Text','[F] + focus point','MenuSelected',@eFPadd);
    m4.Separator = 'on';
    m5 = uimenu(cm1,'Text','[U] reset focus','MenuSelected',@eFPreset);
    m6 = uimenu(cm1,'Text','[I] Integrate','MenuSelected',@eIntegrateToggle);
    m6.Separator = 'on';
    m7 = uimenu(cm1,'Text','    Background','MenuSelected',@eBgndToggle);
    m8 = uimenu(cm1,'Text','[-] Use current image as Background','MenuSelected',@eBgndStore);
    m9 = uimenu(cm1,'Text','    Load image file as Background','MenuSelected',@eBgndLoad);
    mA = uimenu(cm1,'Text','[S] Save current image','MenuSelected',@eSaveImgName);
    mB = uimenu(cm1,'Text','[DEL] Stop motors and maps','MenuSelected',@eStopMotors);
    mB.Separator = 'on';
    mC = uimenu(cm1,'Text','[ESC] Stop microscope','MenuSelected',@eExit);
    m0.Checked = 'on';
    if flag_background
        m7.Checked = 'on';
        m8.Enable = 'off';
    end
    hImage.ContextMenu = cm1;
% -------------------------------------------------------------------------
% [FIGURE2: contrast anauscope_sizeysis window]
    hf2 = figure(2); clf; hold on;
    hf2.Color = [1 1 1];
    hf2.MenuBar = 'none';
    hf2.NumberTitle = 'off';
    hf2.Name = 'uScope - Hystograms ';
    hf2.WindowKeyPressFcn = @eKeyPress;
    hf2.WindowButtonMotionFcn = [];
    hhist = histogram([0 0],0:0.5:255);
    hhist.LineStyle = 'none';
    hhist2 = histogram([0 0],0:0.5:255);
    hhist2.LineStyle = 'none';
    ha2main = gca;
    ha2main.YLim = [0 5000];
    ha2main.XTick = 0:20:240;
    ha2main.XTickLabels = {  '0' '' '20\%' '' '40\%' '' '60\%' '' '80\%' ...
                      '' '100\%' '' '120\%'};
    box on;
% -------------------------------------------------------------------------
% [FIGURE3: overview window]
    hf3 = figure(3); clf; hold on;
    hf3.Color = [1 1 1];
    hf3.Pointer = 'crosshair';
    hf3.MenuBar = 'none';
    hf3.NumberTitle = 'off';
    hf3.Name = 'uScope - Overview';
    hf3.WindowButtonMotionFcn = [];
    hf3.WindowScrollWheelFcn = @eScroll;
    hf3.WindowKeyPressFcn = @eKeyPress;     
    imgOverview(1:overview_sizey,1:overview_sizex,1:3) = uint8(0);
    hOverview = image(imgOverview);
    hOverview.ButtonDownFcn = @eClick;
    ha3main = gca;
    axis equal;
    axis tight;
    %axis off;
    hActPos = plot([0 1],[0 1],'Color',overlayColor);  
    h3WinInfo = text(0,0,'size','VerticalAlignment','bottom');
    h3WinSq = plot([-1 +1 +1 -1 -1]*overview_sizex/4+overview_sizex/2,...
                   [-1 -1 +1 +1 -1]*overview_sizey/4+overview_sizey/2,'Color',overlayColor);
    h3WinBL = plot(-overview_sizex/4+overview_sizex/2,...
                   -overview_sizey/4+overview_sizey/2,'o','Color',overlayColor,...
                  'MarkerFaceColor',overlayColor,'MarkerSize',10);
    h3WinTR = plot(+overview_sizex/4+overview_sizex/2,...
                   +overview_sizey/4+overview_sizey/2,'o','Color',overlayColor,...
                  'MarkerFaceColor',overlayColor,'MarkerSize',10);
    h3WinInfo.Color = overlayColor;
    h3WinInfo.FontWeight = 'bold';
    h3WinInfo.FontName = 'Courier';
    box3UpdateLabel();
    h3WinBL.ButtonDownFcn = @eClick;
    h3WinTR.ButtonDownFcn = @eClick;
    h3WinSq.ButtonDownFcn = @eClick;
    cm3w = uicontextmenu(hf3);
    m3w0 = uimenu(cm3w,'Text','[M] StartMapping','MenuSelected',@eMapStart);
    m3w1 = uimenu(cm3w,'Text','    SaveMapRegion','MenuSelected',@eMapSave);
    m3w2 = uimenu(cm3w,'Text','    Info','MenuSelected',@eMapInfo);
    h3WinSq.ContextMenu = cm3w;    
    npt = size(focuspts,1);
    xv = [];
    yv = [];
    for ipt=1:npt
        tmp = overviewMm2pix(focuspts(ipt,1:2));
        xv(ipt) = tmp(1);
        yv(ipt) = tmp(2);
    end
    if npt==0
        xv = NaN;
        yv = NaN;
    end
    hfpts = plot(xv,yv,'o','MarkerFaceColor',[1 1 1 ],'MarkerEdgeColor',overlayColor);
    hfpts.ButtonDownFcn = @eClick;
    cm3a = uicontextmenu(hf3);
    m0 = uimenu(cm3a,'Text','Erase focal point','MenuSelected',@eEraseFP);
    m1 = uimenu(cm3a,'Text','Goto focal point','MenuSelected',@eGotoFP);
    hfpts.ContextMenu = cm3a;
    figureSizeReset(hf3);
    overviewMarkerUpdate([12.5 12.5]);
% -------------------------------------------------------------------------
%  Context menu
    cm3b = uicontextmenu(hf3);
    m3b1 = uimenu(cm3b,'Text','Overview');
    m3b11 = uimenu(m3b1,'Text','Load','MenuSelected',@eLoadOverview);
    m3b12 = uimenu(m3b1,'Text','Save','MenuSelected',@eSaveOverview);
    m3b13 = uimenu(m3b1,'Text','Erase','MenuSelected',@eEraseOverview);
    m3b2 = uimenu(cm3b,'Text','[DEL] Stop motors and maps','MenuSelected',@eStopMotors);
    m3b2.Separator = 'on';
    m3b3 = uimenu(cm3b,'Text','[ESC] Stop microscope','MenuSelected',@eExit);
    hOverview.ContextMenu = cm3b;
    
    figure(1);
    
% -------------------------------------------------------------------------
end
% -------------------------------------------------------------------------
%  Event handlers
function eScopeStart(sou,eve)
    global cam imgMain imgBackgnd XYZ;
    imgMain = double(fliplr(snapshot(cam)));
    crossUpdateLabel();
    zcursorUpdate(0,XYZ(3));
end
function eScopeRefresh(sou,eve)
    global cam imgMain imgBackgnd;
    global hzCurs hImage hhist hhist2 h1WinSq h1WinBL h1WinTR; 
    global tau XYZ ncolor valmax;
    % ---------------------------------------------------------------------
    % 1. Integration and XYZ update (double serve?)
    XYZ = motorReadXYZ();
    if tau==1
        imgMain = double(fliplr(snapshot(cam)))./imgBackgnd;
    else
        imgMain = (1-tau)*imgMain+tau*double(fliplr(snapshot(cam)))./imgBackgnd;
    end
    % ---------------------------------------------------------------------
    % 2. Just keep the correct color
    switch ncolor
        case {1,2,3}
            hImage.CData = imgMain(:,:,ncolor)*2;
        otherwise
            hImage.CData = uint8(imgMain);
    end
    % ---------------------------------------------------------------------
    % 3. Update histogram
    if ncolor>0
        Nv = hist(hImage.CData(:)/valmax*200,linspace(0,255,length(hhist.BinCounts)));
        Nv(1)   = 0;
        Nv(end) = 0;
        Nmax = max(Nv); % excluding saturations
        imax = find(Nv==Nmax);
        valmax = valmax*(hhist.BinEdges(imax)+hhist.BinWidth/2)/200;
        hhist.BinCounts = Nv;
        if strcmp(h1WinSq.Visible,'on')
            subimg = hImage.CData(floor(h1WinBL.YData:h1WinTR.YData),...
                floor(h1WinBL.XData:h1WinTR.XData))/valmax*200;
            Nv = hist(subimg(:),...
            linspace(0,255,length(hhist2.BinCounts)));
            hhist2.BinCounts = Nv;
        else
            hhist2.BinCounts = 0*hhist2.BinCounts;
        end
    else
        hhist.BinCounts  = 0*hhist.BinCounts;
        hhist2.BinCounts = 0*hhist2.BinCounts;
    end
   
    drawnow();
    crossUpdateLabel();
    if abs(hzCurs.Position(2))>0.75
        zcursorUpdate(hzCurs.Position(2),XYZ(3));
    end
    
end
function eKeyPress(sou,eve)  
    global ha1main ha1z;
    global hCross hInfo hzCurs XYZ;
    global uscope_sizex uscope_sizey uscope_mm4pix overview_pix4mm;
    global h3WinBL h3WinTR;
    switch eve.Key
        case '1'; figure(1);
        case '2'; figure(2);
        case '3'; figure(3);
        case 'space'
            if min(ha1main.Position==[0 0 1 1])~=0
                if strcmp(hCross.Visible,'on')
                    hCross.Visible='off';
                    hzCurs.Visible='off';
                    hInfo.Visible='off';
                    ha1z.Visible='off';
                else
                    hCross.Visible='on';
                    hzCurs.Visible='on';
                    hInfo.Visible='on';
                    ha1z.Visible='on';
                end
            end
            figureSizeReset(sou);
% -------------------------------------------------------------------------
        case 'leftarrow';  motorGoToXY(XYZ+[1 0 0],false);
        case 'rightarrow'; motorGoToXY(XYZ-[1 0 0],false);
        case 'uparrow';    motorGoToXY(XYZ+[0 1 0],false);
        case 'downarrow';  motorGoToXY(XYZ-[0 1 0],false);
% -------------------------------------------------------------------------
        case 'm'; eMapStart([],[]);
        case 'o'; overviewStore();
% -------------------------------------------------------------------------
        case 'f'; eFPadd([],[]);
        case 'u'; eFPreset([],[]);
% -------------------------------------------------------------------------
        case 'c'; setColorScheme(0);
        case 'r'; setColorScheme(1);
        case 'g'; setColorScheme(2);
        case 'b'; setColorScheme(3);
% -------------------------------------------------------------------------
        case 'i'; eIntegrateToggle([],[]);
        case {'subtract' 'hyphen'}; eBgndStore([],[]);
        case 'w'; boxToggle(sou)
        case 's'; eSaveImgName([],[]);
% -------------------------------------------------------------------------
        case 'delete'; eStopMotors([],[]);
        case 'escape'; eExit([],[]);
    end
end
function eScroll(sou,eve)
    pt = sou.CurrentPoint./sou.Position(3:4);
    ha = sou.Children(end);
    scrollfact = 1.5;
    if eve.VerticalScrollCount==-1            
        scrollfact = 1/scrollfact;
    end
    oldpos = ha.Position;
    WHv = oldpos(3:4)*scrollfact;
    BLv = (oldpos(1:2)-pt)*scrollfact+pt;
    if BLv(1)>0
        BLv (1)=0;
    end
    if BLv(2)>0
        BLv(2)=0;
    end
    if WHv(1)<1
        WHv(2) = WHv(2)/WHv(1);
        WHv(1)=1;
    end
    if WHv(2)<1
        
    end
    ha.Position = [BLv WHv];
end
function eClick(sou,eve)
    global z1 XYZ h1WinSq h3WinSq;
    tic;
    clickinfo.Source = sou;
    clickinfo.Event = eve;
    if (sou==h1WinSq)|(sou==h3WinSq)
        clickinfo.XData = sou.XData;
        clickinfo.YData = sou.YData;
    end
    hf = sou.Parent.Parent;
    hf.UserData = clickinfo;
    hf.WindowButtonMotionFcn = @eMove;
    hf.WindowButtonUpFcn = @eRelease;
    z1 = XYZ(3);
end
function eMove(sou,eve)
    global hx hy hz z1 
    global hf1 hCross hzCurs h1WinSq h1WinBL h1WinTR;
    global hf3 h3WinSq h3WinBL h3WinTR;
    global uscope_sizex uscope_sizey uscope_mm4pix overview_pix4mm;
    global XYZ;
    clickpt  = sou.UserData.Event.IntersectionPoint;
    clicksou = sou.UserData.Source;
    
    delta = toc;
    pt = get(gca,'CurrentPoint');
    x2 = pt(1,1);
    y2 = pt(1,2);
    if sou==hf1
        if clicksou==h1WinBL
            x1 = max(h1WinTR.XData,x2+10);
            y1 = max(h1WinTR.YData,y2+10);
            h1WinBL.XData = x2;
            h1WinBL.YData = y2;
            h1WinTR.XData = x1;
            h1WinTR.YData = y1;
            h1WinSq.XData = [x2 x1 x1 x2 x2];
            h1WinSq.YData = [y2 y2 y1 y1 y2];
            box1UpdateLabel();
        end
        if clicksou==h1WinTR
            x1 = min(x2-10,h1WinBL.XData);
            y1 = min(y2-10,h1WinBL.YData);
            h1WinBL.XData = x1;
            h1WinBL.YData = y1;
            h1WinTR.XData = x2;
            h1WinTR.YData = y2;
            h1WinSq.XData = [x1 x2 x2 x1 x1];
            h1WinSq.YData = [y1 y1 y2 y2 y1];
            box1UpdateLabel();
        end
        if clicksou==h1WinSq
            dx = x2-clickpt(1);
            dy = y2-clickpt(2);
            h1WinSq.XData = sou.UserData.XData+dx;
            h1WinSq.YData = sou.UserData.YData+dy;
            h1WinTR.XData = h1WinSq.XData(3);
            h1WinTR.YData = h1WinSq.YData(3);
            h1WinBL.XData = h1WinSq.XData(1);
            h1WinBL.YData = h1WinSq.YData(1);
            box1UpdateLabel();
        end
        if clicksou==hzCurs
            hf1.Pointer = 'custom';
            y2 = min(max(-1,y2),1);
            if abs(y2)<0.75
                hz.SetVelParams(0,0,1,3);
                newz = min(50,max(0,z1+(y2+(4*y2)^3)/50));
                zcursorUpdate(y2,newz);
                hz.SetAbsMovePos(0,newz);
                hz.MoveAbsolute(0,false);
            else
                z1 = hz.GetPosition_Position(0); 
                zcursorUpdate(y2,z1);
                vel = 4*(abs(y2)-0.75);
                hz.SetVelParams(0,0,1,vel);
                if y2>0
                    hz.SetAbsMovePos(0,50);
                else
                    hz.SetAbsMovePos(0,0);
                end
                hz.MoveAbsolute(0,false);
            end
        end
        if clicksou==hCross
            dx = x2-uscope_sizex/2;
            dy = y2-uscope_sizey/2;
            dr = sqrt(dx*dx+dy*dy);
            drclipped = min(400,dr);
            dx = dx*drclipped/dr;
            dy = dy*drclipped/dr;
            crossUpdatePos(dx,dy);
            crossUpdateLabel(dx,dy);
            hx.SetVelParams(0,0,1,abs(dx)/400);
            hy.SetVelParams(0,0,1,abs(dy)/400);
            if (dx<0)
                hx.SetAbsMovePos(0,0);
                hx.MoveAbsolute(0,0);
            else
                hx.SetAbsMovePos(0,25);
                hx.MoveAbsolute(0,0);
            end
            if (dy<0)
                hy.SetAbsMovePos(0,0);
                hy.MoveAbsolute(0,0);
            else
                hy.SetAbsMovePos(0,25);
                hy.MoveAbsolute(0,0);
            end
            motorFocalPlane(XYZ(1:2));
        end
    end
    if sou==hf3
        if clicksou==h3WinBL
            
            x1 = max(h3WinTR.XData,x2+uscope_sizex*uscope_mm4pix*overview_pix4mm);
            y1 = max(h3WinTR.YData,y2+uscope_sizey*uscope_mm4pix*overview_pix4mm);
            h3WinBL.XData = x2;
            h3WinBL.YData = y2;
            h3WinTR.XData = x1;
            h3WinTR.YData = y1;
            h3WinSq.XData = [x2 x1 x1 x2 x2];
            h3WinSq.YData = [y2 y2 y1 y1 y2];
            box3UpdateLabel();
        end
        if clicksou==h3WinTR
            x1 = min(h3WinBL.XData,x2-uscope_sizex*uscope_mm4pix*overview_pix4mm);
            y1 = min(h3WinBL.YData,y2-uscope_sizey*uscope_mm4pix*overview_pix4mm);
            h3WinBL.XData = x1;
            h3WinBL.YData = y1;
            h3WinTR.XData = x2;
            h3WinTR.YData = y2;
            h3WinSq.XData = [x1 x2 x2 x1 x1];
            h3WinSq.YData = [y1 y1 y2 y2 y1];
            box3UpdateLabel();
        end
        if clicksou==h3WinSq
            dx = x2-clickpt(1);
            dy = y2-clickpt(2);
            h3WinSq.XData = sou.UserData.XData+dx;
            h3WinSq.YData = sou.UserData.YData+dy;
            h3WinTR.XData = h3WinSq.XData(3);
            h3WinTR.YData = h3WinSq.YData(3);
            h3WinBL.XData = h3WinSq.XData(1);
            h3WinBL.YData = h3WinSq.YData(1);
            box3UpdateLabel();
        end
    end
end
function eRelease(sou,eve)
    global hf1 hf2 hf3 hli hsq hx hy hz;
    global hImage hzCurs hCross hOverview hfpts;
    global uscope_sizex uscope_sizey XYZ uscope_mm4pix;
    global flag_saveoverview;
    sou.WindowButtonMotionFcn = [];
    hf1.Pointer = 'crosshair';
    clicksou = sou.UserData.Source;
    if clicksou == hzCurs
        hz.StopImmediate(0);
        hz.SetVelParams(0,0,1,1);
        zcursorUpdate(0,hz.GetPosition_Position(0));
        flag_saveoverview = true;
    end
    if clicksou == hCross
        hx.StopImmediate(0);
        hy.StopImmediate(0);
        hx.SetVelParams(0,0,1,0.5);
        hy.SetVelParams(0,0,1,0.5);
    end
    if clicksou == hImage
        eve = sou.UserData.Event;
        px = eve.IntersectionPoint(1)-uscope_sizex/2;
        py = eve.IntersectionPoint(2)-uscope_sizey/2;
        button = eve.Button;
        if button==1
            motorGoToXY(XYZ + [px +py 0]*uscope_mm4pix,false);
        else
            % anything else?
        end
    end
    if clicksou == hOverview
        eve = sou.UserData.Event;
        tmp = overviewPix2mm(eve.IntersectionPoint(1:2));
        button = eve.Button;
        if button==1
            motorGoToXY([tmp 0],false);
        else
            % anything else?
        end
    end
    if clicksou == hfpts
        eve = sou.UserData.Event;
        if eve.Button==1
            npts = length(hfpts.XData);
            mindist = 10e10;
            for ii=1:npts
               dist = sqrt((hfpts.XData(ii)-eve.IntersectionPoint(1))^2 ...
                          +(hfpts.YData(ii)-eve.IntersectionPoint(2))^2);
               if dist<mindist
                   mindist = dist;
                   imin = ii;
               end
            end
            tmp = overviewPix2mm([hfpts.XData(imin) hfpts.YData(imin)]);
            motorGoToXY([tmp 0],false);
        end
    end
    crossUpdatePos(0,0);
    
    % needed?
    delta = toc;
    if delta>0.5
    else
    end
    
end
function eRGBSelect(sou,eve)
    global ncolor;
    cm = sou.Parent;
    nmen   = length(cm.Children);
    ncolor = sou.Position-1;
    for ii=nmen-3:nmen
        cm.Children(ii).Checked = 'off';
    end
    cm.Children(nmen-ncolor).Checked = 'on';
end
function eIntegrateToggle(sou,eve)
    global hImage tau;
    cm = hImage.ContextMenu;
    for ii=1:length(cm.Children)
        if strcmp(cm.Children(ii).Text,'[I] Integrate')
            hm = cm.Children(ii);
        end
    end
    switch hm.Checked
        case 'on'
            tau = 1;
            hm.Checked = 'off';
        case 'off'
            tau = 0.1;
            hm.Checked = 'on';
    end
end
function eBgndToggle(sou,eve)
    global hImage flag_background imgBackgnd bgndfile;
    global uscope_sizex uscope_sizey;
    cm = hImage.ContextMenu;
    for ii=1:length(cm.Children)
        if strcmp(cm.Children(ii).Text,'    Background')
            hm = cm.Children(ii);
            im = ii;
        end
    end
    switch hm.Checked
        case 'on'               
            flag_background = false;
            imgBackgnd = ones(uscope_sizey,uscope_sizex,3);
            hm.Checked = 'off';
            cm.Children(im-1).Enable = 'on';
        case 'off'
            flag_background = exist(bgndfile);
            if flag_background
                load(bgndfile);
                hm.Checked = 'on';
                cm.Children(im-1).Enable = 'off';
            end
    end
end
function eBgndStore(sou,eve)
    global hImage imgMain;
    cm = hImage.ContextMenu;
    for ii=1:length(cm.Children)
        if strcmp(cm.Children(ii).Text,'    Background')
            hm = cm.Children(ii);
        end
    end
    switch hm.Checked
        case 'off'
            bgndStore(imgMain);
        case 'on'
           msgbox('First disable the background pls...');
    end
end
function eBgndLoad(sou,eve)
    global uscope_sizex uscope_sizey;
    fn = imgetfile;
    if length(fn)>0
        tmp = imread(fn);
        if all(size(tmp)==[uscope_sizey uscope_sizex 3])
            bgndStore(double(tmp));
        end
    end
    endfunction eFPadd(sou,eve)
    global focuspts XYZ hfpts;
    npts = size(focuspts,1);
    if npts<3
        focuspts(npts+1,1:3)=XYZ;
        tmp = overviewMm2pix(XYZ(1:2));
        hfpts.XData = [hfpts.XData tmp(1)];
        hfpts.YData = [hfpts.YData tmp(2)];
    else
        warndlg('Focal plane active: first erase info by pressing "U"');
    end
    focusCoeffCalc();
    crossUpdateLabel();
end
function eFPreset(sou,eve)
    global focuspts hfpts;
    focuspts = [];
    hfpts.XData = [];
    hfpts.YData = [];
    focusCoeffCalc();
end
function eFPadd(sou,eve)
    global focuspts hfpts XYZ;
    npt = size(focuspts,1);
    if npt<3
        focuspts(npt+1,1) = XYZ(1);
        focuspts(npt+1,2) = XYZ(2);
        focuspts(npt+1,3) = XYZ(3);
        newpt = overviewMm2pix(XYZ(1:2));
        hfpts.XData(npt+1) = newpt(1); 
        hfpts.YData(npt+1) = newpt(2); 
    end
    focusCoeffCalc(); 
end
function eSaveImg(sou,eve,n,ncols)
    global imgMain;
    fn = sprintf('img-%d_cols-%d.bmp',[n,ncols]);
    imwrite(flipud(uint8(imgMain)),fn);
end
function eSaveImgName(sou,eve)
    global imgMain;
    fn = inputdlg('Insert image name with extension:  ','Input');
    imwrite(flipud(uint8(imgMain)),fn{1});
end
function eStopMotors(sou,eve)
    global flag_stopmapping;
    flag_stopmapping = true;
    motorGoToXY(motorReadXYZ(),false);
end
function eExit(sou,eve)
    global hf1 hImage hzCurs hCross timScope;
    hf1.Name = 'uScope stopped!';
    hImage.ButtonDownFcn = [];
    hzCurs.ButtonDownFcn = [];
    hCross.ButtonDownFcn = [];
    timScope.delete();
end
function eLoadOverview(sou,eve)
    global hOverview;
    fn = imgetfile;
    if length(fn)>0
        tmp = imread(fn);
        if all(size(tmp)==size(hOverview.CData))
            hOverview.CData = flipud(tmp);
        end
    end
end
function eSaveOverview(sou,eve)
    global hOverview;
    fn = imsave;
    imwrite(flipud(hOverview.CData),fn);
end
function eEraseOverview(sou,eve)
    global hOverview;
    hOverview.CData = hOverview.CData*0;
end
function eEraseFP(sou,eve)
    global focuspts hfpts;
    pt = get(gca,'CurrentPoint');
    npts = length(hfpts.XData);
    mindist = 10e10;
    for ii=1:npts
       dist = sqrt((hfpts.XData(ii)-pt(1,1))^2 ...
                  +(hfpts.YData(ii)-pt(1,2))^2)
       if dist<mindist
           mindist = dist;
           imin = ii;
       end
    end
    tmp = focuspts([1:(imin-1) (imin+1):npts],1:3);
    focuspts = tmp;
    xv = [];
    yv = [];
    for ii=1:npts-1
        tmp = overviewMm2pix(focuspts(ii,1:2))
        xv(ii) = tmp(1);
        yv(ii) = tmp(2);
    end
    hfpts.XData = xv;
    hfpts.YData = yv;
    focusCoeffCalc();
end
function eGotoFP(sou,eve)
    global focuspts hfpts;
    pt = get(gca,'CurrentPoint');npts = length(hfpts.XData);
    mindist = 10e10;
    for ii=1:npts
       dist = sqrt((hfpts.XData(ii)-pt(1,1))^2 ...
                  +(hfpts.YData(ii)-pt(1,2))^2)
       if dist<mindist
           mindist = dist;
           imin = ii;
       end
    end
    motorGoToXY(focuspts(imin,:),false);
end
function eMapStart(sou,eve)
    global XYZ h3WinBL h3WinTR uscope_mm4pix uscope_sizex uscope_sizey overview_pix4mm;
    global flag_stopmapping;
    global overviewXY nx ny;
    global imgMain;
    
    answer = questdlg('Before proceeding, the current view should be set on a clean, broad background region. Do you want to proceed?',...
        'Warning','Yes','No','Yes');
    switch answer
        case 'No'
            return
    end
    
    flag_stopmapping = false;
    initXYZ = XYZ;
    overlap = 200;
    
    % Map center in mm coordinates
    mapc  = overviewPix2mm([(h3WinBL.XData+h3WinTR.XData)/2 ...
                            (h3WinBL.YData+h3WinTR.YData)/2]);
    % Map size in mm coordinates (note xflip)
    mapWH =[(h3WinTR.XData-h3WinBL.XData) ...
            (h3WinTR.YData-h3WinBL.YData)]/overview_pix4mm;
    % Number of requested frames ny*nx
    mapWHpix = mapWH/uscope_mm4pix;
    nx = floor((mapWHpix(1)-overlap)/(uscope_sizex-overlap));
    ny = floor((mapWHpix(2)-overlap)/(uscope_sizey-overlap));
    pt(3) = NaN;
    pt(1) = -nx/2*(uscope_sizex-overlap)*uscope_mm4pix;
    pt(2) = -ny/2*(uscope_sizey-overlap)*uscope_mm4pix;
    overviewXY = floor( (mapc + pt(1:2))./uscope_mm4pix - [uscope_sizex uscope_sizey]/2);
    
    questdlg('Select image for lighting correction','Lighting correction','Ok','Ok');
    [corrfile, corrcancel] = imgetfile();
    if corrcancel
        return
    end
    
    Ccorr = double(rgb2gray(imread(corrfile)));
    [Cx,Cy] = size(Ccorr);
    Ccenter = Ccorr(round(Cx/2),round(Cy/2),:);
    Ccorr = Ccorr/Ccenter;
    Ccorr_HSV = double(rgb2hsv(imread(corrfile)));
    Ccenter_HSV = Ccorr_HSV./Ccorr_HSV(round(Cx/2),round(Cy/2),:);
    Ccorr_HSV = Ccorr_HSV./Ccenter_HSV;
    [Int_bg,Int_bg_HSV] = pickBgnd();
    
    outputfile={'Img #', '# of ML','max area [um^2]'};

    timetot = (nx+1)*(ny+1)*(2.2 + 1/2.7);  %estimated total map time
    mintot = floor(timetot/60);
    sectot = floor(mod(timetot,60));
    
    f = waitbar(0,strcat('Estimated remaining time: ',num2str(mintot),'min',num2str(sectot),'sec'),...
        'Name','Map Progression', 'CreateCancelBtn','setappdata(gcbf,''Cancel'',1)');
    setappdata(f,'Cancel',0);
    
    ii=1;
    index=1;
    for ix = (-nx/2):(nx/2)
        pt(1) = + ix*(uscope_sizex-overlap)*uscope_mm4pix;
        for iy = (-ny/2):(ny/2)
            pt(2) = + iy*(uscope_sizey-overlap)*uscope_mm4pix;
            motorGoToXY([mapc 0]+pt,true);
            pause(1);
            eScopeRefresh([],[]);
            overviewStore();
            eSaveImg([],[],ii,nx+1);
            
            image = flipud(uint8(imgMain));
            [flakenum, areamax] = flakeFind(image,Ccorr,Ccorr_HSV,Int_bg,Int_bg_HSV,ii);
            if ~isempty(flakenum)
                outputfile{index+1,1}=ii;
                outputfile{index+1,2}=flakenum;
                outputfile{index+1,3}=areamax;
                index = index+1;
            end
            
            timerem = timetot*(1 - ii/((nx+1)*(ny+1)));    %estimated remaining time
            minrem = floor(timerem/60);
            secrem = floor(mod(timerem,60));
            waitbar(ii/((nx+1)*(ny+1)),f,strcat('Estimated remaining time:  ',num2str(minrem),'min',num2str(secrem),'sec'));
            
            ii=ii+1;
            if or(flag_stopmapping, getappdata(f,'Cancel'))
                break;
            end
        end
        if or(flag_stopmapping, getappdata(f,'Cancel'))
            break;
        end
    end
    
    delete(f);
    
    motorGoToXY(initXYZ,false);
    pause(1);
    saveflag = questdlg('Do you want to save the Map and Data?','Save Map');
    switch saveflag
        case 'Yes'
            eMapSave([],[]);
            operation=['xlswrite(','''Results', '.xls''',',' ' outputfile' ')'];
            eval(operation);
    end
end
function eMapSave(sou,eve)
    global h3WinBL h3WinTR uscope_mm4pix uscope_sizex uscope_sizey overview_pix4mm;
    global hOverview;
    overlap = 200;
    % Map center in overview pix coordinates
    mapc_opix  = [(h3WinBL.XData+h3WinTR.XData)/2 ...
                  (h3WinBL.YData+h3WinTR.YData)/2];
    % Map size in camera pix coordinates 
    mapWH_cpix = [(h3WinTR.XData-h3WinBL.XData)  ...
                  (h3WinTR.YData-h3WinBL.YData)] ...
                  /overview_pix4mm/uscope_mm4pix;
    nx = floor((mapWH_cpix(1)-overlap)/(uscope_sizex-overlap));
    ny = floor((mapWH_cpix(2)-overlap)/(uscope_sizey-overlap));
    % Map size in overview pix coordinates
    mapWH_opix = [(nx+1)*uscope_sizex-nx*overlap ...
                  (ny+1)*uscope_sizey-ny*overlap ] ...
                  * uscope_mm4pix * overview_pix4mm;
    xv = round(((-mapWH_opix(1)/2):(+mapWH_opix(1)/2))+mapc_opix(1));
    yv = round(((-mapWH_opix(2)/2):(+mapWH_opix(2)/2))+mapc_opix(2));
    
    imgOverview=flipud(hOverview.CData(yv,xv,1:3));
    sizeO = size(imgOverview);
    stepX = floor(sizeO(2)/(nx+1));
    stepY = floor(sizeO(1)/(ny+1));
    
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
    for xx = 1 : nx+1
        posX = stepX*(xx-1)+10;
        ii=ii+1;
        text(posX,20,char(ii),'Color','k','FontSize',14);
    end
    ii=1;
    for yy = 2 : ny+1
        posY = (stepY*(yy-1)+20);
        ii=ii+1;
        text( 30, posY, int2str(ii), 'Color', 'k','FontSize',14);
    end
    
    OverviewGrid = getframe(f).cdata;
    imwrite(OverviewGrid,imsave);
    close(f);
    
    defanswer = {'map_log.txt','30'};
    inputs = inputdlg({'Insert map log file name: ','Insert lighting value in percentage:  '}, 'Input',[1,50],defanswer);
    logF = fopen(inputs{1},'w');
    fprintf(logF, '[DATA LOG FOR SAMPLE SCAN]\n');
    fprintf(logF, 'rows \t columns \t tot \t light \n');
    fprintf(logF,'%d \t %d \t %d \t %d \n', [ny+1, nx+1, (ny+1)*(nx+1), str2num(inputs{2})]);
    fclose(logF);
    
end
function eMapInfo(sou,eve)
    global h3WinBL h3WinTR uscope_mm4pix uscope_sizex uscope_sizey overview_pix4mm;
    overlap = 200;
    mapWH =[(h3WinTR.XData-h3WinBL.XData) ...
            (h3WinTR.YData-h3WinBL.YData)]/overview_pix4mm;
    % Number of requested frames ny*nx
    mapWHpix = mapWH/uscope_mm4pix;
    nx = floor((mapWHpix(1)-overlap)/(uscope_sizex-overlap));
    ny = floor((mapWHpix(2)-overlap)/(uscope_sizey-overlap));
    msgbox(sprintf('Selecte area corresponds to %d x %d = %d images',nx+1,ny+1,(nx+1)*(ny+1)),'Map info');
end
function eBoxInfo(sou,eve)
    global h1WinInfo h1WinSq uscope_mm4pix;
    dx = h1WinSq.XData(2)-h1WinSq.XData(1);
    dy = h1WinSq.YData(3)-h1WinSq.YData(2);
    dxum = dx*uscope_mm4pix*1e3;
    dyum = dy*uscope_mm4pix*1e3;
    msgbox(sprintf('Selected area = %.1f x %.1f = %.1f um2\nDiagonal = %.1f um',...
        dxum,dyum,dxum*dyum,sqrt(dxum^2+dyum^2)),'Box info');
end
% -------------------------------------------------------------------------
%  Motor utilities
function motorGoToXY(target,flag)
    global hx hy flag_moved;
    hx.SetAbsMovePos(0,target(1));
    hx.MoveAbsolute(0,flag); % flag=true aspetta fine movimento 
    hy.SetAbsMovePos(0,target(2));
    hy.MoveAbsolute(0,flag);
    motorFocalPlane(target);
    flag_moved = true;
end
function motorFocalPlane(target)
    global hz focus focuscoeff;
%     if focus.npt==3
%         zval = focus.CC(1)*target(1) ...
%              + focus.CC(2)*target(2)+focus.CC(3);
%         hz.SetAbsMovePos(0,zval);
%         hz.MoveAbsolute(0,0);
%     end
    if length(focuscoeff)>0
        zval = focuscoeff(1)*target(1) ...
             + focuscoeff(2)*target(2)+focuscoeff(3);
        hz.SetAbsMovePos(0,zval);
        hz.MoveAbsolute(0,0);
        zcursorUpdate(0,zval);
    end   
    
end
function pos = motorReadXYZ()
    global hx hy hz;
    pos(1) = hx.GetPosition_Position(0);
    pos(2) = hy.GetPosition_Position(0);
    pos(3) = hz.GetPosition_Position(0);
    overviewMarkerUpdate(pos(1:2));
end
function res = motorNotMoving()
    global hx hy hz;
    res = true;
    %fprintf('%d\n',hx.GetStatusBits_Bits(0)+2^31);
    if hx.GetStatusBits_Bits(0)+2^31~=1024
        res = false;
    end
    if hy.GetStatusBits_Bits(0)+2^31~=1024
        res = false;
    end
end
% -------------------------------------------------------------------------
%  Other utilities
function boxToggle(sou)
    global hf1 h1WinSq h1WinBL h1WinTR h1WinInfo;
    global hf3 h3WinSq h3WinBL h3WinTR h3WinInfo;
    if sou == hf1
        if strcmp(h1WinSq.Visible,'on')
            h1WinSq.Visible = 'off';
            h1WinBL.Visible = 'off';
            h1WinTR.Visible = 'off';
            h1WinInfo.Visible = 'off';
        else
            h1WinSq.Visible = 'on';
            h1WinBL.Visible = 'on';
            h1WinTR.Visible = 'on';
            h1WinInfo.Visible = 'on';
        end
    end
    if sou == hf3
        if strcmp(h3WinSq.Visible,'on')
            h3WinSq.Visible = 'off';
            h3WinBL.Visible = 'off';
            h3WinTR.Visible = 'off';
        else
            h3WinSq.Visible = 'on';
            h3WinBL.Visible = 'on';
            h3WinTR.Visible = 'on';
        end
    end
end
function box1UpdateLabel()
    global h1WinInfo h1WinSq uscope_mm4pix;
    dx = h1WinSq.XData(2)-h1WinSq.XData(1);
    dy = h1WinSq.YData(3)-h1WinSq.YData(2);
    dxum = dx*uscope_mm4pix*1e3;
    dyum = dy*uscope_mm4pix*1e3;
    h1WinInfo.String = sprintf('%.1fx%.1f um2',dxum,dyum);
    h1WinInfo.Position = [10+h1WinSq.XData(1) h1WinSq.YData(3)];
end
function box3UpdateLabel()
    global h3WinInfo h3WinSq overview_pix4mm;
    dx = h3WinSq.XData(2)-h3WinSq.XData(1);
    dy = h3WinSq.YData(3)-h3WinSq.YData(2);
    dxmm = dx/overview_pix4mm;
    dymm = dy/overview_pix4mm;
    h3WinInfo.String = sprintf('%.2fx%.2f mm2',round(dxmm,1),round(dymm,1));
    h3WinInfo.Position = [10+h3WinSq.XData(1) h3WinSq.YData(3)];
end
function setColorScheme(nc)
    global ncolor hImage;
    ncolor = nc;
    cm     = hImage.ContextMenu;
    nmen   = length(cm.Children);
    for ii=nmen-3:nmen
        cm.Children(ii).Checked = 'off';
    end
    cm.Children(nmen-ncolor).Checked = 'on';
end
function bgndStore(img)
    global imgBackgnd bgndfile;
    imgBackgnd = img;
    dn = 10;
    imgBackgnd(:,:,1)=imgBackgnd(:,:,1)/mean(mean(imgBackgnd(dn:end-dn,dn:end-dn,1)));
    imgBackgnd(:,:,2)=imgBackgnd(:,:,2)/mean(mean(imgBackgnd(dn:end-dn,dn:end-dn,2)));
    imgBackgnd(:,:,3)=imgBackgnd(:,:,3)/mean(mean(imgBackgnd(dn:end-dn,dn:end-dn,3)));
    save(bgndfile,'imgBackgnd');
end
function overviewStore()
    global overview_pix4mm uscope_sizex uscope_sizey uscope_mm4pix
    global cropsize hOverview imgMain XYZ;
    npx = overview_pix4mm/((uscope_sizex-2*cropsize)*uscope_mm4pix)+1;
    npy = overview_pix4mm/((uscope_sizey-2*cropsize)*uscope_mm4pix)+1;
    xv1 = round(linspace(1+cropsize,uscope_sizex-cropsize,npx));
    yv1 = round(linspace(1+cropsize,uscope_sizey-cropsize,npy));
    iyv = round((0+yv1*uscope_mm4pix+XYZ(2))*overview_pix4mm);
    ixv = round((0+xv1*uscope_mm4pix+XYZ(1))*overview_pix4mm);
    hOverview.CData(iyv,ixv,1:3) = imgMain(yv1,xv1,1:3);
end
function overviewMarkerUpdate(pos)
    global hActPos uscope_sizex uscope_sizey uscope_mm4pix overview_pix4mm;
    xv = [-1  1  1 -1 -1]*uscope_sizex/2*uscope_mm4pix;
    yv = [-1 -1  1  1 -1]*uscope_sizey/2*uscope_mm4pix;
    hActPos.XData = ( 0+pos(1)+xv+uscope_sizex/2*uscope_mm4pix)*overview_pix4mm;
    hActPos.YData = ( 0+pos(2)+yv+uscope_sizey/2*uscope_mm4pix)*overview_pix4mm;
end
function focusCoeffCalc()
    global hfpts focuspts focuscoeff hf1;
    if size(focuspts,1)==3
        Zv = focuspts(:,3);
        XY1m = focuspts;
        XY1m(:,3) = 1;
        if det(XY1m)~=0
            focuscoeff = inv(XY1m)*Zv;    
            hfpts.MarkerFaceColor = [0 1 0];
            hf1.Name = 'uScope - Camera feed [Focal plane is active]';
        else
            focuscoeff = [];
            hfpts.MarkerFaceColor = [1 1 1];
            hf1.Name = 'uScope - Camera feed [Invalid focal plane]';
        end
    else
        focuscoeff = []; 
        hfpts.MarkerFaceColor = [1 1 1];
        hf1.Name = sprintf('uScope - Camera feed [%d focal points]',size(focuspts,1));
    end
end
function figureSizeReset(sou)

    global hf1 ha1main ha1z;
    global hf3 ha3main;
    
    if sou==hf1
        pos = hf1.Position;
        newH = pos(3)/1920*1080;
        dH = pos(4)-newH;
        pos(4) = newH;
        pos(2) = pos(2)+dH;
        hf1.Position = pos;
        ha1main.Position = [0 0 1 1];

        npix = 30;
        x1 = max(1/3,1-2*npix/pos(3));
        y1 = min(1/3,npix/pos(4));
        dx = min(1/3,npix/pos(3));
        dy = max(1/3,1-2*npix/pos(4));
        ha1z.Position = [x1 y1 dx dy];
    else    
        pos = hf3.Position;
        newH = pos(3);
        dH = pos(4)-newH;
        pos(4) = newH;
        pos(2) = pos(2)+dH;
        hf3.Position = pos;
        ha3main.Position = [0 0 1 1];
    end
end
function crossUpdateLabel(dx,dy)
    global hInfo XYZ;
    tmpx = sprintf('%.3f\n',XYZ(1));
    if XYZ(1)<10
        tmpx = [' ' tmpx];
    end
    tmpy = sprintf('%.3f',XYZ(2));
    if XYZ(2)<10
        tmpy = [' ' tmpy];
    end
    hInfo.String = [tmpx tmpy];
end
function crossUpdatePos(posx,posy)
    global hCross uscope_sizex uscope_sizey hInfo;
    AA = 10;
    BB = 100;
    xv = [-BB -AA   0   0   0 +AA +BB +AA   0   0   0 -AA -BB NaN 0];
    yv = [  0   0 +AA +BB +AA   0   0   0 -AA -BB -AA   0   0 NaN 0];
    hCross.XData = [xv+posx 0] + uscope_sizex/2;
    hCross.YData = [yv+posy 0] + uscope_sizey/2;
    hInfo.Position = [uscope_sizex/2+10+posx uscope_sizey/2-5+posy];
end
function zcursorUpdate(pos,value)
    global hzCurs overlayColor;
    pos = max(min(pos,1),-1);
    hzCurs.Position(2) = pos;
    hzCurs.String = num2str(value,'%+.3f');
    if(abs(pos)>0.75)
        hzCurs.BackgroundColor = overlayColor/2;
    else
        hzCurs.BackgroundColor = overlayColor;
    end
end
function askHomeReset()
    global hx hy hz
    answer = questdlg('Reset to Home and go to middle position?', 'Home Reset', 'Yes', 'No', 'No');
    switch answer
        case 'Yes'
            hx.MoveHome(0,false);
            hy.MoveHome(0,false);
            hz.MoveHome(0,false);

            flag = true;        
            while flag
                pause(0.1);
                f1 = dec2bin(hx.GetStatusBits_Bits(0))-'0';
                f1 = f1(27) + f1(28);
                f2 = dec2bin(hx.GetStatusBits_Bits(0))-'0';
                f2 = f2(27) + f2(28);
                f3 = dec2bin(hx.GetStatusBits_Bits(0))-'0';
                f3 = f3(27) + f3(28);
                if (f1+f2+f3)==0
                    flag = false;
                end
            end
            hx.SetAbsMovePos(0,12.5);
            hx.MoveAbsolute(0,false);
            hy.SetAbsMovePos(0,12.5);
            hy.MoveAbsolute(0,false);
            hz.SetAbsMovePos(0,17.03);
            hz.MoveAbsolute(0,true);
    end
end
function [Int,Int_HSV]=pickBgnd()
    global imgMain;
    
    %%ADD NAVIGATION FEATURE BEFORE ACQUISITION
    
    f = figure();
    imbg = flipud(uint8(imgMain));
    imshow(imbg);
    title('Select background area in the center of the image');
    rect = getrect();
    imgry=imcrop(imbg, rect);
    
    Int = round(mean(imgry,[1,2]),3);    %vettore a 3 componenti
    Int_HSV = round(mean(rgb2hsv(imgry),[1,2]),3);
    
    close(f);
end
function [flakenum, MAXarea] = flakeFind(flakeimg,Ccorr,Ccorr_HSV,Int_bg,Int_bg_HSV,num)
    global uscope_mm4pix;
    % Parameters definition
    MLminR = 0.920;
    MLmaxR = 0.970;
    VarmaxR = 0.006;
    MLminG = 0.959;
    MLmaxG = 1.011;
    VarmaxG = 0.008;

    MLminS = 1.072; 
    MLmaxS = 1.150; 
    VarmaxS = 0.014;
    
    flakedim = 10;  % minimum flake dimension in um
    areamin = (flakedim/(uscope_mm4pix*1e3))^2;
    areamax = 10000;
    
    box = 10;
    
    % Import images and calculate contrast
    fileflake=double(flakeimg);
    fileflake_HSV=double(rgb2hsv(flakeimg));
    
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
    flakenum = [];
    MAXarea = [];
    if areaoutput_cell{3}>0
        areas = cellfun(@numel, areaoutput.PixelIdxList);
        MAXarea = round(max(areas)*(box*umforpx)^2);
        flakenum = areaoutput_cell{3};
        
        % Mostra le singole immagini
        figure(num);
        montage({MLCbin,flakeimg});
        title(num);
    end
end

% -------------------------------------------------------------------------
% Unit conversions
%
% All pictures are plotted using the function "image" which sets the origin
% of the xy axis at the top left corner of the picture, as costumary with
% screen coordinates.
%
% XY motor coordinates are conventional, with the origin a the bottom left
% corner of the picture. The motor travel range is 25cm and we should add
% to this 1/2 the size of the microscope image.
%
function pixpos = overviewMm2pix(mmpos)
    global uscope_sizex uscope_sizey uscope_mm4pix overview_pix4mm
    pixpos(1) = ((0+mmpos(1))+uscope_sizex/2*uscope_mm4pix)*overview_pix4mm;
    pixpos(2) = ((0+mmpos(2))+uscope_sizey/2*uscope_mm4pix)*overview_pix4mm;
end
function mmpos = overviewPix2mm(pixpos)
    global uscope_sizex uscope_sizey uscope_mm4pix overview_pix4mm
    mmpos(1) =  0 + pixpos(1)/overview_pix4mm-uscope_sizex/2*uscope_mm4pix;
    mmpos(2) =  0 + pixpos(2)/overview_pix4mm-uscope_sizey/2*uscope_mm4pix;
end
