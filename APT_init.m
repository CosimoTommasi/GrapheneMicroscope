SN_MX = 26002765;
SN_MY = 26002661;
SN_MZ = 49148454;

SX = 300;
SY = 200;

hfmotor = figure(100);
hfmotor.Name = 'APT Controllers';
hfmotor.MenuBar = 'none';
hfmotor.NumberTitle = 'off';
hfmotor.Position(3:4) = [3*SX SY];
clf;

global hx;
global hy;
global hz;
hx = actxcontrol('MGMOTOR.MGMotorCtrl.1',[0 0 SX SY],hfmotor);
hx.StartCtrl;
hx.HWSerialNum = SN_MX;
hx.SetBLashDist(0,0);
hy = actxcontrol('MGMOTOR.MGMotorCtrl.1',[SX 0 SX SY],hfmotor);
hy.StartCtrl;
hy.HWSerialNum = SN_MY;
hy.SetBLashDist(0,0);
hz = actxcontrol('MGMOTOR.MGMotorCtrl.1',[2*SX 0 SX SY],hfmotor);
hz.StartCtrl;
hz.HWSerialNum = SN_MZ;
hz.SetBLashDist(0,0);