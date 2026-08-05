function [finalMask, intermediateImage, features] = segmentBloodCellColor(imagePath)

%% 1. LOAD IMAGE
original = imread(imagePath);
original = imresize(original,[400 400]);

% Convert to HSV color space
hsvImg = rgb2hsv(original);
H = hsvImg(:,:,1);
S = hsvImg(:,:,2);
V = hsvImg(:,:,3);

% Convert grayscale for intensity feature
gray = rgb2gray(original);

%% 2. COLOR THRESHOLD (PURPLE / BLUE RANGE)
% Purple nucleus usually has:
% - High saturation
% - Medium to low brightness
% - Hue around 0.65–0.85

maskColor = (H > 0.55 & H < 0.85) & ...
            (S > 0.35) & ...
            (V < 0.85);

intermediateImage = maskColor;

%% 3. MORPHOLOGICAL CLEANUP
maskColor = imopen(maskColor, strel('disk',2));
maskColor = imclose(maskColor, strel('disk',3));
maskColor = imfill(maskColor,'holes');
maskColor = bwareaopen(maskColor,80);

% Keep largest connected object
L = bwlabel(maskColor);
stats = regionprops(L,'Area');
if ~isempty(stats)
    [~,id] = max([stats.Area]);
    finalMask = ismember(L,id);
else
    finalMask = maskColor;
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
