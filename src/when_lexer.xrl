Definitions.

KEYWORD = branch|BRANCH|tag|TAG|result|RESULT|result_reason|RESULT_REASON
OPERATOR = =|!=|=~|!~
BOOL_OPERATOR = and|AND|or|OR
BOOLEAN = true|TRUE|false|FALSE
WHITESPACE = [\s\t\n\r]

Rules.

{OPERATOR}      : {token, {operator,  TokenLine, list_to_binary(TokenChars)}}.
{BOOL_OPERATOR} : {token, {bool_operator,  TokenLine, to_lowercase_binary(TokenChars)}}.
\(              : {token, {'(',  TokenLine}}.
\)              : {token, {')',  TokenLine}}.
{KEYWORD}       : {token, {keyword,  TokenLine, to_lowercase_binary(TokenChars)}}.
{BOOLEAN}       : {token, {boolean,  TokenLine, to_lowercase_binary(TokenChars)}}.
'[^\']+'        : {token, {string, TokenLine, extract_string(TokenChars)}}.
{WHITESPACE}+   : skip_token.

Erlang code.

extract_string(Chars) ->
    list_to_binary(lists:sublist(Chars, 2, length(Chars) - 2)).

to_lowercase_binary(Chars) ->
    string:lowercase(list_to_binary(Chars)).
