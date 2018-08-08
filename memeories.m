function memeories()
close all;
figure('Name','Math(Work)s','NumberTitle','off','Resize','off');
% Create menu
uicontrol('Style', 'text', 'FontSize', 30, 'String', 'MEMEories',...
    'Position', [30 320 500 50], 'FontName', 'comic sans ms');

uicontrol('Style', 'pushbutton', 'FontSize', 18, 'String', 'Browse Old Memes',...
    'Position', [30 210 500 80],...
    'Callback', @redditOptions, 'FontName', 'comic sans ms');

uicontrol('Style', 'pushbutton', 'FontSize', 18, 'String', 'Create New Memes',...
    'Position', [30 110 500 80],...
    'Callback', @allthememes, 'FontName', 'comic sans ms');

uicontrol('Style', 'text', 'String', 'by Alex, Alexa, Jon, and William',...
    'Position', [350 10 200 20], 'FontName', 'comic sans ms');
end

%% Browse Reddit

function redditOptions(~,~)
prompt = {'Enter subreddit: (e.g. memes, aww)','Sort by: (e.g. top, new, hot)'};
title = 'Options';
dims = [1 35];
definput = {'memes','top'};
answer = inputdlg(prompt,title,dims,definput);
if ~isempty(answer)
    viewMemes([],[],lower(answer{1}),lower(answer{2}))
end
end

function viewMemes(~,~,subreddit,sortby)
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
    viewMemes();
    return;
end

if length(memedata) == 0
    disp("Could not find the " + subreddit + " subreddit. Try another.");
    viewMemes();
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
    answer = inputdlg("Go to post number:","Select Post",[1 35],"");
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

%% Create Memes
function mememaker(~,~,shuffly,ehrmagerdify,id)
warning ('off','all');
% Display original blank meme
figure;
set(gcf,'Position',[100 100 500 500]);

if strcmp(id,"0")
    ids = ["102156234" "112126428" "8072285" "16464531" "42784038" "84341851"...
        "61581" "124822590" "143601" "163573" "6531067" "74191766" "100777631"...
        "68690826" "100952" "119139145" "92828380" "96572077" "27813981" "326093"...
        "61535" "5471748" "107043" "1006090" "96132919", "347390"];
    index = randi([1 length(ids)],1,1);
    id = ids(index);
end

space = urlencode(" ");
[response,~,~] = send(matlab.net.http.RequestMessage,...
    strcat("https://api.imgflip.com/caption_image?template_id=",...
    id,"&text0=","TOP%20TEXT","&text1=","BOTTOM%20TEXT",...
    "&username=imgflip_hubot&password=imgflip_hubot")); % Don't steal this account
imshow(imread(response.Body.Data.data.url));

% get user input
try
[top, bottom] = userInput();
catch
    return;
end
top = urlencode(top);
bottom = urlencode(bottom);

% ehrmagerdify if checked
ischecked = get(ehrmagerdify,'Value');
if (ischecked)
    top = convert_EHRMAGERD(top);
    bottom = convert_EHRMAGERD(bottom);
end

clf;

% get random new id if shuffling
if shuffly
    index = randi([1 length(ids)],1,1);
    id = ids(index);
end

% API doesn't like empty parameters
if strcmp("", top)
    top = space;
end
if strcmp("", bottom)
    bottom = space;
end

% display meme with text
[response,~,~] = send(matlab.net.http.RequestMessage,...
    strcat("https://api.imgflip.com/caption_image?template_id=",...
    id,"&text0=",top,"&text1=",bottom,...
    "&username=imgflip_hubot&password=imgflip_hubot"));
imshow(imread(response.Body.Data.data.url))

uicontrol('Style', 'pushbutton', 'String', 'Share on Facebook',...
    'Position', [10 10 200 30],...
    'Callback', {@share,response.Body.Data.data.url});

end

function share(~,~,url)
web("https://www.facebook.com/sharer/sharer.php?u="+url)
end

% gets user input for texts
function [top, bottom] = userInput(~,~)
prompt = {'Top Text','Bottom Text'};
title = 'Text';
dims = [1 35];
answer = inputdlg(prompt,title,dims);

if ~isempty(answer)
    top = answer{1};
    bottom = answer{2};
end
end

% Generate meme format list
function allthememes(~,~)
off = 20;
yoffset = off;
xoffset = 20;
figure('Name','Choose meme format','NumberTitle','off')
set(gcf,'Position',[400 100 340 320]);

% Create meme buttons
ehrmagerd = uicontrol('Style', 'checkbox', 'String', 'ERMAGERDify',...
    'Position', [xoffset yoffset 150 20]);

yoffset = yoffset + off * 2;

uicontrol('Style', 'pushbutton', 'String', 'Mocking Spongebob',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"102156234"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Distracted Boyfriend',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"112126428"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Doge',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"8072285"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', "Sippin' Tea",...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"42784038"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Dark Kermit',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"84341851"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Push it Somewhere Else',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"61581"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Taking Exit',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"124822590"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Steve Harvey',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"143601"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Spongebob Imagination',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"163573"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'See, Nobody Cares',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"6531067"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Arthur Fist',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"74191766"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Is This A...',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"100777631"});

% Second column
yoffset = off;
xoffset = xoffset + 150;

uicontrol('Style', 'pushbutton', 'String', 'Random Format',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"0"});
yoffset = yoffset + 2*off;

uicontrol('Style', 'pushbutton', 'String', 'Caveman Spongebob',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"68690826"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Overly Attached Girlfriend',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"100952"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Hit The Button',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"119139145"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Confused Math Lady',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"92828380"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Blinking White Guy',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"96572077"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Hide The Pain Harold',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"27813981"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Spongebob Um Actually',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"326093"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Buzz Lightyear',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"347390"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Joseph Ducreux',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"61535"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', "It's OK",...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"5471748"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Fire Cows',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"107043"});

yoffset = yoffset + off;

uicontrol('Style', 'pushbutton', 'String', 'Bill Nye',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@mememaker,false,ehrmagerd,"1006090"});

end

function result = convert_EHRMAGERD(string)
inter = '';
for i = 1:(strlength(string))
    character = string(i);
    if i < strlength(string) && vowel_find(character)
        if vowel_find(string(i+1))
            continue
        else
            inter = [inter, 'ER'];
        end
    elseif strcmpi(character, 'y')
        inter = [inter, 'AH'];
    else
        inter = [inter, character];
    end
end
result = upper(inter);
end

function result = vowel_find(i)
result = strcmpi(i, 'a') || strcmpi(i, 'e') || ...
    strcmpi(i, 'i') || strcmpi(i, 'o') || strcmpi(i, 'u');
end
