function [ibcd,p,t,np,iq1,iq2,iq3,iq4,icl]=kpde2dumsh(ax,bx,ay,by,nx,ny)
%KPDE2DUMSH Uniform quadrilateral mesh generation for 2D rectangular domain
%   Creates a structured mesh of bilinear quadrilaterals divided into triangles
%   for the domain [ax,bx] × [ay,by] with nx×ny grid points.
%
%   INPUTS:
%       ax,bx : x-interval boundaries (left, right)
%       ay,by : y-interval boundaries (bottom, top)
%       nx,ny : number of grid points in x and y directions
%
%   OUTPUTS:
%       ibcd : global indices of all boundary nodes
%       p    : node coordinates matrix (np × 2) where np = nx×ny
%       t    : triangle connectivity matrix (nt × 3) where nt = 2×(nx-1)×(ny-1)
%       np   : total number of nodes (nx×ny)
%       iq1,iq2,iq3,iq4 : interior node indices for each quadrant (used in FEM assembly)
%       icl  : indices of corner nodes
%
%   MESH STRUCTURE:
%       - Creates a regular grid with uniform spacing hx and hy
%       - Divides each quadrilateral into two triangles
%       - Identifies boundary nodes for Dirichlet conditions
%       - Provides quadrant indices for element assembly
%
%   OUTPUT FORMATS:
%       p: [x1 y1; x2 y2; ...; xN yN] where N = nx×ny
%       t: [node_i node_j node_k] for each triangle (counter-clockwise order)
%
%   BOUNDARY NODES:
%       ib1 : bottom edge nodes (y = ay)
%       ib2 : right edge nodes (x = bx)
%       ib3 : top edge nodes (y = by)
%       ib4 : left edge nodes (x = ax)

np=nx*ny; nq=(nx-1)*(ny-1); nt=2*nq;

% Node coordinates
hx=(bx-ax)/(nx-1); hy=(by-ay)/(ny-1);
[x,y]=ndgrid(ax:hx:bx,ay:hy:by);
p=[x(:) y(:)];

% Quadrangle indices
ip=1:nx*ny';
ib1=(1:nx)'; ib2=nx*(1:ny)';
ib3=(nx*(ny-1)+1:nx*ny)'; ib4=(1:nx:nx*ny)';

ib12=union(ib1,ib2); ib23=union(ib2,ib3);
ib34=union(ib3,ib4); ib14=union(ib1,ib4);

% Boundary nodes
B1=union(ib12,ib23); B2=union(ib34,ib14);
icl=union(B1,B2);  % corner nodes

% Quadrant indices for interior nodes
iq1=setdiff(ip,ib23); iq2=setdiff(ip,ib34);
iq3=setdiff(ip,ib14); iq4=setdiff(ip,ib12);

% Triangulation (each quadrilateral split into two triangles)
t=zeros(nt,3);
t(1:nq,1)=iq1;      t(1:nq,2)=iq2;      t(1:nq,3)=iq3;
t(nq+1:2*nq,1)=iq3; t(nq+1:2*nq,2)=iq4; t(nq+1:2*nq,3)=iq1;

% Boundary node arrays for each edge
pbx=[ib1 ib3];  % bottom and top edges (constant y)
pby=[ib4 ib2];  % left and right edges (constant x)

% Global boundary node indices
ibcx=union(pbx(:,1),pbx(:,2)); ibcy=union(pby(:,1),pby(:,2));
ibcd=union(ibcx,ibcy);  % all boundary nodes