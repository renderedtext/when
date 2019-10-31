Nonterminals expression term basic_val list params fun.

Terminals operator bool_operator '(' ')' '[' ']' keyword string boolean integer float identifier ','.

Rootsymbol expression.

expression -> expression bool_operator term : {extract_token('$2'), '$1', '$3'}.
expression -> term : '$1'.

term -> '(' expression ')'        : '$2'.
term -> keyword operator string   : {extract_token('$2'), {'keyword', extract_token('$1')}, extract_token('$3')}.
term -> string operator keyword   : {extract_token('$2'), extract_token('$1'), {'keyword', extract_token('$3')}}.
term -> basic_val                 : '$1'.
term -> fun                       : '$1'.
term -> fun operator term         : {extract_token('$2'), '$1', '$3'}.

basic_val -> string               : extract_token('$1').
basic_val -> boolean              : extract_token('$1').
basic_val -> integer              : extract_token('$1').
basic_val -> float                : extract_token('$1').
basic_val -> list                 : '$1'.

list -> '[' ']'                   : [].
list -> '[' params ']'            : '$2'.

fun -> identifier '(' ')'         : {'fun', extract_token('$1'), []}.
fun -> identifier '(' params ')'  : {'fun', extract_token('$1'), '$3'}.

params -> basic_val               : ['$1'].
params -> basic_val ',' params    : ['$1'] ++ '$3'.

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
