close all
clear
clc

% Read video file
filename='IMG_2145.mp4'; % Need to convert the mov file into mp4
fprintf(['Read video: ' filename '\n']);

vidObj = VideoReader(filename);

NumFrames=vidObj.NumFrames;

i=1;
while hasFrame(vidObj)
    frame = readFrame(vidObj);
    
    img=im2gray(frame); % grayscale the image
    [n1,n2]=size(img); % Image size (rows, cols)
%    imgc=adapthisteq(img);
    imgc=img;
    imgb=imbinarize(imgc); % automatically make black or white
    imgb = (imgb == 0); % invert black and white
    cc4 = bwconncomp(imgb,4); %4-connectivity

    % threshold to find the worm in the image
    maxpixel=2000; % max number of pixels for the worm
    minpixel=100; % min number of pixels for the worm
    newc={}; % stores only good size blobs
    for j=1:cc4.NumObjects
        s(j)=size(cc4.PixelIdxList{1,j},1); % size of blob j
        if s(j)>minpixel && s(j)<maxpixel 
            if (isempty(newc))
                newc{1}=cc4.PixelIdxList{1,j};
            else
                newc={newc,cc4.PixelIdxList{1,j}};
            end
        end
    end
    newcsize=size(newc,2);

    % if no blobs pass size filter, error

    objsize(i)=size(newc{1},1); % chooses the worm blob

    vpixels=zeros(objsize(i),2); % converts linear indicies into (row, col) pixel coords
    for p=1:objsize(i)
        x=newc{1}(p);
        % 1D index into 2D coordinates
        vpixels(p,1)=floor(x/n1);
        vpixels(p,2)=mod(x,n1);
    end
    
    % Find bounding box to crop image
    imin=min(vpixels(:,1));
    imax=max(vpixels(:,1));
    jmin=min(vpixels(:,2));
    jmax=max(vpixels(:,2));
    
    n1=imax-imin+1;
    n2=jmax-jmin+1;

    ROI=zeros(n1,n2); % Region of Interest: cropped image around worm
    for p=1:objsize(i)
        ROI(vpixels(p,1)-imin+1,vpixels(p,2)-jmin+1)=1;
    end

    % Figure 1: raw cropped worm mask
    figure(1)
    subplot(1,4,1);
    imagesc(ROI);
    
    % stats gets shape properties of the blob
    stats = regionprops(logical(ROI), 'Centroid','MajorAxisLength','MinorAxisLength','Orientation');
    
    % rotate ROI is worm is straight according to orientation
    ROIrot = imrotate(ROI,-stats.Orientation);
    subplot(1,4,2);
    imagesc(ROIrot);
    
    % Measure bounding box after rotation
    statsrot = regionprops(logical(ROIrot), 'BoundingBox');

    size1=statsrot.BoundingBox(3); % width
    size2=statsrot.BoundingBox(4); % height
    aspectratio=max(size1,size2)/min(size1,size2); 
    
    % Skeletionize to 1-pixel wide spine
    out = bwskel(logical(ROI));

    subplot(1,4,3);
    imagesc(out);

    out=out(:); % flatten into 1D
    idx1=find(out==1); % indices of skeleton pixels
    nematode_length=size(idx1,1); % length in pixels
 
    cc4.NumObjects=newcsize;
    cc4.PixelIdxList=newc;

    L4 = labelmatrix(cc4); % label image: each blob has integer label

    RGB_label = label2rgb(L4); % convert labels into colored image

    subplot(1,4,4);
    imshow(RGB_label);
    
    i=i+1; % go to next frame
end

fprintf('That s all folks\n');