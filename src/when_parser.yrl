Nonterminals expression term.

Terminals operator bool_operator '(' ')' keyword string boolean.

Rootsymbol expression.

expression -> expression bool_operator term : {extract_token('$2'), '$1', '$3'}.
expression -> term : '$1'.

term -> '(' expression ')'        : '$2'.
term -> keyword operator string   : {extract_token('$2'), {'keyword', extract_token('$1')}, extract_token('$3')}.
term -> string operator keyword   : {extract_token('$2'), extract_token('$1'), {'keyword', extract_token('$3')}}.

term -> string                    : extract_token('$1').
term -> boolean                   : extract_token('$1').

Erlang code.

extract_token({_Token, _Line, Value}) -> Value.
