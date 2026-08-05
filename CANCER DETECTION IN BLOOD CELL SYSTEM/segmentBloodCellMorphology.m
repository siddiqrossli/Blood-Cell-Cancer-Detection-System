function [finalMask, intermediateImage, features] = segmentBloodCellMorphology(imagePath)

%% 1. LOAD IMAGE
original = imread(imagePath);
original = imresize(original,[400 400]);

% Convert to grayscale
if size(original,3) == 3
    gray = rgb2gray(original);
else
    gray = original;
end

gray = im2uint8(gray);
gray = medfilt2(gray,[3 3]);

%% 2. INITIAL THRESHOLD (PRE-SEGMENTATION)
% Otsu used only as starting point
level = graythresh(gray);
bw = imbinarize(gray, level);
bw = ~bw;   % nucleus is dark

intermediateImage = bw;

%% 3. MORPHOLOGICAL REFINEMENT
se = strel('disk',3);

% Remove small noise
bw = imopen(bw, se);

% Close gaps
bw = imclose(bw, se);

% Fill holes
bw = imfill(bw,'holes');

% Remove tiny objects
bw = bwareaopen(bw,100);

% Keep largest connected component
L = bwlabel(bw);
stats = regionprops(L,'Area');
if ~isempty(stats)
    [~,id] = max([stats.Area]);
    finalMask = ismember(L,id);
else
    finalMask = bw;
end

%% 4. FEATURE EXTRACTION
features.Area = 0;
features.Perimeter = 0;
features.Eccentricity = 0;
features.Solidity = 0;
features.MeanIntensity = 0;

props = regionprops(finalMask, ...
    'Area','Perimeter','Eccentricity','Solidity');

if ~isempty(props)
    features.Area = props.Area;
    features.Perimeter = props.Perimeter;
    features.Eccentricity = props.Eccentricity;
    features.Solidity = props.Solidity;

    masked = gray;
    masked(~finalMask) = 0;
    features.MeanIntensity = mean(masked(masked>0));
end

end
