function deltasigma = change( p, r , z )
% Function to calculate the change in stress at a point 
% whose coordinates are given by r and z due to load P
A=(z^3)/((r^2 + z^2)^2.5);
deltasigma= (3*p*A)/(2*pi);
end

