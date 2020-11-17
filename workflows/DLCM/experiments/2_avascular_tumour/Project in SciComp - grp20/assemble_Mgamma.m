% Function that allocates the boundary matrix Mgamma.
% Output: M the allocated mass matrix
% Input: p the point matrix, t the connectivity matrix 
function Mgamma = assemble_Mgamma(p,t)
    np = size(p,2); % Number of nodes 
    nt = size(t,2); % Number of boundary edges
    Mgamma = sparse(np,np); % Allocate mass matrix 
    
    inds = [1,2;2,3;3,1];
    len = ones(1,3)*sqrt((p(1,1) - p(1,2))^2 + (p(2,1) - p(2,2))^2);
    for K = 1:nt
    loc2glb = t(1:3,K); 
    x = p(1,loc2glb); % x-coordinates of triangle nodes
    y = p(2,loc2glb); % y-coordinates of triangle nodes
    for ii = 1:length(loc2glb)
       if x(inds(ii,1)) ~= x(inds(ii,2)) && y(inds(ii,1)) ~= y(inds(ii,2))
           zeroInd = inds(ii,:);
       end
    end
    MK = [2 1 1; 1 2 1; 1 1 2]/(4*6).*len; % element mass matrix
    MK(zeroInd(1),zeroInd(2)) = 0; MK(zeroInd(2),zeroInd(1)) = 0;
    Mgamma(loc2glb,loc2glb) = Mgamma(loc2glb,loc2glb)+ MK; % add element masses to M
    end
end