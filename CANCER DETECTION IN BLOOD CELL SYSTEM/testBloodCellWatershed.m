clc; clear; close all;

[file,path] = uigetfile({'*.jpg;*.png;*.bmp'},'Select Blood Cell Image');
if file == 0
    return;
end

imagePath = fullfile(path,file);

[mask, Lrgb, feat] = segmentBloodCellWatershed(imagePath);

figure;
subplot(1,3,1), imshow(imread(imagePath)), title('Original');
subplot(1,3,2), imshow(Lrgb), title('Watershed Regions');
subplot(1,3,3), imshow(mask), title('Final Mask');

disp('Extracted Features:');
disp(feat);
