% Simulation of an avascular tumour model.
%
%   Avascular tumour growth, still growth experiment: An initial circular
%   population cells (one per voxel) lie in a domain rich in oxygen. Cells 
%   consume oxygen at a constant rate, cons. Cells occupying a voxel with 
%   oxygen above cutoff_prol proliferate at a rate r_prol. Cells occupying
%   voxels with an oxygen concentration below cutoff_die die at a
%   rate r_die. Dead cells degrade and stop occupying space at a
%   rate r_degrade.
%   
%   No movement of the cells is allowed. Pressure between cells is
%   calculated but does not cause any actions.

% C. Jayaweera & A. Graf Brolund 2021-01 (revision)
% S. Engblom 2017-12-27 (revision)
% D. B. Wilson 2017-09-05
% S. Engblom 2017-02-11

clear;
clc;
close all;

% cells live in a square of Nvoxels-by-Nvoxels
Nvoxels = 121; % odd so the BC for oxygen can by centered

% fetch Cartesian discretization
[P,E,T,gradquotient] = basic_mesh(1,Nvoxels); 
[V,R] = mesh2dual(P,E,T,'voronoi');

D = 1; % D_rate, the rate with which cells move in the domain. 
        % currently the rate is the same for visited voxels and non-visited

% simulation interval
Tend = 100;
tspan = linspace(0,Tend,101);
timescaling = 0.005;

% report(tspan,'timeleft','init'); % (this estimator gets seriously confused!)

% The user specified cutoff and rate parameters for the proliferation,
% death, degradation and consumption rules.
cons = 0.0015;        % consumption of oxygen by cells
cutoff_prol = 0.65;   % the minimum amount of oxygen for proliferation
r_prol = 0.125;       % rate of proliferation of singly occupied voxels
cutoff_die = 0.55;    % the maximum amount of oxygen where cells can die
r_die = 0.125;        % rate of death
r_degrade = 0.01;     % rate of degradation for already dead cells
cutoff_deg = 0.0001;  % the minimum amount of dead cells in a voxel
cutoff_remain = 0.01; % the minimum amount of alive cells in a voxel

% Initial population: circular blob of living cells
start_value = 1; % cell concentrations in the initial blob
radius = 0.25;
r = sqrt(P(1,:).^2+P(2,:).^2);
ii = find(r < radius); % radius of the initial blob
U = fsparse(ii(:),1,start_value,[Nvoxels^2 1]); % intialize
U_new = fsparse(ii(:),1,start_value,[Nvoxels^2 1]);
U_dead = fsparse(ii(:),1,0,[Nvoxels^2 1]);      
U_deadnew = fsparse(ii(:),1,0,[Nvoxels^2 1]);  

% boundary conditions
OBC1 = 0; % BC for the oxygen equation for unvisited boundary
OBC2 = 0; % BC for the visited boundary

% assemble minus the Laplacian on this grid (ignoring BCs), the voxel
% volume vector, and the sparse neighbor matrix
[L,dM,N] = dt_operators(P,T);       %N gives the neighbours 
neigh = full(sum(N,2));

% dofs for the sources at the extreme outer circular boundary
[xc,yc] = getmidpointcircle(1/2*(Nvoxels+1),1/2*(Nvoxels+1),1/2*(Nvoxels-1));
irem = find(xc < 1 | yc < 1 | xc > Nvoxels | yc > Nvoxels);
xc(irem) = [];
yc(irem) = [];
extdof = find(sparse(xc,yc,1,Nvoxels,Nvoxels));

% visit marker matrix: 1 for voxels who have been occupied
VU = (U ~= 0);

% representation of solution: cell-vector of sparse matrices
Usave = cell(1,numel(tspan));
Usave{1} = U;
Udsave = cell(1,numel(tspan));
Udsave{1} = U_dead;

% for keeping track of the oxygen
Oxysave = cell(1,numel(tspan));

tt = tspan(1);
i = 1;
La = struct('X',0,'L',0,'U',0,'p',0,'q',0,'R',0);
OLa = struct('X',0,'L',0,'U',0,'p',0,'q',0,'R',0);

% oxygen Laplacian
OLa.X = L;
OLai = fsparse(extdof,extdof,1,size(OLa.X));
OLa.X = OLa.X-OLai*OLa.X+OLai;   
[OLa.L,OLa.U,OLa.p,OLa.q,OLa.R] = lu(OLa.X,'vector');

while tt <= tspan(end)
    U = U_new;
    U_dead = U_deadnew;
    
    %% Init U and U_dead and classify the DOFs
    U = U_new;
    U_dead = U_deadnew;
    U_and_U_dead = U | U_dead;
  
    %Classification of the DOFs
    adof = find(U_and_U_dead); % all filled voxels 
    sdof = find(U > 1); % source voxels,concentration more than 1
    % empty voxels touching occupied ones 
    Idof = (N*(U_and_U_dead ~= 0) > 0 & U_and_U_dead == 0);          
    idof1 = find(Idof & ~VU); % "external" OBC1
    idof2 = find(Idof & VU); % "internal" OBC2
    idof = find(Idof);
    ddof = find(U_dead > 0); % degrading voxels
    
    % "All DOFs" = adof + idof, like the "hull of adof"
    Adof = [adof; idof];
    % The above will be enumerated within U, a Nvoxels^2-by-1 sparse
    % matrix. Determine also a local enumeration, eg. [1 2 3
    % ... numel(Adof)].

    Adof_ = (1:numel(Adof))';
    [sdof_,idof1_,idof2_,idof_,adof_,ddof_] = ...          
       map(Adof_,Adof,sdof,idof1,idof2,idof,adof,ddof);
     
    %% Calculate Pressure and Oxygen systems
    
    % pressure Laplacian
    La.X = L(Adof,Adof);
    %remove emtpy voxels touching occupied ones
    Lai = fsparse(idof_,idof_,1,size(La.X)); 
    La.X = La.X-Lai*La.X+Lai;
    [La.L,La.U,La.p,La.q,La.R] = lu(La.X,'vector');

    % RHS source term proportional to the over-occupancy and BCs
    Pr = full(fsparse(sdof_,1,(U(sdof)-1)./dM(sdof), ...%equilibrium at U=1
        [size(La.X,1) 1]));     % RHS first...
    Pr(La.q) = La.U\(La.L\(La.R(:,La.p)\Pr)); % ..then the solution

    % RHS source term proportional to the over-occupancy and BCs
    Oxy = full(fsparse([extdof; adof],1, ...
        [ones(size(extdof)); ...
        -cons*full(U(adof)./dM(adof))], ... 
        [size(OLa.X,1) 1]));
    Oxy(OLa.q) = OLa.U\(OLa.L\(OLa.R(:,OLa.p)\Oxy));
    
    %%  Change calculation
    % proliferation, death and degradation

    %proliferation
    ind_prol = find((Oxy > cutoff_prol));   %index of proliferating cells
    prol_conc = r_prol*U(ind_prol);

    %death
    ind_die = find(Oxy < cutoff_die);   %index for dying cells
    dead_conc = r_die*U(ind_die);

    %degradation
    degrade_conc = U_deadnew(ddof)*r_degrade; 
    
    %%  Calculate time step dt    
    % find the largest possible time step while avoiding U<0
    dt_death = U_new(ind_die)./(dead_conc); 

    dt = min([dt_death;(0.1*Tend)])*timescaling; % scale dt smaller
   
    %% Report back and save time series of current states
 
    if tspan(i+1) < tt+dt
        iend = i+find(tspan(i+1:end) < tt+dt,1,'last');

        % save relevant values 
        Usave(i+1:iend) = {U};
        Udsave(i+1:iend) = {U_dead};

        Oxysave(i+1:iend) = {Oxy};

        i = iend;
    end
    
    %% Euler steps
    
    %Proliferation
    U_new(ind_prol) = U_new(ind_prol)+prol_conc*dt;

    %Death
    U_new(ind_die) = U_new(ind_die) - dead_conc*dt;
    U_deadnew(ind_die) = U_deadnew(ind_die) + dead_conc*dt;
    ind_cutoff =  find(U_new < cutoff_remain & (Oxy < cutoff_die));
    U_new(ind_cutoff) = 0; % remove cells below cutoff_remain
    
    % Degradation
    U_deadnew(ddof) = U_deadnew(ddof) - degrade_conc*dt;
    U_deadnew(U_deadnew < cutoff_deg) = 0; % remove cells below cutoff_deg
    
    %% Step in time    
    tt = tt+dt;
%     report(tt,U,'');
    
    % update the visited sites
    VU = VU | U;
end
% report(tt,U,'done'); 

%% Create a GIF animation
Mnormal = struct('cdata',{},'colormap',{});
figure(1), clf, 

Umat=full(cell2mat(Usave));
colorbar
caxis([min(min(Umat)) max(max(Umat))])
colorlabel('Concentration of cells, U')
for i = 1:numel(Usave)
    % background
    patch('Faces',R,'Vertices',V,'FaceColor',[0.9 0.9 0.9], ...
        'EdgeColor','none');
    hold on,
    axis([-1 1 -1 1]); axis square, axis off
    
    % colour living voxels after concentration level
    ii = find(Usave{i}>0);
    c = Umat(ii,i);
    patch('Faces',R(ii,:),'Vertices',V,'FaceVertexCData',c, ... 
        'FaceColor','flat');     

    % color (fully) dead voxels black
    ii = find(Usave{i} == 0 & Udsave{i} > 0);
    p_dead = patch('Faces',R(ii,:),'Vertices',V, ...
        'FaceColor',[0 0 0]);
    legend(p_dead,'dead')
    
    title(sprintf('Time = %d',tspan(i)));
    drawnow;
    Mnormal(i) = getframe(gcf);
end

% save the GIF
movie2gif(Mnormal,{Mnormal([1:2 end]).cdata},'Tumour.gif', ...
          'delaytime',0.1,'loopcount',0);