
% =========================================================================
%         /                                                       \
%        /                                                         \
%       /                      Block Runner                         \
%      /                                                             \
%     /       A Matlab FPV Video Game with Force Plate Controls       \
%    /                                                                 \
%   /                                                                   \
%  /                                                                     \
% =========================================================================
%  Caspian Bell, J. Josiah Steckenrider
%  United States Military Academy
%  West Point, NY

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Game setup

clear all
close all
clc

% Define global variables for game
global r_wbs vfwd N arena_w harena f angle_wbs w corners_b stance health lossfactor thealth hBlocks2D sensitivity acc dist path condition sortv len wid mN rN lN COPx COPy T Note penalty vidObj secn n;

% Initialize variable for the stored path
path = [];
dist = 0;

% Define translational and rotational "velocities"
vfwdbase = 0.1; % Translational forward
vfwd = vfwdbase;
w = 0.1; % Rotational

% Define force plate sensitivity
sensitivity = 30;

% Define camera focal length
f = 1; % Focal length

% Define width between feet
stance = 0;

%Initialize parameters
COPx=[];
COPy=[];
Note=[];
T=[];
penalty=[];
secn=null(1,2);

% Initialize health level and loss factor
health = 0;
lossfactor = -1;

% Get screen size
screen = get(0,'screensize');

% Define block corners in block reference frame
corners_b = [-0.5 -0.5 -0.5 -0.5 0.5 0.5 0.5 0.5 ; ...
             -0.5 -0.5 0.5 0.5 -0.5 -0.5 0.5 0.5 ; ...
             0 1 0 1 0 1 0 1]; % Origin is at bottom center of block

% Define arena boundaries
r_wa = [0 ; 0.1 ; 0]; % Vector to the back-left corner of the arena
wid = 10; % Width of arena
len = 10*wid; % Length of arena
arena_w = repmat(r_wa,1,4) + ...
    [0 wid wid 0 ; 0 0 len len ; 0 0 0 0]; % 4 corners of arena

% Define location of camera in world frame
r_wc = [5 ; 0 ; 2]; % Vector from world origin to camera position

% Define orientation of camera
yaw_c = 0; % Rotates camera about z
pitch_c = 0; % Rotates camera about y
roll_c = 0; % Rotates camera about x

% Generate rotation matrix from camera to world frame
R_cwz = [cos(-yaw_c) -sin(-yaw_c) 0 ; sin(-yaw_c) cos(-yaw_c) 0 ; 0 0 1];
R_cwy = [cos(-pitch_c) 0 sin(-pitch_c) ; 0 1 0 ; -sin(-pitch_c) 0 cos(-pitch_c)];
R_cwx = [1 0 0 ; 0 cos(-roll_c) -sin(-roll_c) ; 0 sin(-roll_c) cos(-roll_c)];
R_cw = R_cwz*R_cwy*R_cwx;

% Transform arena corners into camera frame
arena_c = R_cw*(arena_w-repmat(r_wc,1,4));

% Randomly generate blocks
rN = 40; % Number of random blocks
blockxs = min(arena_w(1,:)) + wid*rand(1,rN); % Random x-coordinates of blocks
blockys = min(arena_w(2,:))+2*len/3 +len*rand(1,rN)/3; % Random y-coordinates of blocks
blockzs = zeros(1,rN);  % All blocks are positioned on the "floor"
blockvs = zeros(1,rN);  % None of these blocks move laterally
%r_wbs = [blockxs ; blockys ; blockzs]; % Stack all world-to-block position vectors
%angle_wbs = [2*pi*rand(1,N) ; zeros(1,N) ; zeros(1,N)]; % Randomly generate block orientations

% Gernerate moving blocks
mN=20; % Number of moving blocks
Vblk=.2;
blockx=min(arena_w(1,:)) + wid*rand(1,rN); % Random x-coordinates of blocks
blocky=(1:mN)*len/(mN*3)+len/3;
blockz=zeros(1,mN);
blockv=null(1,mN);
for i=1:mN
    if rand>.5
        blockv(i)=-Vblk;
    else 
        blockv(i)=Vblk;
    end
end

% Systematiclly generate lines of blocks
l=8; % Number of blocks per line
n=5; % Number of lines
lN=l*n; % Number of blocks
N=lN+rN+mN;
ld=10; % Distance between lines 
blocksx=null(1,lN);
blocksy=null(1,lN);
blocksz=zeros(1,lN);
blocksv=zeros(1,lN);
vd=randi([1 (l+1)],1,n); % Creates martix of openings
kx=1; % Index for the next x value
ky=1; % Index for the next y value
for i=1:n % Iterates through each line
    for j=1:(l+1) % Iterates through each space on the line
        if vd(i)~=j % Skips the void spot
            blocksx(kx)=(j-.5)*wid/(l+1); % Sets a block at every non void x value
            kx=kx+1; % Increments the x index
        end
    end
    for j=1:l % Iterates through each block in a line
        blocksy(ky)=i*len/(3*n); % Sets the y value for each line evenly spaced out over the whole arena length
        ky=ky+1; % Increments the y index
    end
end

[sorty,sortIndex]=sort(cat(2,blocksy,blockys,blocky));
catx=cat(2,blocksx,blockxs,blockx);
catz=cat(2,blocksz,blockzs,blockz);
catv=cat(2,blocksv,blockvs,blockv);
sortx=catx(sortIndex);
sortz=catz(sortIndex);
sortv=catv(sortIndex);
r_wbs = [sortx; sorty; sortz]; % Stack all world-to-block position vectors
angle_wbs = [2*pi*rand(1,N) ; zeros(1,N) ; zeros(1,N)]; % Randomly generate block orientations

OPy=null(1,len/vfwd);
OPy(1)=5;
for i=1:n
    OPy(1+ld*(i-1))=vd(i);
    for j=(2:ld)
        inx=(i-1)*ld+j;
        OPy(inx)=OPy(inx-1);
    end
end

% Set up 2D plot
hfig = figure(1);
hold on
set(gcf,'units','normalized','outerposition',[0 0 1 1])
% set(gcf,'units','normalized','outerposition',[1/3 1/4 1/3 1/2])
axis equal % Make scaling correct
xlim([-1 1]) % Set x limits from -1 to 1
ylim([-1 1]) % Set y limits from -1 to 1

% Plot arena corners in 2D image
c1 = f*[(arena_c(1,1)/arena_c(2,1)) ; (arena_c(3,1)/arena_c(2,1))];
c2 = f*[(arena_c(1,2)/arena_c(2,2)) ; (arena_c(3,2)/arena_c(2,2))];
c3 = f*[(arena_c(1,3)/arena_c(2,3)) ; (arena_c(3,3)/arena_c(2,3))];
c4 = f*[(arena_c(1,4)/arena_c(2,4)) ; (arena_c(3,4)/arena_c(2,4))];
figure(1)
Xarena = [c1(1) c2(1) c3(1) c4(1) c1(1)];
Yarena = [c1(2) c2(2) c3(2) c4(2) c1(2)];
harena = line(Xarena,Yarena,'color','magenta','linewidth',1.5);

% Plot initial Score
thealth = text(0.70,0.85,'0','FontSize',16);
drawnow

% Transform location of blocks to world and camera frames and plot   
Blocks_c = cell(1,N); % Initialize cell array to store block corners in camera frame
for i = 1:N
    % For each block, determine location of corners in camera frame
    r_wb = r_wbs(:,i); % Extract vector from world origin to ith block origin
    yaw_b = angle_wbs(1,i); % Extract ith yaw
    pitch_b = angle_wbs(2,i); % Extract ith pitch
    roll_b = angle_wbs(3,i); % Extract ith roll
    R_wbz = [cos(yaw_b) -sin(yaw_b) 0 ; sin(yaw_b) cos(yaw_b) 0 ; 0 0 1];
    R_wby = [cos(pitch_b) 0 sin(pitch_b) ; 0 1 0 ; -sin(pitch_b) 0 cos(pitch_b)];
    R_wbx = [1 0 0 ; 0 cos(roll_b) -sin(roll_b) ; 0 sin(roll_b) cos(roll_b)];
    R_wb = R_wbz*R_wby*R_wbx; % Compute 3D rotation matrix for ith block
    corners_w = r_wb + R_wb*corners_b; % Transform ith block's corners into the world frame
    corners_c = R_cw*(corners_w-repmat(r_wc,1,8)); % Transform ith block's corners into camera frame
    
    % Replace vertices behind the camera with small nonzero values (0.01)
    signcheck = (sign(corners_c(2,:)) + 1)/2;
    signcheck = [ones(1,8) ; signcheck ; ones(1,8)];
    corners_c = corners_c.*signcheck;
    corners_c(corners_c == 0) = 0.01;
    Blocks_c{i} = corners_c;
    
    % Project 3D corners onto 2D plane
    c1 = f*[(corners_c(1,1)/corners_c(2,1)) ; (corners_c(3,1)/corners_c(2,1))];
    c2 = f*[(corners_c(1,2)/corners_c(2,2)) ; (corners_c(3,2)/corners_c(2,2))];
    c3 = f*[(corners_c(1,3)/corners_c(2,3)) ; (corners_c(3,3)/corners_c(2,3))];
    c4 = f*[(corners_c(1,4)/corners_c(2,4)) ; (corners_c(3,4)/corners_c(2,4))];
    c5 = f*[(corners_c(1,5)/corners_c(2,5)) ; (corners_c(3,5)/corners_c(2,5))];
    c6 = f*[(corners_c(1,6)/corners_c(2,6)) ; (corners_c(3,6)/corners_c(2,6))];
    c7 = f*[(corners_c(1,7)/corners_c(2,7)) ; (corners_c(3,7)/corners_c(2,7))];
    c8 = f*[(corners_c(1,8)/corners_c(2,8)) ; (corners_c(3,8)/corners_c(2,8))];
    
    % Stack all 8 corners' X and Y coordinates into vectors and plot
    Xblock = [c1(1) c2(1) c4(1) c3(1) c1(1) c5(1) c6(1) c8(1) c7(1) c5(1) c6(1) c2(1) c4(1) c8(1) c7(1) c3(1)];
    Yblock = [c1(2) c2(2) c4(2) c3(2) c1(2) c5(2) c6(2) c8(2) c7(2) c5(2) c6(2) c2(2) c4(2) c8(2) c7(2) c3(2)];
    hblock2D = line(Xblock,Yblock,'color','black','linewidth',1.5);
    
    % Add plot handle to array for in-the-loop plot updating
    hBlocks2D(i) = hblock2D;
    
end

% Intro to game
figure(1)
ht1 = text(-0.6,0.65,'BLOCK RUNNER','Color','green','FontSize',28);
ht2 = text(-0.6,0.5,'Avoid the blocks','Color','black','FontSize',14);
ht3 = text(-0.6,0.4,'Stay inside the arena','Color','black','FontSize',14);
ht4 = text(-0.6,0.3,'Side-to-side: lean left and right','Color','black','FontSize',14);
ht5 = text(-0.6,0.2,'Press any key to start','Color','black','FontSize',14);

% Initialize accumulator and condition variables
acc = 0;
condition = true;
 
% Define global parameters for force plate interaction
global DLLInterface;
global DataHandler;
% global hscat;
 
% Initialize the force plate
status = DLLInitialize(true);
if status == 0
    % Fatal error: there's no DLL to attach to
    error('DLL not found - cannot run application');
end
 
% Start up the dynamic linked library
status = DLLStartup();
DataHandler.DeviceCount = status;
if ( status < 0 )
    % Show error
    disp('Cannot start DLL');    
else
    disp('DLL initialized');    
    % Show the device count
    numstring = sprintf(' %d',status);
    disp(numstring)
    % Set up the device list
    if ( status > 0 )
        titles = cell( 1, status );
        for i = 1 : status
            [ ~, AmpSN ]  = DLLGetAmpID( i );
            [ model, PlatSN ] = DLLGetPlatformID( i );
            tstr = sprintf( ' %d:  %-6s%-24s%s', i, AmpSN, model, PlatSN );
            titles{1,i} = tstr;
        end
    else
        titles = '     ';
    end
    disp(titles);
end
if ( status > 0 )
    CurrentAmp = 1;
else
    CurrentAmp = 0;
end
 
% Set everything up here so as to minimize processing during live data collection
if ~DLLInterface.Running
    
    % Set up data collection
    DataHandler.PacketCount = 0;
    DataHandler.LastIndex = 0;
    DataHandler.DataCount = 0;
    DataHandler.DataPointer = 1;
    DataHandler.AmpOffset = CurrentAmp - 1;
    DataHandler.BufferPoints = 10000;      %  NB: Must be a multiple of 16
 
    % Build the mask for data copying during collection
    ndev = DataHandler.DeviceCount;
    aoff = DataHandler.AmpOffset;
    DataHandler.DataMask = false( 1, ndev * 8 * 16 );
 
    % Set up all channels as active
    nactive = 6;
    DataHandler.DataMask( aoff*8 + 2 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 3 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 4 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 5 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 6 : 8*ndev : 128*ndev ) = true;
    DataHandler.DataMask( aoff*8 + 7 : 8*ndev : 128*ndev ) = true;
 
    DataHandler.ActiveChannels = nactive;
    DataHandler.DataLength = nactive * 16;
 
    DataHandler.BufferSize = DataHandler.BufferPoints * nactive;
    DataHandler.Buffer = zeros( 1, DataHandler.BufferSize );
 
    % Call the DLL start command
    DLLCollecting(true);
 
    disp('Starting data collection');
else
    % Call the DLL stop command
    DLLCollecting(false);
    pause( 0.2 );
 
    disp('Stopping data collection');
end
 
% Interface to data collection
DataHandler.Initialized = true;
DataHandler.CallbackCount = 0;
DataHandler.CallbackList = [];
DataHandler.PacketCount = 0;
DataHandler.ActiveChannels = 0;
DataHandler.FzCutoff = 1;
DataHandler.Sample = zeros(1,6);
DataHandler.COP.X = 0;
DataHandler.COP.Y = 0;
 
% Timer creation for data acquisition polling 
handles.AcquisitionTimer = timer;

% % Set up plot [USE FOR DEVELOPMENT AND BASIC TROUBLESHOOTING]
% figure(1)
% hscat = scatter(0,0,'filled');
% xlim([-0.5 0.5])
% ylim([-0.5 0.5])

 %vidObj = VideoWriter('Block_Runner_Demo'); % Create a video object to write frames to
 %vidObj.FrameRate = 24; % Specify the frame rate of the video
 %vidObj.Quality = 100; % Specify the quality (resolution) of the video (100 is best)
 %open(vidObj) % Open the video for writing 

% User begins the game by pressing a button
waitforbuttonpress
delete(ht1)
delete(ht2)   %signal assesment/seperation FFT
delete(ht3)
delete(ht4)
delete(ht5)

%Starts the time
tic

% This is where the juicy stuff actually happens
set(handles.AcquisitionTimer, 'Name', 'Acquisition timer');
set(handles.AcquisitionTimer, 'ExecutionMode', 'fixedRate');
set(handles.AcquisitionTimer, 'Period', 0.03);
set(handles.AcquisitionTimer, 'TimerFcn', {@DLLAcquisition_Block_Runner});

start(handles.AcquisitionTimer)

% Pause until user presses key to end game
pause

% Close things down
% close(vidObj) % Close the video object once simulation is complete
tmrs = [handles.AcquisitionTimer];
for tmr = tmrs
    if tmr.Running
        stop(tmr);
        pause( 0.3 );
    end
    delete(tmr);
end
disp('Closing down the application');
DLLInitialize(false);

% % Plot the COP trace
% timesteps = 1:1:length(path);
% mask = path(:,1) ~= 0;
% maskpath = path(mask,:);
% timesteps = timesteps(mask);
% figure(2)
% plot(maskpath(:,1),maskpath(:,2))
% axis equal

% Plot the path with boxes
figure(3)
hold on
for i = 1:N
r_wb = r_wbs(:,i);
r_wb(2) = r_wb(2) + len;
Xblock = [r_wb(1)-0.5 r_wb(1)+0.5 r_wb(1)+0.5 r_wb(1)-0.5 r_wb(1)-0.5];
Yblock = [r_wb(2)-0.5 r_wb(2)-0.5 r_wb(2)+0.5 r_wb(2)+0.5 r_wb(2)-0.5];
hblock2D = line(Xblock,Yblock,'color','black');
end
arena_w(2,3:4) = arena_w(2,3:4) + len;
Xarena = [arena_w(1,:) arena_w(1,1)];
Yarena = [arena_w(2,:) arena_w(2,1)];
plot(path(:,1),path(:,2),'b')
plot(Xarena,Yarena,'m')
axis equal

% Extracts metrics from the data
Block_Runner_PostProcessing()