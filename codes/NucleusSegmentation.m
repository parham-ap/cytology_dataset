% NucleusSegmentation is the baseline segmentation method for the dataset.
% This method is a slightly modified version of the method presented in the
% following reference. If you use it, please consider citing it:
% 
% Reference:
% Hady Ahmady Phoulady, Dmitry B. Goldgof, Lawrence O. Hall, Peter R. 
% Mouton, A Framework for Nucleus and Overlapping Cytoplasm Segmentation in
% Cervical Cytology Extended Depth of Field and Volume Images, Computerized
% Medical Imaging and Graphics, June 2017
%
% @article{phoulady2017framework,
% 	title={A framework for nucleus and overlapping cytoplasm segmentation
% 	in cervical cytology extended depth of field and volume images},
% 	author={{Ahmady Phoulady}, Hady and Goldgof, Dmitry and Hall, Lawrence
% 	O and Mouton, Peter R},
% 	journal={Computerized Medical Imaging and Graphics},
% 	volume={59},
% 	pages={38--49},
% 	year={2017},
% 	publisher={Elsevier}
% }
% 
% Copyright (c) 2017, Hady Ahmady Phoulady
% Department of Computer Science,
% University of Southern Maine, Portland, ME.
%
% Last modified: December 16, 2017

function [nuclei, masks] = NucleusSegmentation(I, cellsInfo)

if (size(I, 3) == 3)
    I = rgb2gray(I);
end

if (~exist('cellsInfo', 'var'))
    cellsInfo = struct('MinSize', 150, 'MinMean', 30, ...
        'MaxMean', 150, 'MinSolidity', 0.9);
end

lowN = floor(cellsInfo.MinMean / 10) * 10;
highN = ceil(cellsInfo.MaxMean / 10) * 10;


I = wiener2(I, [5 5]);
nuclei = zeros(size(I));
allPixels = length(I(:));

for thresh = lowN: 10: highN
    binaryImage = I <= thresh;
    if sum(binaryImage(:)) > allPixels / 5
        break
    end
    blobs = bwlabel(binaryImage);
    regProp = regionprops(blobs, 'Area', 'Solidity', 'PixelIdxList');
    addTheseRegions = true(length(regProp), 1);
    removeTooConcaveTooSmallBlobs = (...
        [regProp.Area] < cellsInfo.MinSize) | ...
        ([regProp.Solidity] < cellsInfo.MinSolidity);
    
    addTheseRegions(removeTooConcaveTooSmallBlobs) = false;
    
    pixelsAlreadyInNuclei = (blobs ~= 0 & nuclei ~= 0);
    blobsAlreadyInNuclei = unique(blobs(pixelsAlreadyInNuclei));
    
    nuclei = bwlabel(nuclei);
    nucRegProp = regionprops(nuclei, 'Solidity', 'PixelIdxList');
    if (~isempty(blobsAlreadyInNuclei))
        for j = blobsAlreadyInNuclei'
            intersectWithThese = unique(nuclei(blobs == j));
            if (regProp(j).Solidity < ...
                    max([nucRegProp(...
                    intersectWithThese(intersectWithThese > 0)).Solidity]))
                addTheseRegions(j) = false;
            end
        end
    end
    
    nuclei(cat(1, regProp(addTheseRegions).PixelIdxList)) = 1;
    nuclei = logical(nuclei);
    
end

nuclei = bwareaopen(imfill(nuclei, 'holes'), floor(cellsInfo.MinSize), 8);

dilatedSeg = imdilate(nuclei, strel('disk', 1));
[regionsLabel, ~] = bwlabel(nuclei);
[dilatedRegionsLabel, numOfDilatedRegions] = bwlabel(dilatedSeg);
for l = 1: numOfDilatedRegions
    if (length(unique(regionsLabel(dilatedRegionsLabel == l))) >= 3)
        dilatedSeg(dilatedRegionsLabel == l) = ...
            nuclei(dilatedRegionsLabel == l);
    end
end
nuclei = dilatedSeg;

imageBoundary = false(size(nuclei));
imageBoundary(1, :) = true;
imageBoundary(end, :) = true;
imageBoundary(:, 1) = true;
imageBoundary(:, end) = true;
nuclei(imreconstruct(imageBoundary, nuclei)) = false;

[L, num] = bwlabel(nuclei);
masks = cell(1, num);
for i = 1: num
    masks{i} = L == i;
end