function make(varargin)
%MAKE Makefile for FAST.
%   MAKE by itself makes FAST with default arguments.
%
%   MAKE(...) accepts additional arguments as property/value-pairs.
%
%   Property     Value/{Default}     Description
%   -----------------------------------------------------------------
%   OpenMP       Boolean {false}     Turns OpenMP-compilation
%                                    on/off. Only affects FSPARSE.
%
%   fsparseonly  Boolean {false}     Only compiles FSPARSE.
%
%   fsparsetime  Boolean {false}     Timing syntax for FSPARSE.
%
%   silent       Boolean {false}     Turns information display on/off.

% Johannes Dufva 2020-10-30 (mexw64, 9.7)
% S. Engblom 2019-01-23 (mexmaci64, mexa64, 9.6)
% S. Engblom 2016-11-23 (spreplace)
% S. Engblom 2015-03-23 (mexa64, 8.4)
% S. Engblom 2015-01-19 (mexmaci64, 8.4)
% S. Engblom 2013-12-02 (OpenMP, fsparse)
% S. Engblom 2012-04-16 (mexmaci64, 7.11)
% S. Engblom 2011-04-17 (mexmaci64, 7.10)
% S. Engblom 2011-03-07 (mexa64, 7.11)
% S. Engblom 2010-09-23 (mexs64, 7.7)
% S. Engblom 2010-02-02 (mexa64, 7.8)
% S. Engblom 2010-01-12 (mexmaci)
% S. Engblom 2007-05-17 (mexs64)
% S. Engblom 2006-11-09 (mexa64)
% S. Engblom 2005-03-22 (mexmac)

% Use '-DmwIndex=int' for platforms where mex is not automatically
% linked against the library defining the mwIndex type.

% default options
optdef.openmp = false;
optdef.fsparseonly = false;
optdef.fsparsetime = false;
optdef.silent = false;

% merge defaults with actual inputs
if nargin > 0
  opts = struct(varargin{:});
  fn = fieldnames(opts);
  for i = 1:length(fn)
    optdef = setfield(optdef,fn{i},getfield(opts,fn{i}));
  end
end
opts = optdef;
if opts.openmp
  if ~opts.silent
    fprintf(1,'Compiling FSPARSE with OpenMP.\n');
  end
end
if opts.fsparseonly
  if ~opts.silent
    fprintf(1,'Compiling FSPARSE only.\n');
  end
end
if opts.fsparsetime
  FSPARSEDEF = '-DFSPARSE_TIME';
  if ~opts.silent
    fprintf(1,'Compiling with #define FSPARSE_TIME.\n');
  end
else
  FSPARSEDEF = '';
  if ~opts.silent
    fprintf(1,'Compiling with #undef FSPARSE_TIME.\n');
  end
end

% Note that the OpenMP version of fsparse is a beta-release. Not all
% cases of the code has been parallelized. Also, the OpenMP make has
% only been implemented for some platforms. The important lines are:
%
% clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/glnxa64 -lmx ' ...
%          '-lmex'];
% mex('-largeArrayDims',clibs, ...
%     ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
%     '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
%     '-outdir',s,[s '/source/fsparse.c']);

s = pwd;
mx = mexext;
ver = version;

% first is the fsparse-only compilation
if opts.fsparseonly
  if strcmp(mx,'mexa64')
    if ver(1) == '7'
      if ~strncmp(ver,'7.2',3) && ~strncmp(ver,'7.8',3) && ...
            ~strncmp(ver,'7.11',4) && ~strncmp(ver,'7.13',4)
        warning(['Extension .' mexext [' tested with Matlab version(s) ' ...
                            '7.2, 7.8, 7.11 and 7.13 only.']]);
      end
      if ~strncmp(ver,'7.11',4)
        if strncmp(ver,'7.2',3)
          % should be an easy fix:
          if opts.openmp, warning('OpenMP not implemented for this platform.'); end
          mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
               '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
              '-outdir',s,[s '/source/fsparse.c']);
        else
          if opts.openmp
            clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/glnxa64 -lmx ' ...
                     '-lmex'];
            mex('-largeArrayDims',clibs, ...
                ['CFLAGS=-fopenmp -O5 -fPIC -std=c99 ' ...
                 '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
                '-outdir',s,[s '/source/fsparse.c']);
          else
            mex('-largeArrayDims', ...
                ['CFLAGS=-fPIC -O5 -std=c99 ' ...
                 '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
                '-outdir',s,[s '/source/fsparse.c']);
          end
        end
      else
        % should be an easy fix:
        if opts.openmp, warning('OpenMP not implemented for this platform.'); end
        % apparently, the linker path is not properly set up on 7.11:
        mex('-largeArrayDims', ...
            ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            ['-L' matlabroot '/sys/os/glnxa64'], ...
            '-outdir',s,[s '/source/fsparse.c']);
      end
    else
      if ~strncmp(ver,'8.4',3) && ~strncmp(version,'9.6',3)
        warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
                 '8.4 only.']);
      end
      
      % apparently, the linker path is not properly set up on 8.4 (also a
      % soft link libstdc++.so inside [matlabroot '/sys/os/glnxa64']
      % is required to point to the correct shared library, in this
      % case libstdc++.so.6.0.17)
      if opts.openmp
        clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/glnxa64 -lmx ' ...
                 '-lmex'];
        mex('-largeArrayDims',clibs, ...
            ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            ['-L' matlabroot '/sys/os/glnxa64'], ...
            '-outdir',s,[s '/source/fsparse.c']);
      else
        mex('-largeArrayDims', ...
            ['CFLAGS=-fPIC O5 -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            ['-L' matlabroot '/sys/os/glnxa64'], ...
            '-outdir',s,[s '/source/fsparse.c']);
      end
    end
  elseif strcmp(mx,'mexmaci64')
    if ver(1) == '7'
      if ~strncmp(ver,'7.10',4) && ~strncmp(ver,'7.11',4) && ...
            ~strncmp(ver,'7.14',4)
        warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
                 '7.10 and 7.11 only.']);
      end
      if opts.openmp
        clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/maci64 -lmx ' ...
                 '-lmex'];
        mex('-largeArrayDims',clibs, ...
            ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            '-outdir',s,[s '/source/fsparse.c']);
      else
        mex('-largeArrayDims', ...
            ['CC=gcc -std=c99 -fast ',FSPARSEDEF], ...
            '-outdir',s,[s '/source/fsparse.c']);
      end
    else
      if opts.openmp, warning('Compilation of OpenMP not (yet?) supported for this platform.'); end 
      if ~strncmp(ver,'8.4',3) && ~strncmp(version,'9.6',3)
        warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
		 '8.4 and 9.6 only.']);
      end
      if opts.openmp
        % no harm in trying (await update of Clang?)
        clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/maci64 -lmx ' ...
                 '-lmex'];
        mex('-largeArrayDims',clibs, ...
            ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            '-outdir',s,[s '/source/fsparse.c']);
      else
        mex('-largeArrayDims', ...
            ['CFLAGS=-Wno-logical-op-parentheses -std=c99 ',FSPARSEDEF],'-outdir',s,[s '/source/fsparse.c']);
      end
    end
  else
    error('FSPARSE-only compilation not implemented for this platform.');
  end
  return;
end

% main compilation
if strcmp(mx,'mexglx')
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  if ~strncmp(ver,'7.5',3) && ~strncmp(ver,'7.8',3)
    warning(['Extension .' mexext [' tested with Matlab version(s) ' ...
                        '7.5 and 7.8 only.']]);
  end
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
      '-outdir',s,[s '/source/clenshaw.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
      '-outdir',s,[s '/source/fsetop.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
        '-outdir',s,[s '/source/mexfrepmat.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
      '-outdir',s,[s '/source/powerseries.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
      '-outdir',s,[s '/source/sppmul.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions'], ...
      '-outdir',s,[s '/source/spreplace.c']);
  mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
       '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
      '-outdir',s,[s '/source/fsparse.c']);
elseif strcmp(mx,'mexa64')
  if ver(1) == '7'
    if ~strncmp(ver,'7.2',3) && ~strncmp(ver,'7.8',3) && ...
          ~strncmp(ver,'7.11',4) && ~strncmp(ver,'7.13',4)
      warning(['Extension .' mexext [' tested with Matlab version(s) ' ...
                          '7.2, 7.8, 7.11 and 7.13 only.']]);
    end
    if ~strncmp(ver,'7.11',4)
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          '-outdir',s,[s '/source/clenshaw.c']);
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          '-outdir',s,[s '/source/fsetop.c']);
      if strncmp(ver,'7.2',3)
        % should be an easy fix:
        if opts.openmp, warning('OpenMP not implemented for this platform.'); end
        mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions'], ...
            '-outdir',s,[s '/source/mexfrepmat.c']);
        mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
            '-outdir',s,[s '/source/fsparse.c']);
      else
        mex('-largeArrayDims', ...
            ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
             '-D_GNU_SOURCE -pthread -fexceptions'], ...
            '-outdir',s,[s '/source/mexfrepmat.c']);
        if opts.openmp
          clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/glnxa64 -lmx ' ...
                   '-lmex'];
          mex('-largeArrayDims',clibs, ...
              ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
               '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
              '-outdir',s,[s '/source/fsparse.c']);
        else
          mex('-largeArrayDims', ...
              ['CFLAGS=-fPIC  -O5 -fno-omit-frame-pointer -std=c99 ' ...
               '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
              '-outdir',s,[s '/source/fsparse.c']);
        end
      end
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          '-outdir',s,[s '/source/powerseries.c']);
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          '-outdir',s,[s '/source/sppmul.c']);
      mex('-largeArrayDims', ...
	  ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          '-outdir',s,[s '/source/spreplace.c']);
    else
      % should be an easy fix:
      if opts.openmp, warning('OpenMP not implemented for this platform.'); end
      % apparently, the linker path is not properly set up on 7.11:
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/clenshaw.c']);
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/fsetop.c']);
      mex('-largeArrayDims', ...
          ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/mexfrepmat.c']);
      mex('-largeArrayDims', ...
          ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/fsparse.c']);
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/powerseries.c']);
      mex(['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/sppmul.c']);
      mex('-largeArrayDims', ...
	  ['CFLAGS=-fPIC -fno-omit-frame-pointer -std=c99 -O3 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions'], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/spreplace.c']);
    end
  else
    if ~strncmp(ver,'8.4',3) && ~strncmp(version,'9.6',3)
      warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
               '8.4 and 9.6 only.']);
    end
    
    % apparently, the linker path is not properly set up on 8.4 (also a
    % soft link libstdc++.so inside [matlabroot '/sys/os/glnxa64'] is
    % required to point to the correct shared library, in this case
    % libstdc++.so.6.0.17)
    mex('CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/clenshaw.c']);
    mex('CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/fsetop.c']);
    mex('-largeArrayDims','CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/mexfrepmat.c']);
    mex('CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/powerseries.c']);
    mex('-largeArrayDims','CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/sppmul.c']);
    mex('-largeArrayDims','CFLAGS=-fPIC -std=c99 -O3',['-L' matlabroot '/sys/os/glnxa64'], ...
        '-outdir',s,[s '/source/spreplace.c']);

    if opts.openmp
      clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/glnxa64 -lmx ' ...
               '-lmex'];
      mex('-largeArrayDims',clibs, ...
          ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/fsparse.c']);
    else
      mex('-largeArrayDims', ...
          ['CFLAGS=-fPIC -O5 -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
          ['-L' matlabroot '/sys/os/glnxa64'], ...
          '-outdir',s,[s '/source/fsparse.c']);
    end
  end
elseif strcmp(mx,'mexmac')
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  if ~strncmp(ver,'7.0',3)
    warning(['Extension .' mexext ' tested with Matlab version(s) 7.0 only.']);
  end
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/clenshaw.c']);
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/fsetop.c']);
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/mexfrepmat.c']);
  mex(['CC=gcc -std=c99',FSPARSEDEF],'-outdir',s,[s '/source/fsparse.c']);
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/powerseries.c']);
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/sppmul.c']);
  mex('CC=gcc -std=c99','-outdir',s,[s '/source/spreplace.c']);
elseif strcmp(mx,'mexmaci')
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  if ~strncmp(ver,'7.8',3)
    warning(['Extension .' mexext ' tested with Matlab version(s) 7.8 only.']);
  end
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/clenshaw.c']);
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/fsetop.c']);
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/mexfrepmat.c']);
  mex(['CC=gcc -std=c99 -fast',FSPARSEDEF],'-outdir',s,[s '/source/fsparse.c']);
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/powerseries.c']);
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/sppmul.c']);
  mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/spreplace.c']);
elseif strcmp(mx,'mexmaci64')
  if ver(1) == '7'
    if ~strncmp(ver,'7.10',4) && ~strncmp(ver,'7.11',4) && ...
          ~strncmp(ver,'7.14',4)
      warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
               '7.10 and 7.11 only.']);
    end
    mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/clenshaw.c']);
    mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/fsetop.c']);
    mex('-largeArrayDims', ...
        'CC=gcc -std=c99 -fast','-outdir',s,[s '/source/mexfrepmat.c']);
    if opts.openmp
      clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/maci64 -lmx ' ...
               '-lmex'];
      mex('-largeArrayDims',clibs, ...
          ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
          '-outdir',s,[s '/source/fsparse.c']);
    else
      mex('-largeArrayDims', ...
          ['CC=gcc -std=c99 -fast',FSPARSEDEF],'-outdir',s,[s '/source/fsparse.c']);
    end
    mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/powerseries.c']);
    mex('CC=gcc -std=c99 -fast','-outdir',s,[s '/source/sppmul.c']);
    mex('-largeArrayDims', ...
	'CC=gcc -std=c99 -fast','-outdir',s,[s '/source/spreplace.c']);
  else
    if opts.openmp, warning('Compilation of OpenMP not (yet?) supported for this platform.'); end 
    if ~strncmp(ver,'8.4',3) && ~strncmp(version,'9.6',3)
      warning(['Extension .' mexext ' tested with Matlab version(s) ' ...
               '8.4 and 9.6 only.']);
    end
    mex('CFLAGS=-Wno-parentheses -std=c99','-outdir',s,[s '/source/clenshaw.c']);
    mex('CFLAGS= -std=c99','-outdir',s,[s '/source/fsetop.c']);

    mex('-largeArrayDims', ...
        'CFLAGS= -std=c99','-outdir',s,[s '/source/mexfrepmat.c']);
    if opts.openmp
      % no harm in trying (await update of Clang?)
      clibs = ['CLIBS=-lgomp -lm -L' matlabroot '/bin/maci64 -lmx ' ...
               '-lmex'];
      mex('-largeArrayDims',clibs, ...
          ['CFLAGS=-fopenmp -O5 -fPIC -fno-omit-frame-pointer -std=c99 ' ...
           '-D_GNU_SOURCE -pthread -fexceptions ' FSPARSEDEF], ...
          '-outdir',s,[s '/source/fsparse.c']);
    else
      mex('-largeArrayDims', ...
          ['CFLAGS=-Wno-logical-op-parentheses -std=c99 ',FSPARSEDEF],'-outdir',s,[s '/source/fsparse.c']);
    end
    mex('CFLAGS= -std=c99','-outdir',s,[s '/source/powerseries.c']);
    mex('CFLAGS= -std=c99','-outdir',s,[s '/source/sppmul.c']);
    mex('-largeArrayDims', ...
	'CFLAGS= -std=c99','-outdir',s,[s '/source/spreplace.c']);
  end
elseif strcmp(mx,'mexs64')
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  if ~strncmp(ver,'7.7',3)
    warning(['Extension .' mexext ' tested with Matlab version(s) 7.7 only.']);
  end
  mex('-outdir',s,[s '/source/clenshaw.c']);
  mex('-DNO_STDINT','-outdir',s,[s '/source/fsetop.c']);
  mex('-largeArrayDims','-outdir',s,[s '/source/mexfrepmat.c']);
  mex('-largeArrayDims',['-DNO_STDINT ' FSPARSEDEF], ...
      '-outdir',s,[s '/source/fsparse.c']);
  mex('-outdir',s,[s '/source/powerseries.c']);
  mex('-outdir',s,[s '/source/sppmul.c']);
  mex('-largeArrayDims','-outdir',s,[s '/source/spreplace.c']);
elseif strcmp(mx,'mexw64')
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  mex('-outdir',s,[s '/source/clenshaw.c']);
  mex('-outdir',s,[s '/source/fsetop.c']);
  mex('-outdir',s,[s '/source/mexfrepmat.c']);
  mex(FSPARSEDEF,'-outdir',s,[s '/source/fsparse.c']);
  mex('-outdir',s,[s '/source/powerseries.c']);
  mex('-outdir',s,[s '/source/sppmul.c']);
  mex('-largeArrayDims','-outdir',s,[s '/source/spreplace.c']);
else
  warning('New platform. Trying default make.');
  if opts.openmp, warning('OpenMP not implemented for this platform.'); end
  mex('-outdir',s,[s '/source/clenshaw.c']);
  mex('-outdir',s,[s '/source/fsetop.c']);
  mex('-outdir',s,[s '/source/mexfrepmat.c']);
  mex(FSPARSEDEF,'-outdir',s,[s '/source/fsparse.c']);
  mex('-outdir',s,[s '/source/powerseries.c']);
  mex('-outdir',s,[s '/source/sppmul.c']);
  mex('-largeArrayDims','-outdir',s,[s '/source/spreplace.c']);
end
