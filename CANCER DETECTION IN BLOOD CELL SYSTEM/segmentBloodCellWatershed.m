function [finalMask, intermediateImage, features] = segmentBloodCellWatershed(imagePath)

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

%% 2. DARK NUCLEUS SEED DETECTION
% Dark regions correspond to nucleus
bwSeed = gray < graythresh(gray)*255*0.8;

bwSeed = imopen(bwSeed, strel('disk',2));
bwSeed = imfill(bwSeed,'holes');
bwSeed = bwareaopen(bwSeed,50);

% Keep largest seed region
L = bwlabel(bwSeed);
stats = regionprops(L,'Area');
if ~isempty(stats)
    [~,id] = max([stats.Area]);
    bwSeed = ismember(L,id);
end

%% 3. WATERSHED REFINEMENT
% Distance transform from seed
D = bwdist(~bwSeed);
D = -D;
D(~bwSeed) = -Inf;

Lw = watershed(D);
intermediateImage = label2rgb(Lw);

finalMask = bwSeed;
finalMask(Lw==0) = 0;

finalMask = imclose(finalMask,strel('disk',2));
finalMask = imfill(finalMask,'holes');

%% 4. FEATURE EXTRACTION
features.Area = 0;
features.Perimeter = 0;
features.Eccentricity = 0;
features.Solidity = 0;
features.MeanIntensity = 0;

props = regionprops(finalMask,...
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
