% EvaluateDetection calculates Precision, Recall and their corresponding
% standard deviations across all images.
% 
% Inputs:
%   1) groundTruth - list of manually marked points inside frames. It needs
%   to be a cell array (of size (p, 2), where p is the number of annotated
%   frames. Each cell element is an array of size p x 2, where each each
%   row has the x and y coordinates of a marked point.
% 
%   2) detectionResult - detection result of the algorithm to be evaluated.
%   It can be similarly structured to groundTruth, be a single binary mask
%   that has segmented regions, or a cell of binary masks each for a single
%   segmented region.
% 
%   3) allowedDistance - the distance that is used to create a binary mask
%   in case a cell of lists of point coordinates  in given in
%   detectionResult. The default value is 10 (pixels).
% 
% Outputs:
%   1) P - overall precision of the detection results.
% 
%   2) R - overall recall of the detection results.
% 
%   3) stdP - standard deviation of precision measures computed for each
%   frame separately.
% 
%   4) stdR - standard deviation of recall measures computed for each frame
%   separately.
% 
% Example:
%	[P, R, stdP, stdR] = ...
%	    EvaluateDetection(groundTruth, segmentationResult);
%	fprintf([repmat('\t%.3f (%.3f)', 1, 2) '\n\t%.3f\n'], ...
%		P, stdP, R, stdR, 2 * P * R / (P + R));
% It evaluates detection accuracy and displays the results along with the
% F-measure compted from precision and recall.
% 
% Copyright (c) 2017, Hady Ahmady Phoulady
% Department of Computer Science,
% University of Southern Maine, Portland, ME.
%
% Last modified: December 13, 2017

function [P, R, stdP, stdR] = ...
    EvaluateDetection(groundTruth, detectionResult, allowedDistance)

% Set default value for allowedDistance in case it is not specificed
if (~exist('allowedDistance', 'var'))
    allowedDistance = 10;
end

[imagesFN, imagesTP, imagesFP] = deal(zeros(length(groundTruth), 1));

for i = 1: length(groundTruth)
    if (isempty(detectionResult{i}))
        imagesFN(i) = imagesFN(i) + size(groundTruth{i}, 1);
        continue
    end
    
    % If detectionResult is not as a cell of list of binary masks for each
    % frame, we first convert it to that: a cell array whose each element
    % is a cell array of separate masks for segmented regions inside each
    % frame.
    if (~iscell(detectionResult{i}))
        if (size(detectionResult{i}, 2) == 2)
            detectedPoints = detectionResult{i};
            detectionResult{i} = cell(size(detectionResult{i}, 1), 1);
            [detectionResult{i}{:}] = deal(...
                boolean(max(detectedPoints(:, 1) + allowedDistance, ...
                detectedPoints(:, 2) + allowedDistance)));
            for l = 1: length(detectionResult{i})
                detectionResult{i}{l}(detectedPoints(l, 1), ...
                    detectedPoints(l, 2)) = true;
                detectionResult{i}{l} = bwdist(detectionResult{i}{l}) ...
                    <= allowedDistance;
            end
        else
            [L, num] = bwlabel(detectionResult{i});
            if (~num)
                imagesFN(i) = imagesFN(i) + size(groundTruth{i}, 1);
                continue
            end
            detectionResult{i} = cell(num, 1);
            for l = 1: num
                detectionResult{i}{l} = L == l;
            end
        end
    end
    
    imageSize = size(detectionResult{i}{1});
    foreground = any(reshape([detectionResult{i}{:}], imageSize(1), ...
        imageSize(2), []), 3);
    
    % Initialize and compute a matrix that its (m, d) entry is true if m-th
    % point falls inside the d-th segmented/detected region. We remove a
    % manual point from the matrix if it doesn't fall inside any region:
    % that means it a False Negative.
    intersectionMat = false(size(groundTruth{i}, 1), ...
        length(detectionResult{i}));
    for m = size(groundTruth{i}, 1): -1: 1
        if (~foreground(groundTruth{i}(m, 1), groundTruth{i}(m, 2)))
            intersectionMat(m, :) = [];
            imagesFN(i) = imagesFN(i) + 1;
            continue
        end
        for d = 1: length(detectionResult{i})
            if (detectionResult{i}{d}(groundTruth{i}(m, 1), ...
                    groundTruth{i}(m, 2)))
                intersectionMat(m, d) = true;
            end
        end
    end
    
    % Recursively, check for regions with just a single point inside them
    % and a manually marked point that fall inside only one region. Such
    % point and regions are assigned to each other and are removed from the
    % matrix.
    changed = true;
    while (changed)
        changed = false;
        for m = size(intersectionMat, 1): -1: 1
            if (~any(intersectionMat(m, :)))
                intersectionMat(m, :) = [];
                imagesFN(i) = imagesFN(i) + 1;
                changed = true;
                continue
            elseif (nnz(intersectionMat(m, :) == 1))
                intersectionMat(:, intersectionMat(m, :)) = [];
                intersectionMat(m, :) = [];
                imagesTP(i) = imagesTP(i) + 1;
                changed = true;
            end
        end    
        for d = size(intersectionMat, 2): -1: 1
            if (~any(intersectionMat(:, d)))
                intersectionMat(:, d) = [];
                imagesFP(i) = imagesFP(i) + 1;
                changed = true;
                continue
            elseif (nnz(intersectionMat(:, d) == 1))
                intersectionMat(intersectionMat(:, d), :) = [];
                intersectionMat(:, d) = [];
                imagesTP(i) = imagesTP(i) + 1;
                changed = true;
            end
        end    
    end
    
    % The remaining size of the matrix determines the remanining True
    % Positives, False Negatives, and False Positives that should be
    % counted.
    imagesTP(i) = imagesTP(i) + min(size(intersectionMat));
    if (size(intersectionMat, 1) > size(intersectionMat, 2))
        imagesFN(i) = imagesFN(i) + size(intersectionMat, 1) - ...
            size(intersectionMat, 2);
    elseif (size(intersectionMat, 1) < size(intersectionMat, 2))
        imagesFP(i) = imagesFP(i) + size(intersectionMat, 2) - ...
            size(intersectionMat, 1);
    end
    
end

% Handle NaN elements: if there was no manually marked point, recall will
% be 0 if there were some detected points/regions and 1 if there no
% point/region was reported. As for precision, it will be 0 if there were
% some manually marked points in a frame and will be 1 if there were none.
imagesP = imagesTP ./ (imagesTP + imagesFP);
imagesR = imagesTP ./ (imagesTP + imagesFN);
imagesP(isnan(imagesP) & logical(cellfun(@length, groundTruth))) = 0;
imagesP(isnan(imagesP) & ~logical(cellfun(@length, groundTruth))) = 1;
imagesR(isnan(imagesR) & logical(cellfun(@length, detectionResult))) = 0;
imagesR(isnan(imagesR) & ~logical(cellfun(@length, detectionResult))) = 1;

[P, R, stdP, stdR] = deal(...
    sum(imagesTP) / (sum(imagesTP) + sum(imagesFP)), ...
    sum(imagesTP) / (sum(imagesTP) + sum(imagesFN)), ...
    std(imagesP), std(imagesR));
end

    