% ermagerd feature
function result = ERMAHGERD(string)
if ~exist('string','var')
    answer = inputdlg('Enter string to convert: ','s');
    string = answer{1};
end

if ~isstr(string)
    string = convertStringsToChars(string);
end

inter = '';
for i = 1:(strlength(string))
    character = string(i);
    
    if i < strlength(string) && is_vowel(character)
        % multiple vowels in a row
        if is_vowel(string(i+1))
            continue
        % single vowel
        elseif is_silent_e(string, i)
            inter = [inter, 'E'];
        else
            inter = [inter, 'ER'];
        end
    elseif strcmpi(character, 'y')
        if is_first_letter_of_word(string, i)
            inter = [inter, 'Y'];
        else
            inter = [inter, 'A'];
        end
    else
        inter = [inter, character];
    end
end
result = upper(inter);
end

function result = is_silent_e(string, index)
    result = (index > 1) && ...
             ~is_vowel(string(index - 1)) && ...
             (strcmpi(string(index), 'e'));
end

function result = is_first_letter_of_word(string, index)
    result = (index == 1) || strcmpi(string(index - 1), ' ');
end

function result = is_vowel(i)
result = strcmpi(i, 'a') || strcmpi(i, 'e') || ...
    strcmpi(i, 'i') || strcmpi(i, 'o') || strcmpi(i, 'u');
end