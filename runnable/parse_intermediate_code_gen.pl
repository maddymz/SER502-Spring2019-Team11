compileBumpy(FileName) :- open(FileName, read, InStream),
		   tokenCodes(InStream, TokenCodes),
		   phrase(lexer(Tokens),TokenCodes),
		   parser(ParseTree, Tokens, []),
		   close(InStream),
		   split_string(FileName, ".", "", L),
		   L = [H|_T],
		   atom_concat(H, ".bmic", X),
		   open(X, write, OutStream),
		   write(OutStream, ParseTree),
		   write(OutStream, '.'),
close(OutStream).


tokenCodes(InStream,[]) :- at_end_of_stream(InStream), !.
tokenCodes(InStream, [TokenCode | RemTokens]) :- get_code(InStream, TokenCode),
                                                 tokenCodes(InStream, RemTokens).


%===========================================================================================

lexer(Tokens) -->
    white_space,
    (   ( ";",  !, { Token = ; };  
        "@",  !, { Token = @ };  
        "start",  !, { Token = start };
        "stop",  !, { Token = stop };
        "when",  !, { Token = when };
        "repeat",  !, { Token = repeat };
        "endrepeat",  !, { Token = endrepeat };
        "incase",  !, { Token = incase };
        "do",  !, { Token = do };
        "otherwise",  !, { Token = otherwise };  
        "endcase",  !, { Token = endcase };
        "yes",  !, { Token = yes };
        "no",  !, { Token = no };
        "and",  !, { Token = and };
        "or",  !, { Token = or };
        "var",  !, { Token = var };
        "bool",  !, { Token = bool };
        ">",  !, { Token = > };
        "<",  !, { Token = < };
        "<=", !, { Token = <= };
        ">=", !, { Token = >= };
        "=",  !, { Token = =  };
        "is",  !, { Token = is  };
        ":=:",  !, { Token = :=:  };
        "show", !, {Token = show};
        "~=", !, { Token = ~= };
        "+",  !, { Token = +  };
        "-",  !, { Token = -  };
        "*",  !, { Token = *  };
        "/", !, { Token = /  };
        "mod", !, { Token = mod  };  
        digit(D),  !, number(D, N), { Token = N };
        lowletter(L), !, identifier(L, Id),{  Token = Id};
        upletter(L), !, identifier(L, Id), { Token = Id };
        [Un], { Token = tkUnknown, throw((unrecognized_token, Un)) }),!,
        { Tokens = [Token | TokList] },lexer(TokList);  
    	  [],{ Tokens = [] }).

white_space --> [Char], { code_type(Char,space) }, !, white_space.
white_space --> [].

digit(D) --> [D],{ code_type(D, digit) }.
digits([D|T]) --> digit(D),!,digits(T).
digits([]) -->[].

number(D, N) --> digits(Ds),{ number_chars(N, [D|Ds]) }.

upletter(L) -->[L], { code_type(L, upper) }.

lowletter(L) -->[L], { code_type(L, lower) }.

alphanum([A|T]) -->[A], { code_type(A, csym) }, !, alphanum(T).
alphanum([]) -->[].

identifier(L, Id) -->alphanum(As),{ atom_codes(Id, [L|As]) }.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parser(X) --> program(X).

program(t_program(X,Y)) -->comment(X),block(Y).
program(t_program(X)) -->block(X).

comment(t_comment(Y)) --> [@],words(Y),[@].

words(t_words(X,Y)) --> identifier(X), words(Y) ; numb(X), words(Y).
words(t_words(X)) -->identifier(X); numb(X).

block(t_block(X,Y)) --> [start], declaration(X), process(Y), [stop].

datatype(t_datatype(var)) --> [var].
datatype(t_datatype(bool)) --> [bool].

declaration(t_declare(X,Y,Z)) --> datatype(X), identifier(Y), [;], declaration(Z).    
declaration(t_declare(X,Y)) -->datatype(X),identifier(Y),[;].

process(t_process(X,Y)) --> assignvalue(X), [;], process(Y); control(X), process(Y); iterate(X), process(Y); print(X), process(Y).
process(t_process(X)) -->assignvalue(X),[;] ;control(X) ;iterate(X);print(X).

print(t_print(X)) --> [show],expression(X),[;].
% print(t_print(X)) --> [show], ["], words(X), ["],[;].


assignvalue(t_assign(X,Y)) --> identifier(X), [=] ,expression(Y); identifier(X), [is], boolexp(Y).

control(t_control(X,Y,Z)) --> [incase], condition(X), [do], process(Y), [otherwise], process(Z), [endcase].

iterate(t_iterate(X,Y)) --> [when], condition(X), [repeat], process(Y), [endrepeat].

condition(t_cond_and(X,Y)) --> boolexp(X), [and], boolexp(Y).
condition(t_cond_or(X,Y)) --> boolexp(X), [or], boolexp(Y).
condition(t_cond_not(X)) --> [~], boolexp(X).
condition(t_cond(X)) --> boolexp(X).

boolexp(t_boolexp_eq(X,Y)) --> expression(X), [:=:], expression(Y).
boolexp(t_boolexp_neq(X,Y)) --> expression(X), [~=], expression(Y). 
boolexp(t_boolexp_leq(X,Y)) --> expression(X), [<=], expression(Y).
boolexp(t_boolexp_geq(X,Y)) --> expression(X), [>=], expression(Y).
boolexp(t_boolexp_less(X,Y)) --> expression(X), [<], expression(Y).
boolexp(t_boolexp_great(X,Y)) --> expression(X), [>], expression(Y).
boolexp(t_boolexp_beq(X,Y)) --> expression(X), [:=:], boolexp(Y).
boolexp(t_boolexp_bneq(X,Y)) --> expression(X), [~=], boolexp(Y). 
boolexp(t_boolexp(yes)) --> [yes].
boolexp(t_boolexp(no)) --> [no].

expression(t_add(X,Y)) --> term(X),[+],expression(Y).
expression(t_sub(X,Y)) --> term(X),[-],expression(Y).
expression(t_expr(X)) --> term(X).

term(t_mul(X,Y)) --> identifier(X),[*],term(Y);numb(X),[*],term(Y);numbneg(X),[*],term(Y).
term(t_div(X,Y)) -->identifier(X),[/],term(Y);numb(X),[/],term(Y);numbneg(X),[/],term(Y).
term(t_mod(X,Y)) -->identifier(X),[mod],term(Y);numb(X),[mod],term(Y);numbneg(X),[mod],term(Y).
term(t_term(X)) -->identifier(X);numb(X);numbneg(X).

identifier(t_identifier(X)) -->[X], 
    {string_chars(X,[H|T])}, 
    {(is_alpha(H); X = '_')},
    {forall(member(C,T),
    (is_alnum(C)); C = '_')}.

numbneg(t_numbneg(X)) --> [-],numb(X).
numb(t_numb(X)) --> [X],{number(X)}.
