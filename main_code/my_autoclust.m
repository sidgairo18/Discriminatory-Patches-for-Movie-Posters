%distributed processing settings
%run in parallel?
isparallel=0;
%if isparallel=1, number of parallel jobs
nprocs=150;
%if isparallel=1, whether to run on multiple machines or locally
isdistributed=1;

%output directory settings
global ds;
myaddpath;
ds.prevnm=mfilename;
dssetout(['/home/sid/wmparisllp/output_data' ds.prevnm '_out']);
%ds.dispoutpath=['/PATH/TO/SOME/WEB/ACCESSIBLE/DIRECTORY/' ds.prevnm '_out/'];
%loadimset(7);
% Here use your setdatafunction to use for your own dataset.
load('moviedata.mat');
setdataset(imgs, '/home/sid/github/Discriminatory-Patches-for-Movie-Posters/main_code/data/cutouts', '');

if(isfield(ds.conf.gbz{ds.conf.currimset},'imgsurl'))
  ds.imgsurl=ds.conf.gbz{ds.conf.currimset}.imgsurl;
end

%general configuration

%define the number of training iterations used.  The paper uses 3; sometimes
%using as many as 5 can result in minor improvements.
num_train_its=5;

rand('seed',1234)

%parameters for Saurabh's code
ds.conf.params= struct( ...
  'imageCanonicalSize', 400,...% images are resized so that their smallest dimension is this size.
  'patchCanonicalSize', {[80 80]}, ...% patches are extracted at this size.  Should be a multiple of sBins.
  'scaleIntervals', 8, ...% number of levels per octave in the HOG pyramid 
  'sBins', 8, ...% HOG sBins parameter--i.e. the width in height (in pixels) of each cell
  'useColor', 1, ...% include a tiny image (the a,b components of the Lab representation) in the patch descriptor
  'patchOverlapThreshold', 0.6, ...%detections (and random samples during initialization) with an overlap higher than this are discarded.
  'svmflags', '-s 0 -t 0 -c 0.1');

ds.conf.detectionParams = struct( ...
  'selectTopN', false, ...
  'useDecisionThresh', true, ...
  'overlap', 0.4, ...% detections with overlap higher than this are discarded.
  'fixedDecisionThresh', -1.002);
