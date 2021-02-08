function out = getFeatures( segment )
    sz = size(segment);
    segment = imresize(segment,28/min(sz));
    edgehoriz = convn(segment, [-1 1]);
    edgevert = convn(segment, [-1 1]');
    sumrh = sum(sum(abs(edgehoriz(:,28/2:end))));
    sumlh = sum(sum(abs(edgehoriz(:,1:14))));
    summv = sum(sum(abs(edgevert(10:18,:))));
    sumlv = sum(sum(abs(edgevert(:,1:14))));
    out = [sumrh summv sumlh sumlv];
end

