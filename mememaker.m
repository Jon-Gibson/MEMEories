%% Create Memes
function mememaker(~,~)
off = 20;
yoffset = off;
xoffset = 20;
figure('Name','Choose meme format','NumberTitle','off')
set(gcf,'Position',[400 100 340 320]);

memes = getMemes();

% Create meme buttons
ehrmagerd = uicontrol('Style', 'checkbox', 'String', 'ERMAHGERDify',...
    'Position', [xoffset yoffset 150 20]);
yoffset = yoffset + off * 2;

numpercol = floor(height(memes)/2);
for i = 1:numpercol
    uicontrol('Style', 'pushbutton', 'String', memes.label(i),...
        'Position', [xoffset yoffset 150 20],...
        'Callback', {@creatememe,false,ehrmagerd,memes.id(i)});
    yoffset = yoffset + off;
end

% Second column
yoffset = off;
xoffset = xoffset + 150;

uicontrol('Style', 'pushbutton', 'String', 'Random Format',...
    'Position', [xoffset yoffset 150 20],...
    'Callback', {@creatememe,false,ehrmagerd,"0"});
yoffset = yoffset + 2*off;

for i = numpercol + (1:numpercol)
    uicontrol('Style', 'pushbutton', 'String', memes.label(i),...
        'Position', [xoffset yoffset 150 20],...
        'Callback', {@creatememe,false,ehrmagerd,memes.id(i)});
    yoffset = yoffset + off;
end

end

function memes = getMemes()
memes = [
    {"Mocking Spongebob", "102156234"}
    {"That'd Be Great", "563423"}
    {"Doge", "8072285"}
    {"Sippin' Tea", "42784038"}
    {"Dark Kermit", "84341851"}
    {"Push it Somewhere Else", "61581"}
    {"Taking Exit", "124822590"}
    {"Steve Harvey", "143601"}
    {"Spongebob Imagination", "163573"}
    {"See, Nobody Cares", "6531067"}
    {"Arthur Fist", "74191766"}
    {"First World Problems", "61539"}
    {"Caveman Spongebob", "68690826"}
    {"Overly Attached Girlfriend", "100952"}
    {"Hit The Button", "119139145"}
    {"Confused Math Lady", "92828380"}
    {"Blinking White Guy", "96572077"}
    {"Hide The Pain Harold", "27813981"}
    {"Spongebob Um Actually", "326093"}
    {"Buzz Lightyear", "347390"}
    {"Joseph Ducreux", "61535"}
    {"It's OK", "5471748"}
    {"Fire Cows", "107043"}
    {"Bill Nye", "1006090"}
];
memes = cell2table(memes, 'VariableNames', {'label','id'});
end

function creatememe(~,~,shuffly,ehrmagerdify,id)
warning ('off','all');
% Display original blank meme
figure;
set(gcf,'Position',[100 100 500 500]);

if strcmp(id,"0")
    memes = getMemes();
    ids = memes.id;
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
    top = ERMAHGERD(top);
    bottom = ERMAHGERD(bottom);
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