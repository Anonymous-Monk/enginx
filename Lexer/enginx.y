%{
  #include <stdio.h>
  #include "enginx_dev.h"
  #define YYDEBUG 1
  int enginxlex();
  void enginxerror(const char *s);
%}

%union {
  ENGINX_VALUE            *argument;
  ENGINX_LOCATION         *locations_list;
  ENGINX_SERVER           *server_list;
  ENGINX_STATEMENT        *statement;
  ENGINX_STATEMENT_LIST   *statement_list;
  ENGINX_IF_STATMENT      *if_statement;
  ENGINX_ARGUMENT_LIST    *argument_list;
  ENGINX_EXPRESSION       *expression;
  ENGINX_BLOCK            *block;
}
%token <argument> STRING_LITERAL IDENTIFIER NULL_VALUE
%token SERVER DOMAIN PORT LOCATION LP RP LC RC
SEMICOLON COLON IF ENCODE DECODE RETURN MATCH PARSE DEFINE
GREATER EQUAL SMALLER SCHEME
%type <argument_list> argument_list
%type <expression> expression encode_expression decode_expression return_expression 
match_expression parse_expression define_expression compare_expression
%type <statement> statement if_statement
%type <statement_list> statement_list
%type <block> block;
%type <server_list> server_list server
%type <locations_list> location_list location

%%
server_list
: server
| server_list server
{
  ENGINX_INTERPRETER* inter = enginx_get_current_interpreter();
  inter->server_list = enginx_chain_server($1, $2);
}
;
server
: SERVER LC DOMAIN COLON STRING_LITERAL SEMICOLON SCHEME COLON STRING_LITERAL SEMICOLON PORT COLON STRING_LITERAL SEMICOLON location_list RC
{
  $$ = enginx_create_server($5, $9, enginx_value_to_integer($13), $15);
}
;

location_list
: location
| location_list location
{
  $$ = enginx_chain_location($1, $2);
}
;
location
: LOCATION STRING_LITERAL LC statement_list RC
{
  $$ = enginx_create_location($2, $4);
}
;
statement_list
: statement
{
  $$ = enginx_create_statement_list($1);
}
| statement_list statement
{
  $$ = enginx_chain_statement_list($1, $2);
}
statement
: expression SEMICOLON
{
  $$ = enginx_create_normal_statement($1);
}
| if_statement
;
if_statement
: IF LP compare_expression RP block
{
  $$ = enginx_create_if_statement($3, $5);
}
;
expression
: compare_expression
| encode_expression
| decode_expression
| return_expression
| match_expression
| parse_expression
| define_expression
;
compare_expression
: GREATER argument_list
{
  $$ = enginx_create_expression(GREATER_EXPRESSION, $2);
}
| SMALLER argument_list
{
  $$ = enginx_create_expression(SMALLER_EXPRESSION, $2);
}
| EQUAL argument_list
{
  $$ = enginx_create_expression(EQUAL_EXPRESSION, $2);
}
;
encode_expression
: ENCODE IDENTIFIER
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  $$ = enginx_create_expression(ENCODE_EXPRESSION, list);
}
;
decode_expression
: DECODE IDENTIFIER
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  $$ = enginx_create_expression(DECODE_EXPRESSION, list);
}
;
return_expression
: RETURN STRING_LITERAL
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  $$ = enginx_create_expression(RETURN_EXPRESSION, list);
}
;
match_expression
: MATCH IDENTIFIER STRING_LITERAL
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  list = enginx_chain_argument_list(list, $3);
  $$ = enginx_create_expression(MATCH_EXPRESSION, list);
}
;
parse_expression
: PARSE IDENTIFIER
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  $$ = enginx_create_expression(PARSE_EXPRESSION, list);
}
;
define_expression
: DEFINE IDENTIFIER STRING_LITERAL
{
  ENGINX_ARGUMENT_LIST* list = enginx_create_argument_list($2);
  list = enginx_chain_argument_list(list, $3);
  $$ = enginx_create_expression(DEFINE_EXPRESSION, list);
}
;
argument_list
: STRING_LITERAL
{
  $$ = enginx_create_argument_list($1);
}
| IDENTIFIER 
{
  $$ = enginx_create_argument_list($1);
}
| NULL_VALUE
{
  $$ = enginx_create_argument_list($1);
}
| argument_list STRING_LITERAL
{
  $$ = enginx_chain_argument_list($1, $2);
}
| argument_list IDENTIFIER
{
  $$ = enginx_chain_argument_list($1, $2);
}
| argument_list NULL_VALUE
{
  $$ = enginx_chain_argument_list($1, $2);
}
;
block
:LC statement_list RC
{
  $$ = enginx_create_block($2);
}
| LC RC
{
  $$ = enginx_create_block(NULL);
}
;
%%
