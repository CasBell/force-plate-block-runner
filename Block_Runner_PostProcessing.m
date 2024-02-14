%  Data processing   
%  Caspian Bell
%  United States Military Academy
%  West Point, NY

% Define global variables for game
global r_wbs vfwd N arena_w harena f angle_wbs w corners_b stance health lossfactor thealth hBlocks2D sensitivity acc dist path condition sortv len wid mN rN lN COPx COPy T Note penalty vidObj secn n;

% Excursions calculations
TXml=sum(diff(COPx));

TXap=sum(diff(COPy));

% Acceleration and Velocity calculations
ts=diff(T);

VELap=mean(diff(COPx)/ts);
ACCml=mean((diff(COPy)/ts)/ts);

% Penalty calculations

pen=mean(penalty);

% TNSP calculations

TX=sqrt(COPx.^2+COPy.^2);
lineY=(len/(3*n)) * 1:n;
strt=1;
COPmod=[];
SD=[];
for i = 1:n
    SD=std()
    for j = strt:find(Ypos==lineY(i))
        COPmod(i,j)=mean(TX(strt:j));
    end
    strt=find(Ypos==lineY(i))+1;
end
