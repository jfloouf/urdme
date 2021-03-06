% Function that sets initial conditions for tumour
function U_initial = setInitialCondition(IC,R1,R2,P,Nvoxels)
% IC: Initial condition (1,2,3,4,5)
%   IC1 --> orginally IC, single occupied cells
%   IC2 --> doubly occupied voxels in center
%   IC3 --> dead cells in center
%   IC4 --> random; dead/empty in center surrounded by single/doubly occupied
%   IC5 --> cell with dead center and doubly occupied voxels on boundary 
% P: point matrix from mesh
% R1: Radius of whole initial tumour
% R2: Radius of inner initial setup (doubly occupied, dead etc.)

r = sqrt(P(1,:).^2+P(2,:).^2);
h = 2/(Nvoxels-1);

if IC == 1 % circular blob of cells
    ii = find(r < 0.05); % radius of the initial blob
    U_initial = fsparse(ii(:),1,1,[Nvoxels^2 1]);
    
elseif IC == 2 % doubly occupied voxels in center
    r1 = find(r < R1); % radius whole initial tumour
    r2 = find(r < R2); % radius of doubly occupied cells
    r1 = setdiff(r1,r2);
    U_initial = fsparse([r1(:); r2(:)],1, ...
                [ones(size(r1,2),1); 2*ones(size(r2,2),1)], ...
                [Nvoxels^2 1]); 
    
elseif IC == 3 % dead cells in center
    r1 = find(r < R1); % radius of whole initial tumour
    r2 = find(r < R2); % radius of dead cells
    r1 = setdiff(r1,r2);
    U_initial = fsparse([r1(:); r2(:)],1, ...
                [ones(size(r1,2),1); -1*ones(size(r2,2),1)], ...
                [Nvoxels^2 1]); 
    
elseif IC == 4 % random cell 
    r1 = find(r < R1);
    r2 = find(r < R2);
    r1 = setdiff(r1,r2);
    
    U_initial = fsparse([r1(:); r2(:)],1, ...
                [randi([1,2],size(r1,2),1); randi([-1,0],size(r2,2),1)], ...
                [Nvoxels^2 1]); 
            
elseif IC == 5 % cell with dead center and doubly occupied voxels on boundary 
    r1 = find(r < R1);
    r2 = find(r < R2);
    r3 = find(r < R1 + h);
    r1 = setdiff(r1,r2);
    r3 = setdiff(r3, union(r1,r2));
    
    U_initial = fsparse([r1(:); r2(:); r3(:)],1, ...
                [ones(size(r1,2),1); -1*ones(size(r2,2),1); 2*ones(size(r3,2),1)], ...
                [Nvoxels^2 1]);
end