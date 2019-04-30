option threads=40;
option iterlim=1000000;
option reslim=50000;
option optcr=.5;

$if not set NUM_TASKS $set NUM_TASKS 30
$if not set LANES_UB $set LANES_UB 30

Sets
   i / 1* %NUM_TASKS% /
   k 'mcs'  / 1* %LANES_UB% /
Alias(i,j);

$if not set RUN $set RUN 1
$if not set TEST $set TEST 'gams_4';

parameters
$include C:\Users\jackh\Documents\Hurley\ScheduleGA\Output\%TEST%\run_%RUN%\gams_file.txt


Variable
   x(i,k) 'binary variable indicating job i assigned to machine j'
   s(i,k) 'start time of job i on machine j, if assigned'
   z(i,j,k)      'binary variable, job i and job '
   w   'objective function value'
   M(k)  ' counter whether machine k is used';


Binary variable z(i,j,k);
Positive variable s(i,k);
SOS1 variable x(i,k);
Binary variable m(k);

$if not set MAX_LOAD $set MAX_LOAD 120

Equation
   obj      'define objective function'
   before(i,j,k) 'observe supply limit at plant i'
   after(i,j,k)  'satisfy demand at market j'
   load(k) 'load for each machine '
   start(i,k) 'each job must start after its start'
   end(i,k) 'each job must end before its end time'
   assign(i) 'each job is assigned to at most one machine'
   wub    'upper bound on w'
   mcuse(k)   ' counts whether a machine is used';

obj..w =e= sum(k, M(k));
before(i,j,k)$(ord(i) <> ord(j))..  s(i,k) + p(i)*x(i,k) - s(j,k) =l= %MAX_LOAD% *z(i,j,k);
after(i,j,k)$(ord(i) <> ord(j))..   s(j,k) + p(j)*x(j,k) - s(i,k) =l= %MAX_LOAD% *(1-z(i,j,k));
load(k).. sum(i,  x(i,k)*p(i))  =l= 500;
start(i,k).. s(i,k) =g= aa(i)*x(i,k);
end(i,k)..   s(i,k) =l= (b(i)-p(i))*x(i,k);
assign(i).. sum(k, x(i,k)) =e= 1;
wub.. w =l= %NUM_TASKS%;
mcuse(k).. sum(i,x(i,k)) =l= %LANES_UB%*M(k);


Model schedule / obj,before,after,start,end,assign,mcuse,load /;

solve schedule using mip minimizing w;
File results /C:\Users\jackh\Documents\Hurley\ScheduleGA\Output\%TEST%\run_%RUN%\gams_out.txt/;
put results;
loop((i,k), put i.tl, k.tl, s.l(i,k) /)
putclose results;

display x.l;
display s.l;
