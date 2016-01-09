function [ floads , sum ] = helper( settlements,oloads ,rows , cols,inc,frac )
floads=oloads;
sum=0;
TOL=0.000001;
% midx= (rows+1)/2;
% midy= (cols+1)/2;
average=mean2(settlements);
for i = 1: rows
    for j= 1:cols
           if(average-settlements(i,j) > TOL)
            temp = (average/settlements(i,j))*inc;
            floads(i,j)=floads(i,j)+temp; 
           end
                
    end
end

%summing for new total load

for i=1: rows
    for j=1:cols
    sum=sum+floads(i,j);
    end
end
disp(sum)
end

