class_name HelperTools


func __equals_string(str1: String, str2: String) -> bool:
    return str1 == str2

func __equals_one_of_strings(str1: String, str_list: Array) -> bool:
    return str1 in str_list

func split_string(string: String, splitter, splits_count: int=0):
    var res: Array = []
    var curr_substring := ''
    var occurances := 0
    var splitter_length := 1

    var matches := FuncRef.new()
    matches.set_instance(self)

    if typeof(splitter) == TYPE_STRING:
        matches.set_function('__equals_string')
        splitter_length = splitter.length()

    elif typeof(splitter) == TYPE_ARRAY:
        matches.set_function('__equals_one_of_strings')

    for i in range(string.length()):
        if matches.call_func(string.substr(i, splitter_length), splitter):
#			if curr_substring != '':
#				res.append(curr_substring.substr(splitter_length, curr_substring.length() - splitter_length))
#			else:
            res.append(curr_substring)

            curr_substring = ''

            occurances += 1
            if splits_count > 0 and occurances == splits_count:
                res.append(string.substr(i + 1, string.length() - i - 1))
                return res

            continue

        curr_substring += string[i]

    res.append(curr_substring)

    return res