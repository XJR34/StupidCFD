function [N,Nx] = mlsShapeInterp1D(xint, xs, re, varargin)
%mlsShapeInterp1D
% Calculate MLS shape function.
%
% Input:
% rx,ry: contains relative positions (xj - x, yj - y)
% 
% wgt: weights
%
% Output:
%

% note the minus sign
% (xj-x) -> (x-xj)
% rx = -rx(:);
% ry = -ry(:);

%
if isrow(xs)
    xs = xs.';
end

rx = xint - xs;
% rx = xs;
% rx = -xs;

% set default values
mls_order = 1;
mls_volume = ones(size(xs));

mlsParseInterpOptions;


% weight and derivative
[w, wx] = mlsInterpWeight1D(xint, xs, re);

w = w .* mls_volume;
wx = wx .* mls_volume;

%
[P,Px] = ShapeBasis(rx, mls_order);
Pt = P.';
Pxt = Px.';

W = diag(w);
Wx = diag(wx);

A = Pt * W * P;
Ax = Pxt * W * P + Pt * Wx * P + Pt * W * Px;

% invA = inv(A);
invA = pinv(A);
invAx = -invA * Ax * invA;

ah = invA * Pt * W;
ahx = invAx * Pt * W + invA * Pxt * W + invA * Pt * Wx;

[ph,phx] = ShapeBasis(0, mls_order);
% [ph,phx] = ShapeBasis(-xint, mls_order);
N = ph * ah;
Nx = ph * ahx;
% Nx = phx*ah;
% Nx = ph * ahx + phx*ah;

return
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[w,wx,wy] = WeightFunc(rx,ry,re);

w = w .* mls_volume;
wx = wx .* mls_volume;
wy = wy .* mls_volume;

[P,Px,Py] = ShapeBasis(rx,ry, mls_order);

W = diag(w);
Wx = diag(wx);
Wy = diag(wy);

A = P' * W * P;
Ax = Px' * W * P + P' * Wx * P + P' * W * Px;
Ay = Py' * W * P + P' * Wy * P + P' * W * Py;

invA = inv(A);
invAx = -invA * Ax * invA;
invAy = -invA * Ay * invA;

ah = invA * P' * W;
ahx = invAx * P' * W + invA * Px' * W + invA * P' * Wx;
ahy = invAy * P' * W + invA * Py' * W + invA * P' * Wy;

% center point
ph = ShapeBasis(0,0, mls_order);

N = ph * ah;
Nx = ph * ahx;
Ny = ph * ahy;

% TODO derivatives over 2nd-order are difficult to calculate!!!
% They are here approximated
if mls_order >= 2
    Nxx = ah(4,:);
    Nxy = ah(5,:);
    Nyy = ah(6,:);
else
    Nxx = [];
    Nxy = [];
    Nyy = [];
end



return
end


function [P,Px] = ShapeBasis(rx, completeness)
%ShapeBasis
% Return the polynomial basis
% Currently upto 2nd-order [x, y, x2, xy, y2]
%

vec0 = zeros(size(rx));
vec1 = ones(size(rx));


% the order of polynomial
% completeness = 1;
% completeness = 2;

%
switch completeness
case {0}
    % 1
    P = [ vec1 ];
    Px = [ vec0 ];
    % Py = [ vec0 ];
case {1}
    % 1,x,y
    P = [ vec1, rx ];
    Px = [ vec0, vec1 ];
case {2}
    % x,y, x^2
    P = [ vec1, rx, 1/2*rx.^2 ];
    Px = [ vec0, vec1, rx ];
otherwise
	error('Unsupported completeness=%d',completeness);
end

return
end



function [w,wx,wy] = WeightFunc(rx,ry, cutoff)
%fdpmWeightFunc
% Calculate weight function 
%

rsmall = cutoff * 1.0e-6;

r = sqrt(rx.^2 + ry.^2);

q = r ./ cutoff;

ok = (q<1);

% w = w(q)
w = ok .* (1 - 6*q.^2 + 8*q.^3 - 3*q.^4);

if nargout > 1
    % dw/dq
    wq = ok .* (-12*q + 24*q.^2 - 12*q.^3);
    
    % dw/dr
    wr = wq ./ cutoff;
    
    % dw/dx, dw/dy
    wx = -rx ./ (r+rsmall) .* wr;
    wy = -ry ./ (r+rsmall) .* wr;
end

return
end






