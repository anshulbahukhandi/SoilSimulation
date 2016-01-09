clc;
% Solves for only overconsoliddated and normally consolidated soil
%Sublayers are divided equally
%Mesh MUST be divided into even number of rows and columns

%%~~~~~~~~~~~~~~~~~~~~~~INPUT SECTION STARTS~~~~~~~~~~~~~~~~~~~~~~~~~%%
%%~~~~~~~~~~~~~~~~~~~~~~INPUT SECTION STARTS~~~~~~~~~~~~~~~~~~~~~~~~~%%
ROWS=4;              %These are rows in the mesh not load rows . Load rows in one more than this
COLUMNS=4;           %These are columns in the mesh not load columns . Load columns in one more than this 
length = 40 ;        %length of footing(meter)
width  = 40 ;        %width of footing(meter)
height = 1  ;        %height of footing(meter)
depth  = 1  ;        %depth of footing(meter)
gammaconc = 0 ;      %density of concrete(KN/m^3) to include weight of foundation
phi= 40 ;            % Angle of friction in degrees
cch = 0;             % coefficient of cohesion
gammasoil = 17;      % density of soil (KN/m^3)
clayheight = 9;      % height of clay in meters(give some even number to be precise); 
heightofsublayer=3;  %height of sublayers in meters
pp= 10 ;             %Preconsoildation Pressure in KPa
cc= 1;               % Compression Index
waterdepth = 9;      %depth of water level below the surface
lload= 192000;       %Live load in KN

deltaload =1;           % increament value  , also used to control the total load. Decrease as mesh size increases
frac= 0.6;              % fractional increament in centeral value , is used to decrease the differential settlement values
initload=0;             %  use to control the qmax
%%~~~~~~~~~~~~~~~~~~~~~~INPUT SECTION ENDS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%%
%%~~~~~~~~~~~~~~~~~~~~~~INPUT SECTION ENDS~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%%





%~~~~~~~~~~~~~~~~~~SOIL PROPERTIES~~~~~~~~~~~~~~~~~~~~%
TOL =5 ;           %percent tolerance to be normally consolidated
sublayercount = clayheight/heightofsublayer;   % number of sublayes and also number of matrices in 3rd dimenion
cr = 0.1*cc ;                                  %Recompression Index  
dh=length/COLUMNS;                             %Length of horizontal division of mesh
dv=width/ROWS;                                 %Length of vertical division of mesh
loads= zeros (ROWS+ 1,COLUMNS+ 1);             % mesh size is 10cm*10cm
dload = length * width * height * gammaconc ;  % weight of foundation 
tload = dload + lload - (length*width*depth*gammasoil);  %reducing the excacvation load from total load
fprintf('Total load to distribute : %0.3f KN\n',tload);
%~~~~~~~~~~~~~~~~~~~INITIAL EFFECTIVE STRESS MATRIX~~~~~~~~~~~~~~~~~~~~~~~~~~~%
initialstress=zeros(ROWS + 1,COLUMNS + 1,sublayercount);   %will store the initial stress  at each point
for k= 1 : sublayercount 
    z=(k-0.5)*heightofsublayer ;
    if(waterdepth<=z)
        initialstress(:,:,k)= gammasoil *z - 9.8*(z-waterdepth) ;
    else 
        initialstress(:,:,k)=gammasoil *z;
    end
end %sublayercount
%~~~~~~~~~~~~~~TAKING INPUT FROM USER FOR INITIAL VOID RATIO~~~~~~~~~~~~~~~%
%          Initial void ratios is  same throughout one sublayer 
voidratioinitial = zeros(sublayercount , 1) ; 
for  i= 1 : sublayercount
   fprintf('Enter  the initial void ratio for effective stress %0.3f :',initialstress(1,1,i));
   voidratioinitial(i,1)=input('');
end
%~~~~~~~~~~~~~~~~~CALCULATIONS~~~~~~~~~~~~~~~~~~~~~~~%
qmax = gammasoil*depth *((1+sin(phi*pi/180))/(1-sin(phi*pi/180)))^2;  %Maximum load soil can take
%~~~~~~~~~~~Initializing load distribution ~~~~~~~~~~~~~%
loads(:,:)=initload;
sum=initload*(ROWS+1)*(COLUMNS+1);
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
while(sum <tload)
%~~~~~~~~~~~~~~~~~~~CALCULATING STRESS CHANGE~~~~~~~~~~~~~~~~~~~~~~~~%
delta=zeros(ROWS + 1,COLUMNS+ 1,sublayercount);   %will store the total stress change at each point 
for k= 1 : sublayercount 
z=k*heightofsublayer - 0.5*heightofsublayer; 
    for i=1:ROWS+1
        for j=1 : COLUMNS + 1     %choosing one point 'A' in a sublayer 
        x1=(i-1)*dh;
        y1=(j-1)*dv;
            for m=1:ROWS+1      %calculating changes at 'A' due to loads at all other points
                for n=1 : COLUMNS + 1
                    x2= (m-1)*dh;
                    y2= (n-1)*dv;
                    r=sqrt((x2-x1)^2 + (y2-y1)^2);         
                    temp=change((loads(m,n)) , r , z );
                    delta(i,j,k)=delta(i,j,k)+temp;     %summing up
                end
            end
        end %j
    end    %i 
end  %sublayercount
%~~~~~~~~~~~~~~~~~~~~~~~FINAL EFFECTIVE STRESS~~~~~~~~~~~~~~~~~~~~~~~~~~~%
finalstress = initialstress + delta;   %will store the final stress  at each point
%~~~~~~~~~~~~~~~~~~~~~~~~CHECKING OC/NC SOIL~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%~~~~~~~~~~~~~~~~~CALCULATING CHANGE IN VOID RATIO~~~~~~~~~~~~~~~~~~~~~~~%
voidratiochange = zeros(ROWS+ 1,COLUMNS + 1,sublayercount);  %will store the change in void ratios at each point 
for k = 1 : sublayercount 
  
    if((pp-initialstress(1,1,k))*100/pp >TOL)        %checks if sublayer is n.c 
        fprintf('Sublayer %0.1f is overconsolidated\n',k);
        for i=1:ROWS+1
            for j=1 : COLUMNS + 1     %choosing one point 'A' in a sublayer
       
            if (finalstress(i,j,k) > pp)
            de= cr*log10(pp/initialstress(i,j,k)) + cc*log10(finalstress(i,j,k)/pp);
            voidratiochange(i,j,k)=de;
            else
            de= cr*log10(finalstress(i,j,k)/initialstress(i,j,k));
            voidratiochange(i,j,k)=de;
            end
        
            end
        end

    else       % else layer is o.c  
        fprintf('Sublayer %0.1f is normally consolidated\n',k); 
        for i=1:ROWS+1
            for j=1 : COLUMNS + 1     %choosing one point 'A' in a sublayer
            de=cc*log10(finalstress(i,j,k)/initialstress(i,j,k));
            voidratiochange(i,j,k)=de;
            end
        end
    end
end %sublayercount
%~~~~~~~~~~~~~~~~~~~~CALCULATING STRAIN AT EACH POINT~~~~~~~~~~~~~~~~~~~~~%
strain=zeros(ROWS + 1,COLUMNS+ 1,sublayercount);
for k=1 : sublayercount
temp = 1+ voidratioinitial(k,1);
  
    for i=1:ROWS+1
            for j=1 : COLUMNS + 1     %choosing one point 'A' in a sublayer
                strain(i,j,k)=voidratiochange(i,j,k)/temp;
            end
    end
end
%~~~~~~~~~~~~~~~~~~~~TOTAL STRAIN BELOW EACH POINT~~~~~~~~~~~~~~~~~~~~~~~~%
totalstrain=zeros(ROWS+ 1,COLUMNS+ 1);
for  k = 1: sublayercount
  totalstrain=totalstrain + strain(:,:,k);
    
end
%~~~~~~~~~~~~~~~~~~TOTAL SETTLEMENT UNDER EACH LOAD~~~~~~~~~~~~~~~~~~~~~~~%
settlements= heightofsublayer * totalstrain;
[floads,nsum]=helper(settlements ,loads, ROWS+1 , COLUMNS+1 , deltaload , frac);
    if(nsum~=sum || sum==0) 
        
    midx= (ROWS+2)/2;
    midy= (COLUMNS+2)/2;
    floads(midx,midy)=floads(midx,midy)+frac*deltaload;
    nsum=nsum+frac*deltaload;
    end
    
    loads=floads;
    sum=nsum; 
end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~plotting results~~~~~~~~~~~~~~~~~~~~~~%
fprintf('--------------------------------------------------------------\n');
fprintf('--------------------------------------------------------------\n');
fprintf('Maximum Stress at any point must NOT go beyond : %0.3f KN/m^2\n',qmax);
fprintf('--------------------------------------------------------------\n');
fprintf('--------------------------------------------------------------\n\n');
da=(length*width)/((ROWS+1)*(COLUMNS+1));
fprintf('--------------------------------------------------------------\n');
fprintf('--------------------------------------------------------------\n');
fprintf('Maximum Stress below the foundation and at the corners : %0.3f KN/m^2\n',loads(ROWS+1 , COLUMNS+1)/da);
fprintf('--------------------------------------------------------------\n');
fprintf('--------------------------------------------------------------\n\n');

temp1= max(max(loads)) - min(min(loads));
temp2= max(max(settlements))-min(min(settlements));
fprintf('\nRange of loads is : %0.4f KN',temp1);
fprintf('\nRange of settlements is : %0.2f meter',temp2);
settlements=-1*settlements;
 figure;
 surf(loads);
 %shading interp;
 colorbar;
 figure;
 surface(settlements);
 shading interp;
 colorbar;









