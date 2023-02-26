%option noyywrap
%x COMMENT
%x DEF 
%x DEF_IDENT 
%x UNDEF 
%x IFDEF
%x ELSE
%x ELIF
%x ELIF2
%x ENDIF
%x SKIP_IFDEF
%x SKIP_ELSE
%x SKIP_ELIF

%{
#include "parser.hh"
#include <string>
#include <map>
#include <stack>
 
extern int yyerror(std::string msg);
std::map<std::string, std::string> macros;
std::stack<int> multiline_comment_stack;
std::stack<int> ifdef_stack;
 
inline void push_multiline_comment(int state) {
    multiline_comment_stack.push(state);
}
inline void pop_multiline_comment() {
    multiline_comment_stack.pop();
}
inline bool in_multiline_comment() {
    return !multiline_comment_stack.empty();
}
 
inline void push_ifdef(int state) {
    ifdef_stack.push(state);
}
inline void pop_ifdef() {
    ifdef_stack.pop();
}
 
%}

%%

"?"       { return TQUES;}
":"       { return TCOLON;}

"+"       { return TPLUS; }
"-"       { return TDASH; }
"*"       { return TSTAR; }
"/"       { return TSLASH; }
";"       { return TSCOL; }
"("       { return TLPAREN; }
")"       { return TRPAREN; }
"="       { return TEQUAL; }
"dbg"     { return TDBG; }
"let"     { return TLET; }
[0-9]+    { yylval.lexeme = std::string(yytext); return TINT_LIT; }
[0-9a-zA-Z]+ { if(macros.find(yytext)!=macros.end()){std::string val = macros[yytext];for(int i=val.size()-1;i>=0;i--)unput(val[i]);}else{yylval.lexeme = std::string(yytext); return TIDENT; }}
[ \t\n]   { /* skip */ }
 
"//".* { /* skip */ }
 
"/*" { push_multiline_comment(yylineno); BEGIN COMMENT; }
<COMMENT>"*/" { pop_multiline_comment(); BEGIN INITIAL; }
<COMMENT>. { /* skip */ }
 
"#def" { BEGIN DEF; }
<DEF>[0-9a-zA-Z]+ { yylval.lexeme = std::string(yytext); BEGIN DEF_IDENT; }
<DEF_IDENT>.*\n {
    macros[yylval.lexeme] = std::string(yytext);
    BEGIN INITIAL;
}
 
"#undef" { BEGIN UNDEF; }
<UNDEF>[0-9a-zA-Z]+ {
    if (macros.count(std::string(yytext)) > 0) {
        macros.erase(std::string(yytext));
    }
    BEGIN INITIAL;
}
 
"#endif" { BEGIN ENDIF; }
<ENDIF>.* {
    pop_ifdef(); 
    BEGIN INITIAL;
}
 
"#else" { BEGIN SKIP_ELSE; }
<SKIP_ELSE>"#endif" {
    BEGIN INITIAL;
}
<SKIP_ELSE>. { }
 
"#ifdef" { BEGIN IFDEF; }
<IFDEF>[0-9a-zA-Z]+ {
    if(macros.find(std::string(yytext)) != macros.end()) {
        push_ifdef(yylineno); 
        BEGIN INITIAL;
    } else {
        BEGIN SKIP_IFDEF;
    }
}
<SKIP_IFDEF>"#elif" { BEGIN ELIF; }
<ELIF>[0-9a-zA-Z]+ {
    if(macros.find(std::string(yytext)) != macros.end()) {
        push_ifdef(yylineno);
        BEGIN INITIAL;
    } else {
        BEGIN SKIP_IFDEF;
    }
}
<SKIP_IFDEF>"#endif" {
    pop_ifdef(); 
    BEGIN INITIAL;
}
<SKIP_IFDEF>"#else" { 
    push_ifdef(yylineno); 
    BEGIN INITIAL; 
}
<SKIP_IFDEF>. { /* skip */ }
 
"#elif" { BEGIN ELIF2; }
<ELIF2>[0-9a-zA-Z]+  {
    BEGIN SKIP_ELIF;
}
<SKIP_ELIF>"#endif" {
    pop_ifdef(); 
    BEGIN INITIAL;
}
<SKIP_ELIF>. { /* skip */ }
 
 
. { yyerror("unkown char"); }
 
%%
 
std::string token_to_string(int token, const char *lexeme) {
    std::string s;
    switch (token) {
        case TPLUS: s = "TPLUS"; break;
        case TDASH: s = "TDASH"; break;
        case TSTAR: s = "TSTAR"; break;
        case TSLASH: s = "TSLASH"; break;
        case TSCOL: s = "TSCOL"; break;
        case TLPAREN: s = "TLPAREN"; break;
        case TRPAREN: s = "TRPAREN"; break;
        case TEQUAL: s = "TEQUAL"; break;
        
        case TDBG: s = "TDBG"; break;
        case TLET: s = "TLET"; break;
        
        case TINT_LIT: s = "TINT_LIT"; s.append("  ").append(lexeme); break;
        case TIDENT: s = "TIDENT"; s.append("  ").append(lexeme); break;

        case TQUES: s = "TQUES"; break;
        case TCOLON: s = "TCOLON"; break;
    }
 
    return s;
}