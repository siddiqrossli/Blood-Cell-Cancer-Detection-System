function [finalMask, intermediateImage, features] = segmentBloodCellKMeans(imagePath)

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

%% 2. K-MEANS SEGMENTATION (Image Toolbox)
L = imsegkmeans(gray,2);
intermediateImage = label2rgb(L);

% 🔴 SELECT DARKER CLUSTER (NUCLEUS)
m1 = mean(gray(L==1));
m2 = mean(gray(L==2));

if m1 < m2
    initialMask = L==1;   % darker cluster
else
    initialMask = L==2;
end

%% 3. POST-PROCESSING
finalMask = imfill(initialMask,'holes');
finalMask = bwareaopen(finalMask,80);
finalMask = imopen(finalMask,strel('disk',2));
finalMask = imclose(finalMask,strel('disk',2));

% Keep largest connected object
L2 = bwlabel(finalMask);
stats = regionprops(L2,'Area');
if ~isempty(stats)
    [~,id] = max([stats.Area]);
    finalMask = ismember(L2,id);
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
