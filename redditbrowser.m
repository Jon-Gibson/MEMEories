function redditbrowser(~,~)
prompt = {'Enter subreddit: (e.g. memes, aww)','Sort by: (e.g. top, new, hot)'};
title = 'Options';
dims = [1 35];
definput = {'memes','top'};
answer = inputdlg(prompt,title,dims,definput);
if ~isempty(answer)
    viewreddit([],[],lower(answer{1}),lower(answer{2}))
end
end

function viewreddit(~,~,subreddit,sortby)
warning ('off','all');

if ~exist('subreddit','var')
    disp('Enter subreddit: ')
    subreddit = input('', 's');
    subreddit = strtrim(subreddit);
end

if ~exist('sortby','var') || (~strcmp(sortby,'new') && ~strcmp(sortby,'hot') && ~strcmp(sortby,'top')...
        && ~strcmp(sortby,'controversial') && ~strcmp(sortby,'rising'))
    sortby = "top";
end

try
    memedata = getReddit(subreddit,sortby);
catch
    disp("Could not find the " + subreddit + " subreddit. Try another.");
    viewreddit();
    return;
end

if length(memedata) == 0
    disp("Could not find the " + subreddit + " subreddit. Try another.");
    viewreddit();
    return;
end

upvotes = [];
times = [];
date = {};
for i = 1:length(memedata)
    upvotes(i) = memedata(i).data.ups;
    TS = memedata(i).data.created_utc;
    date{i} = datestr(datevec(TS/60/60/24) + [1970 0 0 0 0 0]);
    times(i) = mod((datetime(date{i}).Hour - 5), 24);
end

%Create upvote vs data plot
figure('units','normalized','outerposition',[0 0 1 1]);
timedifference = tzoffset(datetime('today','TimeZone','local'));
scatter(datetime(date)+timedifference,upvotes,...
    80,'^','MarkerEdgeColor', [255,86,0]/255, 'MarkerFaceColor', [255,139,90]/255);
set(gcf,'Name',sortby+" r/"+subreddit);
set(gcf,'NumberTitle','off');
title("r/"+subreddit,'FontSize',24);
ylabel("Upvotes",'FontSize',18,'FontWeight','bold');
xlabel("Date",'FontSize',18,'FontWeight','bold');
axis = gca;
axis.YAxis.Exponent = 0;

%Make plotted points clickable
datacursormode on;
fig = gcf;
dcm_obj = datacursormode(fig);
set(dcm_obj,'UpdateFcn',{@myupdatefcn,memedata});
end

function txt = myupdatefcn(~,event_obj,memedata,I)
if ~exist('I','var')
    figure('Name','Reddit Preview','NumberTitle','off');
    I = get(event_obj, 'DataIndex');
elseif strcmp(I,"")
    answer = inputdlg("Go to post number:","Select Post",[1 35]);
     I = str2double(answer{1});
    if isnan(I) 
        I = 1;
    end
end

if I > length(memedata)
    I = mod(I,length(memedata));
end

if I == 0
    I = length(memedata);
end

try
    %Display picture preview of post
    imshow(imread(memedata(I).data.url))
catch
    try
        %Usually a gif, imgur folder, or video, so use thumbnail instead
        imshow(imread(memedata(I).data.thumbnail))
    catch
        try
            %Probably just text, show default logo
            imshow(imread('https://cdn.dribbble.com/users/555368/screenshots/1520588/reddit_drib_1x.png'))
        catch
        end
    end
end

set(gcf,'Position',[100 50 700 500]);

% Create push buttons
uicontrol('Style', 'pushbutton', 'String', 'Open Post',...
    'Position', [10 10 90 30],...
    'Callback', {@openWeb,['https://reddit.com' memedata(I).data.permalink]});
uicontrol('Style', 'pushbutton', 'String', 'Share Post',...
    'Position', [100 10 90 30],...
    'Callback', {@share,['https://reddit.com' memedata(I).data.permalink]});
uicontrol('Style', 'pushbutton', 'String', 'Share Image',...
    'Position', [190 10 90 30],...
    'Callback', {@share,memedata(I).data.url});
uicontrol('Style', 'pushbutton', 'String', '<',...
    'Position', [10 40 20 20],...
    'Callback', {@myupdatefcn,memedata,I-1});
uicontrol('Style', 'pushbutton', 'String', num2str(I),...
    'Position', [30 40 20 20],...
    'Callback', {@myupdatefcn,memedata,""});
uicontrol('Style', 'pushbutton', 'String', '>',...
    'Position', [50 40 20 20],...
    'Callback', {@myupdatefcn,memedata,I+1});

data = ("Upvotes: " + memedata(I).data.ups + "  |  Comments: "+memedata(I).data.num_comments);
uicontrol('Style', 'text', 'String', data,...
    'Position', [290 10 200 20], 'HorizontalAlignment', 'left');

%Set and wrap title to reasonable length
title({memedata(I).data.title})
figpos = get(gcf,'Position');
ha=gca; NoCharPerLine = figpos(3) / 8;
if ismatrix(ha(end).Title.String) && size(ha(end).Title.String,2) > NoCharPerLine
    II=strfind((ha(end).Title.String(1:NoCharPerLine)),' '); % find last occurence of a space
    LastSpaceIndex=II(end);
    ha(end).Title.String={ha(end).Title.String(1:LastSpaceIndex-1) ;
        ha(end).Title.String(LastSpaceIndex+1:end)};
end
if iscell(ha(end).Title.String)
    while size(ha(end).Title.String{end},2) > NoCharPerLine
        STR=ha(end).Title.String{end};
        II=strfind(STR,' '); % find last occurence of a space
        beforeBreak = II(II < NoCharPerLine);
        LastSpaceIndex=beforeBreak(end);
        ha(end).Title.String{end}=STR(1:LastSpaceIndex-1);
        ha(end).Title.String{end+1}=STR(LastSpaceIndex+1:end);
        set(gca,'Position',get(gca,'Position')-[0 0 0 .06]);
    end
end
try
    xl = xlabel(memedata(I).data.selftext(1:80)+"...");
catch
    xl = xlabel(memedata(I).data.selftext(1:end));
end
if iscell(xl.String) 
    if length(xl.String) > 1
        xl.String = xl.String{1} + "...";
    end
else
    
end
xl.Position = xl.Position - [0 20 0];

% Remove datatip text
txt = {};
end

% Use reddit API
function memedata = getReddit(subreddit,sortby)
MAX_REQUESTS = 1; % Increase this for more memes
after = '';
memedata = [];
for requests = 1:MAX_REQUESTS
    [response,~,~] = send(matlab.net.http.RequestMessage,...
        "https://www.reddit.com/r/"+urlencode(subreddit)+"/"+sortby+"/.json?t=all&limit=100&after="+after);
    newdata = response.Body.Data.data.children;
    memedata = [memedata; newdata];
    after = response.Body.Data.data.after;
end
end

function openWeb(~,~,url)
web(url)
end