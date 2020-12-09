
%%
close all;

model = createpde(1);
Nvoxels = 121;
% gd = [3 4 -1 1 1 -1 -1 -1 1 1]';
% sf = 'SQ1';
% ns = char(sf)';
% G = decsg(gd,sf,ns);
[P,E,T,grad] = flipped_mesh(Nvoxels);
pdemesh(P,E,T)
axis equal

% [P,E,T,gradquotient] = basic_mesh(1,Nvoxels);
% [L,M] = assema(P,T,1,1,0);
% TR = triangulation(T(1:3,:)',P');
% geometryFromMesh(model,TR.Points',TR.ConnectivityList');
% specifyCoefficients(model,'m',0,'d',0,'c',1,'a',1,'f',0);
figure;
pdemesh(model)
axis equal
figure;
pdegplot(model.Geometry,'EdgeLabels','on')
axis equal
% state.time = 0;
FEM = assembleFEMatrices(model);
% applyBoundaryCondition(model,'edge',1:model.Geometry.NumEdges,'u',0);
% figure;
% spy(FEM.A)
% figure;
% spy(M);
thirdmatrix = round(M-FEM.A, 14);
figure;
title('Diff M')
spy(thirdmatrix);

% figure;
% spy(FEM.K)
% figure;
% spy(L);
thirdmatrix = round(L-FEM.K, 14);
figure;
title('Diff L')
spy(thirdmatrix);

% the (lumped) mass matrix gives the element volume
dM2 = full(sum(FEM.A,2));
ndofs = size(dM2,1);

% explicitly invert the lumped mass matrix and filter the diffusion matrix
[i,j,s] = find(FEM.K);
s = s./dM2(i);
%keep = find(s < 0); % (possibly removes negative off-diagonal elements)
keep = find(i ~= j); % (removes only the diagonal)
i = i(keep); j = j(keep); s = s(keep);

% rebuild L, ensuring that the diagonal equals minus the sum of the
% off-diagonal elements
L2 = sparse(i,j,s,ndofs,ndofs);
L2 = L2+sparse(1:ndofs,1:ndofs,-full(sum(L2,2)));

%% Find points that make up the boundary

[row,col] = find(ismember(T(1:3,:),idof1));

% indices to unique values in col
[~, ind] = unique(col, 'rows');
% duplicate indices
duplicate_ind = setdiff(1:size(col, 1), ind);
% % duplicate values
% duplicate_value = col(duplicate_ind);

cont_int_points = zeros(2,length(duplicate_ind));

for i = 1:length(duplicate_ind)
    cont_int_points(1,i) = T(row(duplicate_ind(i)-1),col(duplicate_ind(i)-1));
    cont_int_points(2,i) = T(row(duplicate_ind(i)),col(duplicate_ind(i)));
end
cont_int_points = sort(cont_int_points,1);
[~,inds] = unique(cont_int_points(1,:));
cont_int_points = cont_int_points(:,inds);

plot(P(1,cont_int_points),P(2,cont_int_points),'*')

%%

keep2 = find(ismember(Adof(jj_),idof1));
iii = reshape(ii(keep2),[],1); jjj_ = reshape(jj_(keep2),[],1);
idof1_moves = sort(max(Pr(sdof_m_(iii))-Pr(jjj_),0).*Drate_(2*VU(Adof(jjj_))+abs(U(Adof(jjj_)))+1))
m = mean(max(Pr(sdof_m_(ii))-Pr(jj_),0).*Drate_(2*VU(Adof(jj_))+abs(U(Adof(jj_)))+1))
maxmax = max(max(Pr(sdof_m_(ii))-Pr(jj_),0).*Drate_(2*VU(Adof(jj_))+abs(U(Adof(jj_)))+1))

%%
[P,E,T,gradquotient] = basic_mesh(1,121);
R = RobinMassMatrix2D(P,E);
figure; spy(R);


%%

% Number of voxels and step size h
Nvoxels = 11;
h = 2/(Nvoxels-1);

% Set up mesh and matrixes
[P,E,T,gradquotient] = basic_mesh(1,Nvoxels);
[L,dM,N,M] = dt_operators(P,T);
[L_orig,M_orig] = assema(P,T,1,1,0);
[V,R] = mesh2dual(P,E,T,'voronoi');
Mgamma = assemble_Mgamma(P,T);
Mgamma_dM = Mgamma./dM;
neigh = full(sum(N,2));

% Initial population
IC = 2; % Choose initial condition (1,2,3,4,5,6)
R1 = 0.35; % Radius of whole initial tumour
R2 = 0.10; % Radius of inner initial setup (doubly occupied, dead etc.)
Pr = setInitialCondition(IC,R1,R2,P,Nvoxels);
VPr = (Pr ~= 0);
Pr(Pr == -1) = 0;

adof = find(Pr); % all filled voxels
bdof_m = find(N*(Pr ~= 0) < neigh & abs(Pr) >= 1);
sdof = find(Pr > 1); % voxels with 2 cells
Idof = (N*(Pr ~= 0) > 0 & Pr == 0); % empty voxels touching occupied ones
idof1 = find(Idof & ~VPr); % "external" OBC1
idof2 = find(Idof & VPr); % "internal" OBC2
idof = find(Idof);

% Determine also a local enumeration, eg. [1 2 3
% ... numel(Adof)].
Adof = [adof;idof];
 Adof_ = (1:numel(Adof))';  
[adof_,sdof_,idof_,idof1_,idof2_,bdof_m_] = ...
      map(Adof_,Adof,adof,sdof,idof,idof1,idof2,bdof_m);

% Plot how the start looks like
figure(12);
patch('Faces',R,'Vertices',V,'FaceColor',[0.9 0.9 0.9], ...
    'EdgeColor','none');
hold on,
axis([-1 1 -1 1]); axis square, axis off
ii = find(Pr == 1);
patch('Faces',R(ii,:),'Vertices',V, ...
    'FaceColor',graphics_color('bluish green'));
ii = find(Pr == 2);
patch('Faces',R(ii,:),'Vertices',V, ...
    'FaceColor',graphics_color('vermillion'));
ii = find(Pr == -1);
patch('Faces',R(ii,:),'Vertices',V, ...
    'FaceColor',[0 0 0]);
ii = idof1;
patch('Faces',R(ii,:),'Vertices',V, ...
    'FaceColor',[0,0,1]);
title('Start out structure')
drawnow;

% Step through different values of alpha
alpha = [1e-2, 1e-1, 1e+1, 1e+2];
alpha_inv = 1./alpha;
i = 1;
for a_inv = alpha_inv

    %%% LHS
    LaX = L(Adof,Adof);
    Mgamma_b = Mgamma_dM(Adof,Adof);
    Lai = fsparse(idof1_,idof1_,1,size(LaX));
    neighs_LaX = sum(LaX~=0,2)-1;
    scale_LaX = fsparse(diag(ones(size(neighs_LaX)) - neighs_LaX./4,0));
    Mgamma_b_toAdd = Lai*Mgamma_b*Lai;
    [ii,jj,ss] = find(Mgamma_b_toAdd);
    keep = find(ii ~= jj); % (removes only the diagonal)
    ii = ii(keep); jj = jj(keep); ss = ss(keep);
    Mgamma_b_toAdd = fsparse(ii,jj,ss,size(LaX));
    Mgamma_b_toAdd = Mgamma_b_toAdd+sparse(1:size(LaX,1),1:size(LaX,1),2*full(sum(Mgamma_b_toAdd,2)));

    lhs = LaX - Lai*LaX*scale_LaX + a_inv*Mgamma_b_toAdd;
    
    Lai2 = fsparse(idof2_,idof2_,1,size(lhs));
    lhs = lhs - Lai2*lhs + Lai2;

    %%% RHS   
    rhs = fsparse(sdof_,1,1./dM(sdof),[size(LaX,1) 1]);
    
    %%% SOLVE
    X_1 = full(lhs \ rhs);
%     X_1 = normalize(X_1,'range');

    %%% PLOT
    figure(1);
    subplot(2,2,i);   
    plot(bdof_m, X_1(bdof_m_),'.-', 'Displayname', 'bdof_m');
    hold on;
    plot(idof, X_1(idof_),'.-', 'Displayname', 'idof1');
    title(sprintf('alpha = %d', 1/a_inv));
    grid on;

    %%% PLOT SURF
    fig2 = figure(2);
    subplot(2,2,i);
    plotPressureBars2(fig2,Nvoxels,h,Pr,X_1,adof,adof_,idof,idof_)
    axis([-1 1 -1 1]);
    grid on;
    title(sprintf('alpha = %d', 1/a_inv));
    view(3);

    % Step figure index
    i = i + 1;
end


row = idof1(1);
format rational
disp('----------------------------------------');
fprintf('NVOXELS = %d --> size(L) = %dx%d\n', Nvoxels,Nvoxels^2,Nvoxels^2);
fprintf('ROW IN MATRIXES: %d\n', row);
fprintf('h = %s \t h^2 = %s \t 1/h = %s \t sqrt(2)*h = %s \t 2*(2+sqrt(2))*h/6 = %s \n', ...
    strtrim(rats(h)),strtrim(rats(h^2)), strtrim(rats(1/h)), ...
    strtrim(rats(sqrt(2*h^2))), strtrim(rats(2*(2+sqrt(2))*h/6)));
fprintf('L \t\t\t= %s\n', strtrim(rats(full(L(row,L(row,:) ~= 0)))));
fprintf('L_orig \t\t= %s\n', strtrim(rats(full(L_orig(row,L_orig(row,:) ~= 0)))));
fprintf('Mgamma \t\t= %s\n', strtrim(rats(full(Mgamma(row,Mgamma(row,:) ~= 0)))));
fprintf('Mgamma_dM \t= %s\n', strtrim(rats(full(Mgamma_dM(row,Mgamma_dM(row,:) ~= 0)))));
fprintf('M \t\t\t= %s\n', strtrim(rats(full(M(row,M(row,:) ~= 0)))));
fprintf('dM \t\t\t= %s\n', strtrim(rats(dM(row))));
disp('----------------------------------------');
format short