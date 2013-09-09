open Core.Std

(*********** Definition ***********)

type identifier = string

type expression =
  | Bool of bool
  | Float of float
  | Int of int
  | List of expression list
  | String of string
  | Identifier of identifier
  | Plus of (expression * expression)
  | Minus of (expression * expression)
  | Multiply of (expression * expression)
  | Divide of (expression * expression)
  | Modulo of (expression * expression)
  | Concat of (expression * expression)
  | Equal of (expression * expression)
  | NotEqual of (expression * expression)
  | Greater of (expression * expression)
  | Less of (expression * expression)
  | GreaterEqual of (expression * expression)
  | LessEqual of (expression * expression)
  | Parentheses of expression
  | Call of (identifier * expression list)

type statement = 
  | Block of (statements)
  | Expression of (expression)
  | Assignment of (identifier * expression)
  | If of (expression * statement)
  | IfElse of (expression * statement * statement)
  | Empty

and statements = statement list

(*********** Output ***********)

let rec print_expression out (expr: expression) =
  match expr with
  | Identifier identifier -> output_string out identifier
  | Int number -> output_string out (string_of_int number)
  | Float number -> output_string out (Float.to_string number)
  | String str -> output_string out (sprintf "\"%s\"" str)
  | Bool true  -> output_string out "true"
  | Bool false -> output_string out "false"
  | Plus _ | Minus _ | Multiply _ | Divide _  | Modulo _ | Concat _
  | Equal _ | NotEqual _ | Greater _ | Less _ | GreaterEqual _ | LessEqual _ ->
      print_binary_expression out expr
  | Parentheses expr ->
      fprintf out "(%a)" print_expression expr
  | Call (ident, exprs) ->
      fprintf out "%s(%a)" ident print_expressions exprs
  | List _ -> ()

and print_expressions out (exprs: expression list) =
  let num_exprs = List.length exprs in
  List.iteri exprs ~f: (fun i expr ->
    print_expression out expr;
    if i <> num_exprs - 1 then
      output_string out ", "
  )

and print_binary_expression out (expr: expression) =
  let print_binary operator left right =
    fprintf out "%a %s %a"
      print_expression left operator print_expression right
  in
  match expr with
  | Plus (left, right) ->
      print_binary "+" left right
  | Minus (left, right) ->
      print_binary "-" left right
  | Multiply (left, right) ->
      print_binary "*" left right
  | Divide (left, right) ->
      print_binary "/" left right
  | Modulo (left, right) ->
      print_binary "%" left right
  | Concat (left, right) ->
      print_binary "++" left right
  | Equal (left, right) ->
      print_binary "==" left right
  | NotEqual (left, right) ->
      print_binary "!=" left right
  | Greater (left, right) ->
      print_binary ">" left right
  | Less (left, right) ->
      print_binary "<" left right
  | GreaterEqual (left, right) ->
      print_binary ">=" left right
  | LessEqual (left, right) ->
      print_binary "<=" left right
  | _ -> assert false

let print_indent out (indent: int) =
  output_string out (String.make indent ' ')

let rec print_statement out (stmt: statement) ~(indent: int) =
  match stmt with
  | Block inner_stmts -> print_block_statement ~indent out inner_stmts
  | Expression expr ->
      print_expression out expr;
      output_string out ";"
  | Assignment (ident, expr) ->
      fprintf out "%s = %a;" ident print_expression expr
  | If (expr, stmt) ->
      print_if_statement out expr stmt ~indent
  | IfElse (expr, thenStmt, elseStmt) ->
      print_if_else_statement out expr thenStmt elseStmt ~indent
  | Empty -> ()

and print_statements out (stmts: statements) ~(indent: int) =
  let print_statement_indented = print_statement ~indent in
  List.iter stmts ~f: (fun stmt ->
    fprintf out "%a%a\n" print_indent indent print_statement_indented stmt
  )

and print_block_statement out (inner_stmts: statements) ~(indent: int) =
  let print_statements_indented = print_statements ~indent:(indent + 2) in
  fprintf out "{\n%a%a}"
      print_statements_indented inner_stmts print_indent indent

and print_if_statement
    out (expr: expression) (stmt: statement) ~(indent: int) =
  fprintf out "if (%a) " print_expression expr;
  print_statement out stmt ~indent

and print_if_else_statement
    (out: out_channel)
    (expr: expression)
    (thenStmt: statement)
    (elseStmt: statement)
    ~(indent: int) =
  print_if_statement out expr thenStmt ~indent;
  output_string out " else ";
  print_statement out elseStmt ~indent

let print_ast out (stmts: statements) =
  print_statements out stmts ~indent: 0
