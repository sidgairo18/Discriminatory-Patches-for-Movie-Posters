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
dssetout(['/home/sid/wmparisllp/output_data/' ds.prevnm '_out']);
%ds.dispoutpath=['/PATH/TO/SOME/WEB/ACCESSIBLE/DIRECTORY/' ds.prevnm '_out/'];
%loadimset(7);
% Here use your setdatafunction to use for your own dataset.
load('moviedata.mat');
setdataset(imgs, '/home/sid/github/Discriminatory-Patches-for-Movie-Posters/main_code/data/cutouts/', '');

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

%pick which images to use out of the dataset

imgs=ds.imgs{ds.conf.currimset};
ds.mycity={'genre1'};
parimgs=find(ismember({imgs.city},ds.mycity));
toomanyprague=find(ismember({imgs.city},{'genre2'})); %there's extra images from prague/london in the datset
toomanyprague=toomanyprague(randperm(numel(toomanyprague)));
toomanyprague=toomanyprague(1001:end);
toomanylon=find(ismember({imgs.city},{'genre3'}));
toomanylon=toomanylon(randperm(numel(toomanylon)));
toomanylon=toomanylon(1001:end);
parsub=find(ismember({imgs.city},{'genre1_sub'}));
nycsub=find(ismember({imgs.city},{'genre4_sub'}));

ds.ispos=zeros(1,numel(imgs));
ds.ispos(parimgs)=1;
otherimgs=ones(size(imgs));
otherimgs(parimgs)=0;
otherimgs(toomanyprague)=0;
otherimgs(toomanylon)=0;
otherimgs(parsub)=0;
otherimgs(nycsub)=0;
otherimgs=find(otherimgs);
rp=randperm(numel(parimgs));
parimgs=parimgs(rp(1:168));%usually 2000 positive images is enough; sometimes even 1000 works.
rp=randperm(numel(otherimgs));
otherimgs=otherimgs(rp(1:800));
ds.myiminds=[parimgs(:); otherimgs(:)];
ds.parimgs=parimgs;

'positive'
numel(parimgs)
'other'
numel(otherimgs)

%sample random positive "candidate" patches
step=2;
ds.isinit=makemarks(ds.myiminds(1:step:end),numel(imgs));
initInds=find(ds.ispos&ds.isinit);
if(isparallel&&(~dsmapredisopen()))
    dsmapredopen(nprocs, 1, ~isdistributed);
end
if(~dsfield(ds,'initFeats'))
  disp('sampling positive patches');
  ds.sample=struct();
  ds.sample.initInds=initInds;
  dsmapreduce('myaddpath;[ds.sample.patches{dsidx}, ds.sample.feats{dsidx}]=sampleRandomPatches(ds.sample.initInds(dsidx),25);',{'ds.sample.initInds'},{'ds.sample.patches','ds.sample.feats'});
  ds.initPatches=cell2mat(ds.sample.patches)';
  disp(['sampled ' num2str(numel(ds.initPatches)) ' patches']);
  ds.initFeats=cell2mat(ds.sample.feats');
  dsdelete('ds.sample')
  ds.initImgInds=initInds;
  dssave();
end

%Also sample some random negative patches as an initial negative set for SVM training/negative mining procedure
if(~dsfield(ds,'initFeatsNeg'))
  initInds=find((~ds.ispos)&ds.isinit);
  disp('sampling negative patches');
  ord=randperm(numel(initInds));
  myinds=ord(1:min(numel(ord),30));
  ds.sample.initInds=myinds;
  dsmapreduce('myaddpath;[ds.sample.patches{dsidx}, ds.sample.feats{dsidx}]=sampleRandomPatches(ds.sample.initInds(dsidx));',{'ds.sample.initInds'},{'ds.sample.patches','ds.sample.feats'});
  {'ds.initPatchesNeg','cell2mat(ds.sample.patches)'''};dsup;
  disp(['sampled ' num2str(numel(ds.initPatchesNeg)) ' patches']);
  {'ds.initFeatsNeg','cell2mat(ds.sample.feats'')'};dsup;
  {'ds.initImgIndsNeg','initInds'};dsup;
end
ds.centers=bsxfun(@rdivide,bsxfun(@minus,ds.initFeats,mean(ds.initFeats,2)),sqrt(var(ds.initFeats,1,2)).*size(ds.initFeats,2));
ds.selectedClust=1:size(ds.initFeats,1);
ds.assignedClust=ds.selectedClust;
dssave();

if(exist([ds.prevnm '_wait'],'file'))
  keyboard;
end

%comptue nearest neighbors for each candidate patch.
npatches=size(ds.centers,1);
ds.centers=[];
dsmapreduce('autoclust_assignnn2',{'ds.myiminds'},{'ds.assignednn','ds.assignedidx','ds.pyrscales','ds.pyrcanosz'});
ds.centers=[];


%Sort the candidate patches by the percentage of top 20 nearest neighbors that come from positive set.
%Create a display of the highest-ranked 1200.
for(i=1:numel(ds.assignednn))
  if(isempty(ds.assignednn{i}))
    ds.assignednn{i}=ones(npatches,1)*Inf;
  end
end
assignednn=cell2mat(ds.assignednn);
ds.assignednn={};
nneighbors=100;
for(j=npatches:-1:1)
  dists=[];
  [topndist(j,:),ord]=mink(assignednn(j,:),nneighbors);
  for(i=numel(ord):-1:1)
    topnlab(j,i)=ds.ispos(ds.myiminds(ord(i)));
    topnidx(j,i,:)=[reshape([ord(i) ds.assignedidx{ord(i)}(j,:)],1,1,[])];
  end
  if(mod(j,100)==0);disp(j);end
end
ds.assignedidx={};
clear assignednn;
perclustpost=sum(topnlab(:,1:20),2);
[~,postord]=sort(perclustpost,'descend');
ds.perclustpost=perclustpost(postord);
{'ds.selectedClust','ds.selectedClust(postord)'};dsup;
disppats=find(ismember(ds.assignedClust,ds.selectedClust(1:1200)));
correspimg=[ds.initPatches.imidx];
currdets=simplifydets(ds.initPatches(disppats),correspimg(disppats),ds.assignedClust(disppats));
if(dsfield(ds,'dispoutpath')),dssymlink(['ds.bestbin0'],ds.dispoutpath);end
prepbatchwisebestbin(currdets,0,1);
dispres_discpatch;
{['ds.bestbin0'],'ds.bestbin'};dsup;
ds.bestbin=struct();
%Greedily get rid of the patches that are redundant.
%Create a display that shows, for each non-redundant patch, a subset of its nearest 
%neighbors (specifically, the [1st:10th]- and [15th:7:100th]-nearest)
dssave;
curridx=1;
selClustIdx=1;
mainflag=1;
topndets={};
topndetshalf={};
topndetstrain={};
topnorig=[];
newselclust=[];
for(i=reshape(postord,1,[]))
  if(mainflag)
    curdet=[];
    for(j=1:nneighbors)
      imgidx=topnidx(i,j,1);
      pos=pyridx2pos(reshape(topnidx(i,j,3:4),1,[]),ds.pyrcanosz{imgidx},ds.pyrscales{imgidx}(topnidx(i,j,2)),...
           ds.conf.params.patchCanonicalSize(1)/ds.conf.params.sBins-2,ds.conf.params.patchCanonicalSize(2)/ds.conf.params.sBins-2,...
                 ds.conf.params.sBins,ds.imgs{ds.conf.currimset}(ds.myiminds(imgidx)).imsize);
      curdet=[curdet;struct('decision',-topndist(i,j),'pos',pos,...
               'imidx',ds.myiminds(imgidx),'detector',ds.selectedClust(selClustIdx))];
      curridx=curridx+1;
    end
    if(mainflag)
      [tmpmainflag]=testclusteroverlap(topndetshalf,curdet(1:50));
    end
    origpatind=find(ds.selectedClust(selClustIdx)==ds.assignedClust);
    origdet=ds.initPatches(origpatind);
    origdet=struct('decision',0,'pos',...
               struct('x1',origdet.x1,'x2',origdet.x2,'y1',origdet.y1,'y2',origdet.y2),...
               'imidx',origdet.imidx,'detector',ds.selectedClust(selClustIdx),'count',ds.perclustpost(selClustIdx));
    if(tmpmainflag)
      if(numel(topnorig)<1200)
        topndets=[topndets;{curdet([1:10 15:7:100])}];%for display
        topndetshalf=[topndetshalf;{curdet(1:50)}];%for duplicate detection
        topndetstrain=[topndetstrain;{curdet(1:5)}];%for initializing detectors
        topnorig=[topnorig;origdet];
      end
      disp(['now have ' num2str(numel(newselclust)) ' topnorig']);
      newselclust=[newselclust ds.selectedClust(selClustIdx)];
      if(numel(newselclust)>=1200)
        mainflag=0;
      end
      tmpmainflag=0;
    end
  end
  selClustIdx=selClustIdx+1;
  disp([num2str(selClustIdx) '/' num2str(numel(postord))]);
end
clear topndetshalf;
{'ds.selectedClust','newselclust'};dsup;
ds.topnidx=topnidx;
ds.topnlab=topnlab;
ds.topndist=topndist;
topndets=cell2mat(topndets);
if(dsfield(ds,'dispoutpath')),dssymlink(['ds.bestbin_topn'],ds.dispoutpath);end
prepbatchwisebestbin(topnorig,0,1,1);
ds.bestbin.counts=[[topnorig.count]' 20-[topnorig.count]'];
ds.bestbin.iscorrect=true(size(ds.bestbin.decision));
dispres_discpatch;
dsmv('ds.bestbin.bbhtml','ds.bestbin.allcandidateshtml');
prepbatchwisebestbin(topndets,1,100,[1:10 15:7:100]);
ds.bestbin.splitflag=1;
dispres_discpatch;
{['ds.bestbin_topn'],'ds.bestbin'};dsup;
dsdelete('ds.bestbin');
dssave;
ds.bestbin_topn.alldiscpatchimg=cell(size(ds.bestbin_topn.alldiscpatchimg));

%extract features for the top 5 for each cluster
topndetstrain=cell2mat(topndetstrain);
trpatches=extractpatches(topndetstrain,ds.imgs{ds.conf.currimset});
dsmv('ds.initFeats','ds.initFeatsOrig');
dsmv('ds.assignedClust','ds.assignedClustOrig');
ds.initFeats=zeros(numel(trpatches),size(ds.initFeatsOrig,2));
ds.initFeatsOrig=[];
extrparams=ds.conf.params;
extrparams.imageCanonicalSize=[min(ds.conf.params.patchCanonicalSize)];
for(i=1:numel(trpatches))
  tmp=constructFeaturePyramidForImg(im2double(trpatches{i}),extrparams,1);
  ds.initFeats(i,:)=tmp.features{1}(:)';
  if(mod(i,10)==0)
    disp(i);
  end
end
ds.assignedClust=[topndetstrain.detector];
ds.posPatches=topndetstrain;
clear trpatches;
clear topnidx;
clear topnlab;
clear topndist;
clear topnorig;
dssave;
