% This code runs and evaluate the method on the Test set for the chosen
% parameters based on Training set.
% 
% Author: Hady Ahmady Phoulady
% Department of Computer Science,
% University of Southern Maine, Portland, ME.
%
% Last modified: December 15, 2017

datasetDirectory = '..\dataset';

allEDF = dir(fullfile(datasetDirectory, 'EDF', '*.png'));
datasetInfo = readtable(fullfile(datasetDirectory, 'labels.csv'));

% Find the Test frames to only run and test the method on those frames
testInd = find(datasetInfo.set);
testing = datasetInfo(logical(datasetInfo.set), :);

[testGroundTruth, testSegmentationResult] = deal(cell(height(testing), 1));
allEDFImages = cell(height(testing), 1);

% Load frames and the ground truth
for s = 1: height(testing)
    allEDFImages{s} = imread(fullfile(datasetDirectory, 'EDF', ...
        [testing.frame{s}, '.png']));
    testGroundTruth{s} = csvread(fullfile(datasetDirectory, 'EDF', ...
        [testing.frame{s}, '.csv']));
end

% Set the parameters to those that achieve the highest F measure on the
% Training set
cellsInfo = struct('MinSize', 150, 'MinMean', 10, ...
    'MaxMean', 120, 'MinSolidity', 0.88);

% Segment frames and save them in testSegmentationResult cell array
for s = 1: height(testing)
    [~, testSegmentationResult{s}] = ...
        NucleusSegmentation(allEDFImages{s}, cellsInfo);
end

% Evaluate detection performance measures
[P, R, stdP, stdR] = ...
    EvaluateDetection(testGroundTruth, testSegmentationResult);

% Display the parameters and results
fprintf(...
    'Min Size: %d\tMin Mean: %d\tMax Mean: %d\tMin Solidity: %.2f\n\n', ...
    cellsInfo.MinSize, cellsInfo.MinMean, ...
    cellsInfo.MaxMean, cellsInfo.MinSolidity);
fprintf([repmat('\t%.3f (%.3f)', 1, 2) '\n\t%.3f\n'], ...
    P, stdP, R, stdR, 2 * P * R / (P + R));
