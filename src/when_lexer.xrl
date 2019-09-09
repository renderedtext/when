Definitions.

KEYWORD = branch|BRANCH|tag|TAG|pull_request|PULL_REQUEST|result|RESULT|result_reason|RESULT_REASON
OPERATOR = =|!=|=~|!~
BOOL_OPERATOR = and|AND|or|OR
WHITESPACE = [\s\t\n\r]
BOOLEAN = true|TRUE|false|FALSE
STRING = '[^\']+'

Digit = [0-9]
NonZeroDigit = [1-9]
NegativeSign = [\-]
Sign = [\+\-]
FractionalPart = \.{Digit}+
IntegerPart = {NegativeSign}?0|{NegativeSign}?{NonZeroDigit}{Digit}*

INTEGER = {IntegerPart}
FLOAT = {IntegerPart}{FractionalPart}

IDENTIFIER = [a-zA-Z][a-zA-Z0-9_\-]*

Rules.

{OPERATOR}      : {token, {operator,  TokenLine, list_to_binary(TokenChars)}}.
{BOOL_OPERATOR} : {token, {bool_operator,  TokenLine, to_lowercase_binary(TokenChars)}}.
\(              : {token, {'(',  TokenLine}}.
\)              : {token, {')',  TokenLine}}.
,               : {token, {',',  TokenLine}}.
{KEYWORD}       : {token, {keyword,  TokenLine, to_lowercase_binary(TokenChars)}}.
{BOOLEAN}       : {token, {boolean,  TokenLine, to_lowercase_binary(TokenChars)}}.
{STRING}        : {token, {string, TokenLine, extract_string(TokenChars)}}.
{INTEGER}       : {token, {integer, TokenLine, list_to_integer(TokenChars)}}.
{FLOAT}         : {token, {float, TokenLine, list_to_float(TokenChars)}}.
{IDENTIFIER}    : {token, {identifier, TokenLine, to_atom(TokenChars)}}.
{WHITESPACE}+   : skip_token.

Erlang code.

extract_string(Chars) ->
    list_to_binary(lists:sublist(Chars, 2, length(Chars) - 2)).

to_lowercase_binary(Chars) ->
    string:lowercase(list_to_binary(Chars)).

to_boolean(Chars) ->
    erlang:binary_to_existing_atom(string:lowercase(list_to_binary(Chars)), utf8).

to_atom(Chars) ->
    erlang:binary_to_atom(list_to_binary(Chars), utf8).
