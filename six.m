%init
close all
im = double(imread('bamse.jpg'))/255;
[M N P] = size(im);
imshow(im, [])
gim = rgb2gray(im);

%Pick out the colors and the text
colors = [];
for x = 1:M
    for y = 1:N
        r = im(x,y,1);
        g = im(x,y,2);
        b = im(x,y,3);
        
        if abs(r-g) > 0.1 || abs(r-b) > 0.1 || abs(b-g) > 0.1
            colors = [colors ; x y r g b];
        end    
    end
end
idx = kmeans(colors,5, 'Replicates', 2);

rgbclrs = zeros(5,3);
tops = 1:5*0;
bots = 1:5*0;
for i=1:5
    tops(i) = max(colors(idx == i,1));
    bots(i) = min(colors(idx == i,1));
    rgbclrs(i,:) = mean(colors(idx == i,3:5));
end
temp = rgbclrs;
sorttops = sort(tops);
for i = 1:5
    rgbclrs(i,:) = temp(tops == sorttops(i),:);
end

imforlbls = im;
for i = 1:5
    cells = colors(idx == i,:);
    for j = 1:length(cells)
        imforlbls(cells(j, 1), cells(j, 2),1) = 0;
        imforlbls(cells(j, 1), cells(j, 2),2) = 0;
        imforlbls(cells(j, 1), cells(j, 2),3) = 0;
    end
end
imforlbls(19:130,152:530,:) = 1;
imshow(imforlbls, [])


%Pick out grouped white areas
grpimg = bwlabel(rgb2gray(imforlbls) > 0.5,4);
ngrps = max(max(grpimg));
groups = zeros(N*M,3);
for x = 1:M
    for y = 1:N
        groups(x*N+y,:) = [x y grpimg(x,y)];    
    end
end

%Pick out grouped black areas
grpimgb = bwlabel(rgb2gray(imforlbls) < 0.5,4);
ngrpsb = max(max(grpimgb));
groupsb = zeros(N*M,3);
for x = 1:M
    for y = 1:N
        groupsb(x*N+y,:) = [x y grpimgb(x,y)];    
    end
end

potnumbers = [];
couples = [];
for i = 1:ngrpsb
    neighbour = 0;
    cells = groupsb(groupsb(:,3)== i,:);
    stop = 0;
    for j = 1:size(cells,1)
        if ~stop
            diff = [1 0; 0 1; -1 0; 0 -1];
            x = cells(j,1);
            y = cells(j,2);

            for d = diff
                n = grpimg(x+d(1), y+d(2));
                if n ~= 0
                    if neighbour == 0
                        neighbour = n;
                    elseif n ~= neighbour
                        groupsb(groupsb(:,3)== i,3) = 0;
                        stop=1;
                    end
                end
            end
        end
    end
    if ~stop
        couples = [couples; i neighbour];
    end
end

segments = cell(1,ngrpsb);
features = [];
dispim = im;
for i = 1:ngrpsb
    cells = groupsb(groupsb(:,3)==i,:);
    if size(cells,1) > 0
        segment = grpimgb(min(cells(:,1)):max(cells(:,1)), min(cells(:,2)):max(cells(:,2)));
        sz = size(segment);
        if sz(2) < sz(1)
            segment = grpimgb(min(cells(:,1)):max(cells(:,1)), min(cells(:,2)) - floor((sz(1) - sz(2))/2):max(cells(:,2))+floor((sz(1) - sz(2))/2 + 0.5));
        end
        if sz(1) < sz(2)
            segment = grpimgb(min(cells(:,1)) - floor((sz(2) - sz(1))/2):max(cells(:,1)) + floor((sz(2) - sz(1))/2 + 0.5), min(cells(:,2)):max(cells(:,2)));
        end
        
        segment = segment==i;
        sz = size(segment);
        
        if sz(1) > 1 && sz(2) > 1
            features = [features; i getFeatures(segment)];
        end
    end
end

%This is hardcoded but the alternative is to provide examples of numbers by
%hand anyway
classes = zeros(5,4);
classes(1,:) = features(features(:,1) == 12,2:end);
classes(2,:) = features(features(:,1) == 8,2:end);
classes(3,:) = features(features(:,1) == 9,2:end);
classes(4,:) = features(features(:,1) == 10,2:end);
classes(5,:) = features(features(:,1) == 11,2:end);

newim = im;
for i = 11:size(features,1)
    dist = sum((classes-features(i,2:end)).^2,2);   
    if min(dist) < 210
        clr = rgbclrs(dist==min(dist),:);
        grp = couples(couples(:,1) == features(i,1),2);
        pixels = groups(groups(:,3) == grp,:);
        for p = 1:size(pixels,1)
            newim(pixels(p,1),pixels(p,2),:) = clr;
        end
    end
end
imshow(newim, []);
