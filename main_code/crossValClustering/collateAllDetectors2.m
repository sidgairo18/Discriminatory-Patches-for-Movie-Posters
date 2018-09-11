% Edit: Carl Doersch (cdoersch at cs dot cmu dot edu) to simplify the interface
function [collatedDetector, numDets, allParams] = collateAllDetectors(dets)
% Collates the detectors of the specified categories.
%
% Author: saurabh.me@gmail.com (Saurabh Singh).

%dets = cell(1, length(subDirs));
%numDets = zeros(1, length(subDirs));
for i = 1 : length(dets)
%  path = [basePath subDirs{i} detFileName];
%  if ~exist(path,'file')
%    error('File %s not found', path);
%  end
%  load(path, 'detectors');
%  dets{i} = detectors;
  numDets(i) = size(dets{i}.firstLevModels.w, 1);
end
totalNumDets = sum(numDets);
featLength = size(dets{1}.firstLevModels.w, 2);
params = dets{1}.params;
w = zeros(totalNumDets, featLength);
rho = zeros(totalNumDets, 1);
firstLabel = zeros(totalNumDets, 1);
info = cell(totalNumDets, 1);
threshold = zeros(totalNumDets, 1);
firstInd = 1;
allParams = cell(size(dets));
for i = 1 : length(dets)
  num = size(dets{i}.firstLevModels.w, 1);
  w(firstInd : firstInd + num - 1, :) = dets{i}.firstLevModels.w;
  rho(firstInd : firstInd + num - 1) = dets{i}.firstLevModels.rho;
  firstLabel(firstInd : firstInd + num - 1) = ...
    dets{i}.firstLevModels.firstLabel;
  info(firstInd : firstInd + num - 1) = dets{i}.firstLevModels.info;
  threshold(firstInd : firstInd + num - 1) = ...
    dets{i}.firstLevModels.threshold;
  allParams{i} = dets{i}.params;
  firstInd = firstInd + num;
end
params.category = '';
collatedDetector = VisualEntityDetectors({}, params);
collatedDetector.firstLevModels.w = w;
collatedDetector.firstLevModels.rho = rho;
collatedDetector.firstLevModels.firstLabel = firstLabel;
collatedDetector.firstLevModels.info = info;
collatedDetector.firstLevModels.threshold = threshold;
end
