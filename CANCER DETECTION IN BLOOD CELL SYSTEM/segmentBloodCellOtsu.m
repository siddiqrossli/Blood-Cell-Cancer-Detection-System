function [finalMask, intermediateImage, features] = segmentBloodCellOtsu(imagePath)

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
gray = medfilt2(gray,[3 3]);   % noise reduction

%% 2. OTSU THRESHOLDING
level = graythresh(gray);
bw = imbinarize(gray, level);

% 🔴 Blood nucleus is DARK → invert binary
bw = ~bw;

intermediateImage = bw;

%% 3. POST-PROCESSING
finalMask = imfill(bw,'holes');
finalMask = bwareaopen(finalMask,80);
finalMask = imopen(finalMask,strel('disk',2));
finalMask = imclose(finalMask,strel('disk',2));

% Keep largest object
L = bwlabel(finalMask);
stats = regionprops(L,'Area');
if ~isempty(stats)
    [~,id] = max([stats.Area]);
    finalMask = ismember(L,id);
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
