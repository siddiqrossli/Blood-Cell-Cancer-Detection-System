function BloodCellSegmentationGUI
clc; close all;

% -----------------------------
% GLOBAL APP DATA
% -----------------------------
app.ImagePath = [];
app.LastFeatures = [];
app.AllFeatures = struct();

% -----------------------------
% MAIN WINDOW
% -----------------------------
fig = uifigure('Name','Blood Cell Cancer Segmentation',...
    'Position',[100 100 1200 650],...
    'Color',[0.15 0.15 0.15]);

% -----------------------------
% BUTTONS
% -----------------------------
uibutton(fig,'Text','Load Image',...
    'Position',[30 580 180 40],...
    'ButtonPushedFcn',@loadImage);

uilabel(fig,'Text','Select Segmentation Method:',...
    'Position',[30 520 220 25],...
    'FontColor','w');

ddMethod = uidropdown(fig,...
    'Items',{'Otsu','KMeans','Watershed','Morphology','Color'},...
    'Position',[30 490 180 30]);

uibutton(fig,'Text','Run Segmentation',...
    'Position',[30 440 180 40],...
    'ButtonPushedFcn',@runSegmentation);

uibutton(fig,'Text','Extract Features (All Methods)',...
    'Position',[30 390 180 40],...
    'ButtonPushedFcn',@extractAllFeatures);

uibutton(fig,'Text','Download Notes',...
    'Position',[30 340 180 40],...
    'ButtonPushedFcn',@downloadNotes);

% -----------------------------
% IMAGE AXES
% -----------------------------
axOriginal = uiaxes(fig,'Position',[260 380 260 220]);
title(axOriginal,'Original','Color','w');

axIntermediate = uiaxes(fig,'Position',[550 380 260 220]);
title(axIntermediate,'Intermediate Mask','Color','w');

axFinal = uiaxes(fig,'Position',[840 380 260 220]);
title(axFinal,'Final Mask','Color','w');

% -----------------------------
% FEATURE TABLE (COMPACT + UNITS)
% -----------------------------
tbl = uitable(fig,...
    'Position',[260 300 840 55],...
    'ColumnName',{ ...
        'Area (px²)', ...
        'Perimeter (px)', ...
        'Eccentricity (-)', ...
        'Solidity (-)', ...
        'Mean Intensity (0–255)'},...
    'RowName',{},...
    'Data',zeros(1,5));

% -----------------------------
% NOTES PANEL
% -----------------------------
uilabel(fig,'Text','Extraction Notes (All Methods):',...
    'Position',[30 300 220 25],...
    'FontColor','w');

txtNotes = uitextarea(fig,...
    'Position',[30 80 220 210],...
    'Editable','off');

% -----------------------------
% BAR CHART AXES
% -----------------------------
axBar = uiaxes(fig,'Position',[260 50 840 220]);
title(axBar,'Feature Comparison Across Methods','Color','w');
grid(axBar,'on');

% =========================================================
% CALLBACK FUNCTIONS
% =========================================================

function loadImage(~,~)
    [file,path] = uigetfile({'*.jpg;*.png;*.bmp'},'Select Blood Cell Image');
    if file == 0; return; end

    app.ImagePath = fullfile(path,file);
    img = imread(app.ImagePath);
    imshow(img,'Parent',axOriginal);
end

% ---------------------------------------------------------

function runSegmentation(~,~)

    if isempty(app.ImagePath)
        uialert(fig,'Please load an image first.','No Image');
        return;
    end

    method = ddMethod.Value;

    try
        switch method
            case 'Otsu'
                [finalMask, intermediate, feat] = segmentBloodCellOtsu(app.ImagePath);

            case 'KMeans'
                [finalMask, intermediate, feat] = segmentBloodCellKMeans(app.ImagePath);

            case 'Watershed'
                [finalMask, intermediate, feat] = segmentBloodCellWatershed(app.ImagePath);

            case 'Morphology'
                [finalMask, intermediate, feat] = segmentBloodCellMorphology(app.ImagePath);

            case 'Color'
                [finalMask, intermediate, feat] = segmentBloodCellColor(app.ImagePath);
        end
    catch ME
        uialert(fig,ME.message,'Segmentation Error');
        return;
    end

    % Display images
    imshow(intermediate,'Parent',axIntermediate);
    imshow(finalMask,'Parent',axFinal);

    % Update table
    tbl.Data = [ ...
        feat.Area, ...
        feat.Perimeter, ...
        feat.Eccentricity, ...
        feat.Solidity, ...
        feat.MeanIntensity];

    app.LastFeatures = feat;
end

% ---------------------------------------------------------

function extractAllFeatures(~,~)

    if isempty(app.ImagePath)
        uialert(fig,'Please load an image first.','No Image');
        return;
    end

    methods = {'Otsu','KMeans','Watershed','Morphology','Color'};
    app.AllFeatures = struct();

    notes = sprintf([ ...
        "FEATURE EXTRACTION SUMMARY\n" + ...
        "====================================\n" + ...
        "Units:\n" + ...
        "Area = pixel^2\n" + ...
        "Perimeter = pixel\n" + ...
        "Eccentricity = ratio\n" + ...
        "Solidity = ratio\n" + ...
        "Mean Intensity = grayscale (0–255)\n\n"]);

    for i = 1:length(methods)
        m = methods{i};

        try
            switch m
                case 'Otsu'
                    [~,~,f] = segmentBloodCellOtsu(app.ImagePath);
                case 'KMeans'
                    [~,~,f] = segmentBloodCellKMeans(app.ImagePath);
                case 'Watershed'
                    [~,~,f] = segmentBloodCellWatershed(app.ImagePath);
                case 'Morphology'
                    [~,~,f] = segmentBloodCellMorphology(app.ImagePath);
                case 'Color'
                    [~,~,f] = segmentBloodCellColor(app.ImagePath);
            end
        catch
            continue;
        end

        app.AllFeatures.(m) = f;

        notes = notes + sprintf([ ...
            "Method: %s\n" + ...
            " Area: %.2f px^2\n" + ...
            " Perimeter: %.2f px\n" + ...
            " Eccentricity: %.4f\n" + ...
            " Solidity: %.4f\n" + ...
            " Mean Intensity: %.2f\n\n"], ...
            m, f.Area, f.Perimeter, f.Eccentricity, f.Solidity, f.MeanIntensity);
    end

    txtNotes.Value = char(notes);

    plotComparisonBar(app.AllFeatures);
end

% ---------------------------------------------------------

function plotComparisonBar(featuresStruct)

    cla(axBar);

    methods = fieldnames(featuresStruct);
    numMethods = numel(methods);
    raw = zeros(numMethods,5);

    for i = 1:numMethods
        f = featuresStruct.(methods{i});
        raw(i,:) = [ ...
            f.Area, ...
            f.Perimeter, ...
            f.Eccentricity, ...
            f.Solidity, ...
            f.MeanIntensity];
    end

    % Normalize per column (better comparison)
    data = raw ./ max(raw,[],1);

    bar(axBar,data);
    axBar.XTickLabel = methods;
    ylabel(axBar,'Normalized Value (0–1)');
    legend(axBar,{'Area','Perimeter','Eccentricity','Solidity','Mean Intensity'},...
        'TextColor','w','Location','northoutside');
    grid(axBar,'on');
end

% ---------------------------------------------------------

function downloadNotes(~,~)

    if isempty(txtNotes.Value)
        uialert(fig,'No notes available.','Empty');
        return;
    end

    [file,path] = uiputfile('ExtractionNotes.txt','Save Notes');
    if file == 0; return; end

    filepath = fullfile(path,file);

    % FIX EMPTY FILE BUG
    if iscell(txtNotes.Value)
        content = strjoin(txtNotes.Value,newline);
    else
        content = txtNotes.Value;
    end

    fid = fopen(filepath,'w');
    fprintf(fid,'%s',content);
    fclose(fid);

    uialert(fig,'Notes saved successfully.','Done');
end

end
