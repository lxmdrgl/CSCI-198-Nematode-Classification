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

    img=im2gray(frame);
    [n1,n2]=size(img);
%    imgc=adapthisteq(img);
    imgc=img;
    imgb=imbinarize(imgc);
    imgb = (imgb == 0); % flip it
    cc4 = bwconncomp(imgb,4);

    % threshold to find the worm in the image
    maxpixel=2000; % max number of pixels for the worm
    minpixel=100; % min number of pixels for the worm
    newc={};
    for j=1:cc4.NumObjects
        s(j)=size(cc4.PixelIdxList{1,j},1);
        if s(j)>minpixel && s(j)<maxpixel 
            if (isempty(newc))
                newc{1}=cc4.PixelIdxList{1,j};
            else
                newc={newc,cc4.PixelIdxList{1,j}};
            end
        end
    end
    newcsize=size(newc,2);

    objsize(i)=size(newc{1},1);

    vpixels=zeros(objsize(i),2);
    for p=1:objsize(i)
        x=newc{1}(p);
        vpixels(p,1)=floor(x/n1);
        vpixels(p,2)=mod(x,n1);
    end

    imin=min(vpixels(:,1));
    imax=max(vpixels(:,1));
    jmin=min(vpixels(:,2));
    jmax=max(vpixels(:,2));
    
    n1=imax-imin+1;
    n2=jmax-jmin+1;

    ROI=zeros(n1,n2);
    for p=1:objsize(i)
        ROI(vpixels(p,1)-imin+1,vpixels(p,2)-jmin+1)=1;
    end

    figure(1)
    subplot(1,4,1);
    imagesc(ROI);
    
    stats = regionprops(logical(ROI), 'Centroid','MajorAxisLength','MinorAxisLength','Orientation');

    ROIrot = imrotate(ROI,-stats.Orientation);
    subplot(1,4,2);
    imagesc(ROIrot);

    statsrot = regionprops(logical(ROIrot), 'BoundingBox');

    size1=statsrot.BoundingBox(3);
    size2=statsrot.BoundingBox(4);
    aspectratio=max(size1,size2)/min(size1,size2);
    
    out = bwskel(logical(ROI));

    subplot(1,4,3);
    imagesc(out);
    out=out(:);
    idx1=find(out==1);
    nematode_length=size(idx1,1);
 
    cc4.NumObjects=newcsize;
    cc4.PixelIdxList=newc;

    L4 = labelmatrix(cc4);

    RGB_label = label2rgb(L4);

    subplot(1,4,4);
    imshow(RGB_label);

    i=i+1;
end

fprintf('That s all folks\n');