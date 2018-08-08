function share(var1,var2,var3)
if ~exist('var12','var') && ~exist('var3','var')
    link = var1;
else
    link = var3;
end
web("https://www.facebook.com/sharer/sharer.php?u="+link)
end