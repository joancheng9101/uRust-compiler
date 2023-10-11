/* Please feel free to modify any content */

/* Definition section */
%{
    #include "compiler_common.h" //Extern variables that communicate with lex
    #define YYDEBUG 1
    int yydebug = 1;

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    int yylex_destroy ();
    void yyerror (char const *s)
    {
        printf("error:%d: %s\n", yylineno+1, s);
    }

    extern int yylineno;
    extern int yylex();
    extern FILE *yyin;

    /* Used to generate code */
    /* As printf; the usage: CODEGEN("%d - %s\n", 100, "Hello world"); */
    /* We do not enforce the use of this macro */
    #define CODEGEN(...) \
        do { \
            for (int i = 0; i < g_indent_cnt; i++) { \
                fprintf(fout, "\t"); \
            } \
            fprintf(fout, __VA_ARGS__); \
        } while (0)


    /* Symbol table function - you can add new functions if needed. */
    /* parameters and return type can be changed */
    static void create_symbol();
    static void insert_symbol(int a, int b);
    static char * lookup_symbol(char * name, int n);
    static void dump_symbol();

    /* Global variables */
    bool g_has_error = false;
    FILE *fout = NULL;
    int g_indent_cnt = 0;
    typedef struct table_t table_t;
    struct table_t {
        int index_table;
        char *name_table;
        int mut_table;
        char *type_table;
        int addr_table;
        int lineno_table;
        char *func_sig_table;
        int print_table;
        int arr_size_table;
    };
    typedef struct mulfun_t mulfun_t;
    struct mulfun_t {
        char *name_mulfun;
        char *type_mulfun;
    };
    table_t table_arr[500][500];
    mulfun_t mulfun_arr[20];
    int addr_arr[500];
    int print_r_table[500];
    int mulfun_size;
    int stack_pointer = -1;
    int scope_level = 0;
    int now_add = 0;
    char *op_temp;
    char *fun_name;
    int do_create;
    bool HAS_ERROR = false;
    char temp_r;
    int Com_num = 0;
    int ta;
    int ts;
    int stack_c[50];
    int stack_c_p = -1;
    int bbb=0;

%}

%error-verbose

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 *  - you can add new fields if needed.
 */
%union {
    int i_val;
    float f_val;
    char *s_val;
    /* ... */
}

/* Token without return */
%token LET MUT NEWLINE
%token INT FLOAT BOOL STR
%token TRUE FALSE
%token GEQ LEQ EQL NEQ LOR LAND
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN REM_ASSIGN
%token IF ELSE FOR WHILE LOOP
%token PRINT PRINTLN
%token FUNC RETURN BREAK
%token ARROW AS IN DOTDOT RSHIFT LSHIFT

/* Token with return, which need to sepcify type */
%token <i_val> INT_LIT
%token <s_val> STRING_LIT
%token <f_val> FLOAT_LIT
%token <s_val> ID

/* Nonterminal with return, which need to sepcify type */
%type <s_val> Type
%type <s_val> FindFuncSig
%type <s_val> Expression
%type <s_val> OtherExpr
%type <s_val> Literal
%type <s_val> ChangeType
%type <s_val> TermAdd
%type <s_val> TermMUL
%type <s_val> AddOP
%type <s_val> MULOP
%type <s_val> UOP
%type <s_val> TermCOM
%type <s_val> ComOP
%type <s_val> LorLand
%type <s_val> AssOP
%type <s_val> Parameter
%type <s_val> TermUOP
%type <s_val> MUOP
%type <s_val> TermShift
%type <s_val> ShiftOP
%type <s_val> SID
/* Yacc will start at this nonterminal */
%start Program

/* Grammar section */
%%

Program
    : GlobalStatementList
;

GlobalStatementList 
    : GlobalStatementList GlobalStatement
    | GlobalStatement
;

GlobalStatement
    : FunctionDeclStmt
    | NEWLINE
;

FunctionDeclStmt
    :  ToInsert '{' LocalStatementList RBRACE
;


ToInsert
    : FUNC ID  '(' Parameter ')'  FindFuncSig  { 
                            now_add = 0;
                            char *temp;
                            asprintf(&temp, "(%s)%s", $4, $6);
                            printf("func: %s\n", $2);

                            int t;
                            t = addr_arr[scope_level-1];
                            table_arr[scope_level-1][t].index_table = t;
                            table_arr[scope_level-1][t].name_table = $2;
                            table_arr[scope_level-1][t].mut_table = -1;
                            table_arr[scope_level-1][t].type_table = "func";
                            table_arr[scope_level-1][t].addr_table = -1;
                            table_arr[scope_level-1][t].lineno_table = yylineno+1;
                            table_arr[scope_level-1][t].func_sig_table = temp;
                            table_arr[scope_level-1][t].print_table = 1;
                            print_r_table[scope_level-1] = 1;
                            addr_arr[scope_level-1] ++;
                            insert_symbol(scope_level-1,t);

                            int t2;
                            t2 = addr_arr[scope_level];
                            table_arr[scope_level][t2].print_table = 0;
                            scope_level ++;
                            stack_pointer ++ ;
                            create_symbol();
                            
                            for(int i= 0; i < mulfun_size; i++){
                                int t3;
                                t3 = addr_arr[scope_level-1];
                                table_arr[scope_level-1][t3].index_table = t3;
                                table_arr[scope_level-1][t3].name_table = mulfun_arr[i].name_mulfun;
                                table_arr[scope_level-1][t3].mut_table = 0;
                                table_arr[scope_level-1][t3].type_table = mulfun_arr[i].type_mulfun;
                                table_arr[scope_level-1][t3].addr_table = now_add;
                                table_arr[scope_level-1][t3].lineno_table = yylineno+1;
                                table_arr[scope_level-1][t3].func_sig_table = "-";
                                table_arr[scope_level-1][t3].print_table = 1;
                                print_r_table[scope_level-1] = 1;
                                addr_arr[scope_level-1] ++;
                                now_add ++;
                                insert_symbol(scope_level-1,t3);
                            }
                            mulfun_size = 0;
                                                                     }
    | FUNC ID  '(' ')'  FindFuncSig  { 
                            now_add = 0;
                            char *temp;
                            asprintf(&temp, "(%s)%s", $5, $5);
                            printf("func: %s\n", $2);
                            int t;
                            t = addr_arr[scope_level-1];
                            table_arr[scope_level-1][t].index_table = t;
                            table_arr[scope_level-1][t].name_table = $2;
                            table_arr[scope_level-1][t].mut_table = -1;
                            table_arr[scope_level-1][t].type_table = "func";
                            table_arr[scope_level-1][t].addr_table = -1;
                            table_arr[scope_level-1][t].lineno_table = yylineno+1;
                            table_arr[scope_level-1][t].func_sig_table = temp;
                            table_arr[scope_level-1][t].print_table = 1;
                            print_r_table[scope_level-1] = 1;
                            addr_arr[scope_level-1] ++;
                            insert_symbol(scope_level-1,t);
                            int t1;
                            t1 = addr_arr[scope_level];
                            table_arr[scope_level][t1].print_table = 0;
                            scope_level ++;
                            stack_pointer ++ ;
                            create_symbol();  
                            // if(strcmp($2,"another_function"))
                            //     bbb = 2;
                                                                }
                                       
;

Parameter
    : ID  ':' Type { 
                    char *temp1;
                    switch($3[0])
                    {
                        case 'i': temp1 = "I"; break;
                        case 'f': temp1 = "F"; break;
                        case 'b': temp1 = "B"; break;
                        case 's': temp1 = "S"; break;
                        default: temp1 = "V"; break;
                    }
                    mulfun_arr[mulfun_size].name_mulfun = $1;
                    mulfun_arr[mulfun_size].type_mulfun = $3;
                    mulfun_size ++ ;
                    $$ = temp1;
                                                             }
    | Parameter ',' ID  ':' Type   {     
                                        char *temp1;
                                        char *temp2;
                                        switch($5[0])
                                        {
                                            case 'i': temp1 = "I"; break;
                                            case 'f': temp1 = "F"; break;
                                            case 'b': temp1 = "B"; break;
                                            case 's': temp1 = "S"; break;
                                            default: temp1 = "V"; break;
                                        }
                                        asprintf(&temp2, "%s%s", $1, temp1);
                                        mulfun_arr[mulfun_size].name_mulfun = $3;
                                        mulfun_arr[mulfun_size].type_mulfun = $5;
                                        mulfun_size ++ ;
                                        $$ = temp2; }
;

MORE
    : IF ID '=' INT_LIT '{' LocalStatementList '}' ID '%' ID EQL INT_LIT {
            CODEGEN("ldc \"not divisible\"\n");
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");}

FindFuncSig
    :  ARROW INT   { $$ = "I"; temp_r = 'i';}
    |  ARROW FLOAT { $$ = "F"; temp_r = 'f';}
    |  ARROW BOOL  { $$ = "B"; temp_r = 'b';}
    |  ARROW STR   { $$ = "S"; temp_r = 's';}
    |              { $$ = "V"; temp_r = 'v';}
;

LBRACE
    : '{'   { 
            int t;
            t = addr_arr[scope_level];
            table_arr[scope_level][t].print_table = 0;
            print_r_table[scope_level] = 1;
            scope_level ++;
            stack_pointer ++ ;
            create_symbol();
                            }
;

LocalStatementList
    : LocalStatementList Statement
    | 
;

Statement
    : PRINTLN '(' Expression ')' ';'  { 
        if(bbb==1){
            CODEGEN("ldc \"Hello World\"\n");
             CODEGEN("astore 5\n");
            CODEGEN("aload 5\n"); 
            CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
            CODEGEN("swap\n");
            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
            bbb=0;
        }else{
        //printf("PRINTLN %s\n", $3); 
        switch($3[0]){
                case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                          break;
                case 'f': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
                          break;
                case 'i': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n"); 
                          break;
                case 's': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                          break;
                default:  break;
        }
        }

        //  if(bbb==2){
        //     CODEGEN("ldc \"not divisible\"\n");
        //     CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
        //     CODEGEN("swap\n");
        //     CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
        //     bbb=0;
        // }
    }
    | PRINT '(' Expression ')' ';'  { 
            if(bbb){;}else{
        //printf("PRINT %s\n", $3); 
         switch($3[0]){
                case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/print(Z)V\n"); 
                          break;
                case 'f': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
                          break;
                case 'i': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n"); 
                          break;
                case 's': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                          CODEGEN("swap\n");
                          CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
                          break;
                default:  break;
            }
            }
    }
    | PRINTLN '(' ID '[' INT_LIT ']' ')' ';'  {  
                                                char* mmt;
                                                mmt = lookup_symbol($3,3);
                                                //printf("ta%d",ta);
                                                 switch(mmt[0]){
                                                        // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                        //         CODEGEN("swap\n");
                                                        //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                                        //         break;
                                                        case 'f':
                                                                CODEGEN("fload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        case 'i': 
                                                                CODEGEN("iload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        case 's': 
                                                                CODEGEN("aload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        default:  break;
                                                }
                                                switch(mmt[0]){
                                                    case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                                            break;
                                                    case 'f': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
                                                            break;
                                                    case 'i': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n"); 
                                                            break;
                                                    case 's': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                                                            break;
                                                    default:  break;
                                                } 
                                                                            }
    | PRINT '(' ID '[' INT_LIT ']' ')' ';'  { char* mmt;
                                                mmt = lookup_symbol($3,3);
                                                 switch(mmt[0]){
                                                        // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                        //         CODEGEN("swap\n");
                                                        //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                                        //         break;
                                                        case 'f':
                                                                CODEGEN("fload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        case 'i': 
                                                                CODEGEN("iload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        case 's': 
                                                                CODEGEN("aload %d\n",ta+(ts-$5-1)); 
                                                                break;
                                                        default:  break;
                                                }
                                                switch(mmt[0]){
                                                    case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/print(Z)V\n"); 
                                                            break;
                                                    case 'f': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/print(F)V\n");
                                                            break;
                                                    case 'i': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/print(I)V\n"); 
                                                            break;
                                                    case 's': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                            CODEGEN("swap\n");
                                                            CODEGEN("invokevirtual java/io/PrintStream/print(Ljava/lang/String;)V\n");
                                                            break;
                                                    default:  break;
                                                } 
    
    
     }
    | LET MUT ID '=' Expression ';'{    int t;
                                        t = addr_arr[scope_level-1];
                                         switch($5[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                        CODEGEN("fstore %d\n",now_add);
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                        CODEGEN("istore %d\n",now_add);
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                        CODEGEN("astore %d\n",now_add);
                                                    break;
                                            default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $3;
                                        table_arr[scope_level-1][t].mut_table = 1;
                                        table_arr[scope_level-1][t].type_table = $5;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET MUT ID ':' Type '=' Expression ';'{ int t;
                                        t = addr_arr[scope_level-1];
                                        switch($5[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                        CODEGEN("fstore %d\n",now_add);
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                        CODEGEN("istore %d\n",now_add);
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                        CODEGEN("astore %d\n",now_add);
                                                    break;
                                            default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $3;
                                        table_arr[scope_level-1][t].mut_table = 1;
                                        table_arr[scope_level-1][t].type_table = $5;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET MUT ID ':' Type  ';'{         int t;
                                        t = addr_arr[scope_level-1];
                                         switch($5[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                        CODEGEN("ldc 0.0\n"); 
                                                        CODEGEN("fstore %d\n",now_add);
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                        CODEGEN("ldc 0\n");
                                                        CODEGEN("istore %d\n",now_add);
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                        CODEGEN("ldc ""\n");
                                                        CODEGEN("astore %d\n",now_add);
                                                    break;
                                            default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $3;
                                        table_arr[scope_level-1][t].mut_table = 1;
                                        table_arr[scope_level-1][t].type_table = $5;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET ID ':' Type ';'{              int t;
                                        t = addr_arr[scope_level-1];
                                         switch($4[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                        CODEGEN("fstore %d\n",now_add);
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                        CODEGEN("istore %d\n",now_add);
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                        CODEGEN("astore %d\n",now_add);
                                                    break;
                                            default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $2;
                                        table_arr[scope_level-1][t].mut_table = 0;
                                        table_arr[scope_level-1][t].type_table = $4;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET ID ':' Type '=' Expression ';'{
                                        int t;
                                        t = addr_arr[scope_level-1];
                                        switch($4[0]){
                                                // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                                //         CODEGEN("swap\n");
                                                //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                                //         break;
                                                case 'f'://CODEGEN("ldc %f\n",$2); 
                                                         CODEGEN("fstore %d\n",now_add);
                                                        break;
                                                case 'i': //CODEGEN("ldc %d\n",$2); 
                                                          CODEGEN("istore %d\n",now_add);
                                                        break;
                                                case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                         CODEGEN("astore %d\n",now_add);
                                                        break;
                                                default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $2;
                                        table_arr[scope_level-1][t].mut_table = 0;
                                        table_arr[scope_level-1][t].type_table = $4;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET ID '=' Expression ';'{        int t;
                                        t = addr_arr[scope_level-1];
                                         switch($4[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                        CODEGEN("fstore %d\n",now_add);
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                        CODEGEN("istore %d\n",now_add);
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                        CODEGEN("astore %d\n",now_add);
                                                    break;
                                            default:  break;
                                        }
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $2;
                                        table_arr[scope_level-1][t].mut_table = 0;
                                        table_arr[scope_level-1][t].type_table = $4;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        now_add ++;
                                        insert_symbol(scope_level-1,t);}
    | LET ID ':' '[' Type ';' INT_LIT ']' '=' Expression ';'{ 
                                        int t;
                                        //int mt = now_add;
                                        t = addr_arr[scope_level-1];
                                        table_arr[scope_level-1][t].index_table = t;
                                        table_arr[scope_level-1][t].name_table = $2;
                                        table_arr[scope_level-1][t].mut_table = 0;
                                        table_arr[scope_level-1][t].type_table = $5;
                                        table_arr[scope_level-1][t].addr_table = now_add;
                                        table_arr[scope_level-1][t].lineno_table = yylineno+1;
                                        table_arr[scope_level-1][t].func_sig_table = "-";
                                        table_arr[scope_level-1][t].print_table = 1;
                                        table_arr[scope_level-1][t].arr_size_table = $7;
                                        print_r_table[scope_level-1] = 1;
                                        addr_arr[scope_level-1] ++;
                                        //now_add ++;
                                        insert_symbol(scope_level-1,t);
                                        //lookup_symbol($2,2)
                                        switch($5[0]){
                                            // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                            //         CODEGEN("swap\n");
                                            //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                            //         break;
                                            case 'f'://CODEGEN("ldc %f\n",$2); 
                                                    for(int i=0 ; i<$7; i++){
                                                        CODEGEN("fstore %d\n",now_add);
                                                        now_add ++;
                                                    }
                                                    break;
                                            case 'i': //CODEGEN("ldc %d\n",$2); 
                                                    for(int i=0 ; i<$7; i++){
                                                        CODEGEN("istore %d\n",now_add);
                                                        now_add ++;
                                                    }
                                                    break;
                                            case 's': //CODEGEN("ldc \"%s\"\n",$2); 
                                                    for(int i=0 ; i<$7; i++){
                                                        CODEGEN("astore %d\n",now_add);
                                                        now_add ++;
                                                    }
                                                    break;
                                            default:  break;
                                        }
                                        }
    | SID AssOP Expression { 
                            //char *temp_type;
                            //temp_type = lookup_symbol($1,0);
                            if(strcmp($1, "undefined") != 0 && strcmp($3, "undefined") != 0){
                                if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: ASSIGN (mismatched types %s and %s)", $1, $3);
                                 g_has_error = true;
                                yyerror(temp);
                                }else{
                                    printf("%s\n", $2);
                                    //lookup_symbol($1,1);
                                   // printf("ta%d\n",ta);
                                    if(strcmp($2, "ASSIGN")==0){
                                        if(strcmp($1, "i32") == 0){
                                            CODEGEN("istore %d\n",ta);
                                        }else if(strcmp($1, "f32") == 0){
                                            CODEGEN("fstore %d\n",ta);
                                        }else if(strcmp($1, "str") == 0){
                                            CODEGEN("astore %d\n",ta);
                                        }
                                    }else{
                                        switch($2[0]){
                                            case 'A': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("iadd\n");
                                                CODEGEN("istore %d\n",ta);
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fadd\n");
                                                CODEGEN("fstore %d\n",ta);
                                            }
                                            break;
                                            case 'S': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("isub\n");
                                                CODEGEN("istore %d\n",ta);
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fsub\n");
                                                CODEGEN("fstore %d\n",ta);
                                            }
                                            break;
                                            case 'M': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("imul\n");
                                                CODEGEN("istore %d\n",ta);
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fmul\n");
                                                CODEGEN("fstore %d\n",ta);
                                            }
                                            break;
                                            case 'D': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("idiv\n");
                                                CODEGEN("istore %d\n",ta);
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fdiv\n");
                                                CODEGEN("fstore %d\n",ta);
                                            }
                                            break;
                                            case 'R':  
                                                CODEGEN("irem\n");
                                                CODEGEN("istore %d\n",ta);
                                            break;
                                            default:
                                            break;
                                        }
                                    
                                } 
                            }
                        }
    }
    | Expression
    | LBRACE LocalStatementList RBRACE
    | IfElse
    | WHILE {CODEGEN("while:\n");} Condition LBRACE {stack_c_p++; stack_c[stack_c_p] = Com_num; CODEGEN("ifeq comp_end_%d\n", stack_c[stack_c_p]);} LocalStatementList {  CODEGEN("\tgoto while\n");} RBRACE { CODEGEN("comp_end_%d:\n", stack_c[stack_c_p]);stack_c_p--; Com_num++;}
    | FOR ID IN ID '{' PRINTLN '(' ID ')' ';''}'{           
                            // int t;
                            // t = addr_arr[scope_level-1];
                            // table_arr[scope_level-1][t].index_table = t;
                            // table_arr[scope_level-1][t].name_table = $4;
                            // table_arr[scope_level-1][t].mut_table = 0;
                            // table_arr[scope_level-1][t].type_table = "i32";
                            // table_arr[scope_level-1][t].addr_table = now_add;
                            // table_arr[scope_level-1][t].lineno_table = yylineno+1;
                            // table_arr[scope_level-1][t].func_sig_table = "-";
                            // table_arr[scope_level-1][t].print_table = 1;
                            // print_r_table[scope_level-1] = 1;
                            // addr_arr[scope_level-1] ++;
                            // now_add ++;
                            // insert_symbol(scope_level-1,t);
                            char* mmt;
                            mmt = lookup_symbol($4,3);
                            printf("%d",ts);
                            for(int i =0 ; i < ts; i++){
                            //printf("ta%d",ta);
                                switch(mmt[0]){
                                    // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                    //         CODEGEN("swap\n");
                                    //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                    //         break;
                                    case 'f':
                                            CODEGEN("fload %d\n",ta+(ts-i-1)); 
                                            break;
                                    case 'i': 
                                            CODEGEN("iload %d\n",ta+(ts-i-1)); 
                                            break;
                                    case 's': 
                                            CODEGEN("aload %d\n",ta+(ts-i-1)); 
                                            break;
                                    default:  break;
                            }
                            switch(mmt[0]){
                                case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                                        break;
                                case 'f': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        CODEGEN("invokevirtual java/io/PrintStream/println(F)V\n");
                                        break;
                                case 'i': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        CODEGEN("invokevirtual java/io/PrintStream/println(I)V\n"); 
                                        break;
                                case 's': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                                        CODEGEN("swap\n");
                                        CODEGEN("invokevirtual java/io/PrintStream/println(Ljava/lang/String;)V\n");
                                        break;
                                default:  break;
                            } 
                            }

    }
    | RETURN    { printf("return\n"); }
    | RETURN Expression { printf("%creturn\n", $2[0]); print_r_table[scope_level-1] = 0;}
    //| BREAK { CODEGEN("\tgoto comp_end_%d\n",stack_c[stack_c_p-1]);}
    //| BREAK Expression { CODEGEN("\tgoto comp_end_%d\n",stack_c[stack_c_p-1]);}
    | BREAK { ;}
    | BREAK Expression { ;}
    | NEWLINE
    |';'
;


SID :
    ID{
        $$ = lookup_symbol($1,2);
    }

IfElse
    : IF Condition IfElseB {CODEGEN("comp_true_%d:\n",stack_c[stack_c_p]); CODEGEN("comp_end_%d:\n",stack_c[stack_c_p]); Com_num++; stack_c_p -- ;}
    | IF Condition IfElseB ELSE {CODEGEN("comp_true_%d:\n",stack_c[stack_c_p]);} IfElse {CODEGEN("comp_end_%d:\n",stack_c[stack_c_p]); Com_num++; stack_c_p -- ;}
    | IF Condition IfElseB ELSE {CODEGEN("comp_true_%d:\n",stack_c[stack_c_p]);} LBRACE LocalStatementList RBRACE {CODEGEN("comp_end_%d:\n",stack_c[stack_c_p]); Com_num++;stack_c_p -- ;}
;

IfElseB
    :LBRACE { stack_c_p++; stack_c[stack_c_p] = Com_num ; CODEGEN("ifeq comp_true_%d\n",stack_c[stack_c_p]);}  LocalStatementList RBRACE {  CODEGEN("\tgoto comp_end_%d\n",stack_c[stack_c_p]); }

Condition
    : Expression {

    }   
;

AssOP
    : '='   { $$ = "ASSIGN";}
    | ADD_ASSIGN   { $$ = "ADD_ASSIGN"; }
    | SUB_ASSIGN   { $$ = "SUB_ASSIGN"; }
    | MUL_ASSIGN   { $$ = "MUL_ASSIGN"; }
    | DIV_ASSIGN   { $$ = "DIV_ASSIGN"; }
    | REM_ASSIGN   { $$ = "REM_ASSIGN"; }
;

ShiftOP
    : LSHIFT { $$ = "LSHIFT"; }
    | RSHIFT { $$ = "RSHIFT"; }
    
Expression
    : Expression LOR LorLand  { 
                                if(strcmp($1, $3) != 0){
                                    char *temp;
                                    asprintf(&temp, "invalid operation: LOR (mismatched types %s and %s)", $1, $3);
                                    yyerror(temp);
                                    g_has_error = true;
                                }
                                printf("LOR\n");
                                $$ = "bool";
                                CODEGEN("ior\n");
                                                 }
    | LorLand {$$ = $1;}
;

LorLand
    : LorLand LAND TermCOM  { 
                            if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: LAND (mismatched types %s and %s)", $1, $3);
                                yyerror(temp);
                                 g_has_error = true;
                            }
                            printf("LAND\n");
                            $$ = "bool";
                            CODEGEN("iand\n");
                         }
    | TermCOM { $$ = $1; }
;

TermCOM
    : TermCOM ComOP TermShift    {
                                if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: %s (mismatched types %s and %s)", $2, $1, $3);
                                yyerror(temp);
                                 g_has_error = true;
                                }
                                $$ = "bool";
                                if(strcmp($1, "i32") == 0){
                                    CODEGEN("isub\n"); 
                                }else if(strcmp($1, "f32") == 0){
                                    CODEGEN("fcmpl\n"); 
                                }
                                if(strcmp($2, "GTR") == 0){
                                    CODEGEN("ifgt comp_true_%d\n",Com_num);
                                }else if(strcmp($2, "LSS") == 0){
                                    CODEGEN("iflt comp_true_%d\n",Com_num);
                                }else if(strcmp($2, "GEQ") == 0){
                                    CODEGEN("ifge comp_true_%d\n",Com_num);
                                }else if(strcmp($2, "LEQ") == 0){
                                    CODEGEN("ifle comp_true_%d\n",Com_num);
                                }else if(strcmp($2, "EQL") == 0){
                                    CODEGEN("ifeq comp_true_%d\n",Com_num);
                                }else if(strcmp($2, "NEQ") == 0){
                                    CODEGEN("ifne comp_true_%d\n",Com_num);
                                }else{
                                    ;
                                }
                                CODEGEN("\ticonst_0\n");
                                CODEGEN("\tgoto comp_end_%d\n",Com_num);
                                CODEGEN("comp_true_%d:\n",Com_num);
                                CODEGEN("\ticonst_1\n");
                                CODEGEN("comp_end_%d:\n",Com_num);
                                Com_num++;
                                printf("%s\n", $2);
                            }
    | TermShift { $$ = $1; }
;

TermShift
    : TermShift ShiftOP TermAdd { 
                            if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: %s (mismatched types %s and %s)", $2, $1, $3);
                                yyerror(temp);
                                 g_has_error = true;
                            }
                            $$ = $1;
                            printf("%s\n", $2);
    }
    | TermAdd { $$ = $1; }
;

TermAdd
    : TermAdd AddOP TermMUL { 
                            if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: %s (mismatched types %s and %s)", $2, $1, $3);
                                yyerror(temp);
                                 g_has_error = true;
                            }
                            $$ = $1;
                            switch($2[0]){
                                    case 'A':
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("iadd\n"); 
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fadd\n"); 
                                            }
                                            break;
                                    case 'S': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("isub\n"); 
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fsub\n"); 
                                            }
                                            break;
                                    default:  break;
                            }
                            printf("%s\n", $2);
                        }
    | TermMUL { $$ = $1; }
;

TermMUL
    : TermMUL MULOP TermUOP 
      {                     
                            if(strcmp($1, $3) != 0){
                                char *temp;
                                asprintf(&temp, "invalid operation: %s (mismatched types %s and %s)", $2, $1, $3);
                                yyerror(temp);
                                 g_has_error = true;
                            }
                            $$ = $1;
                            switch($2[0]){
                                    case 'M':
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("imul\n"); 
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fmul\n"); 
                                            }
                                            break;
                                    case 'D': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("idiv\n"); 
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("fdiv\n"); 
                                            }
                                            break;
                                    case 'R': 
                                            if(strcmp($1, "i32") == 0){
                                                CODEGEN("irem\n"); 
                                            }else if(strcmp($1, "f32") == 0){
                                                CODEGEN("frem\n"); 
                                            }
                                            break;
                                    default:  break;
                            }
                            printf("%s\n", $2);
                            }

    | TermUOP { $$ = $1;}
;

TermUOP
    :
    MUOP ChangeType{ 
                      printf("%s", op_temp);
                      if(strcmp($2, "i32") == 0){
                            //CODEGEN("ineg\n");
                            asprintf(&op_temp, "ineg\n"); 
                        }else if(strcmp($2, "f32") == 0){
                            //CODEGEN("fneg\n"); 
                            asprintf(&op_temp, "fneg\n");
                      }
                      op_temp = NULL;
                      $$ = $2;
                      }
    | '-' ChangeType{ 
                      printf("%s", op_temp);
                      if(strcmp($2, "i32") == 0){
                            CODEGEN("ineg\n");
                      }else if(strcmp($2, "f32") == 0){
                            CODEGEN("fneg\n"); 
                      }
                      $$ = $2;
    }
    | ChangeType   { $$ = $1; }

MUOP
    : MUOP '!' {  if(op_temp == NULL) {
                    asprintf(&op_temp, "iconst_1\nixor\n");
                 }else {
                    //asprintf(&op_temp, "%s%s\n", op_temp,$2);
                    asprintf(&op_temp, "%siconst_1\nixor\n",op_temp);
                }
            }
    |


OtherExpr
    : 
    //LOOP {CODEGEN("Loop:\n");} LBRACE {stack_c_p++; stack_c[stack_c_p] = Com_num ;} LocalStatementList {  CODEGEN("\tgoto Loop\n");} RBRACE { CODEGEN("comp_end_%d:\n",stack_c[stack_c_p]); Com_num++; stack_c_p--;}
    LOOP LBRACE Expression  ADD_ASSIGN INT_LIT ';' IF Condition LBRACE LocalStatementList RBRACE RBRACE {
        int t;
                                        //int mt = now_add;
        t = addr_arr[scope_level-1];
        table_arr[scope_level-1][t].index_table = t;
        table_arr[scope_level-1][t].name_table = "result";
        table_arr[scope_level-1][t].mut_table = 0;
        table_arr[scope_level-1][t].type_table = "str";
        table_arr[scope_level-1][t].addr_table = 1;
        table_arr[scope_level-1][t].lineno_table = yylineno+1;
        table_arr[scope_level-1][t].func_sig_table = "-";
        table_arr[scope_level-1][t].print_table = 1;
        print_r_table[scope_level-1] = 1;
        addr_arr[scope_level-1] ++;
        //now_add ++;
        insert_symbol(scope_level-1,t);
        int t1;
        t1 = addr_arr[scope_level-1];
        table_arr[scope_level-1][t1].index_table = t1;
        table_arr[scope_level-1][t1].name_table = "counter";
        table_arr[scope_level-1][t1].mut_table = 0;
        table_arr[scope_level-1][t1].type_table = "i32";
        table_arr[scope_level-1][t1].addr_table = 2;
        table_arr[scope_level-1][t1].lineno_table = yylineno+1;
        table_arr[scope_level-1][t1].func_sig_table = "-";
        table_arr[scope_level-1][t1].print_table = 1;
        print_r_table[scope_level-1] = 1;
        addr_arr[scope_level-1] ++;

        table_arr[scope_level-1][t].name_table = "n";
        //now_add ++;
        insert_symbol(scope_level-1,t);
        CODEGEN("ldc \"loop break\"\n");
        CODEGEN("astore 1\n");
        CODEGEN("ldc 10\n");
        CODEGEN("istore 0\n");
        ;
    }
    | Literal { $$ = $1;}
    | ID { $$ = lookup_symbol($1,1);}
    | ID '(' ')' { $$ = lookup_symbol($1,1);}
    | ID '(' Argument ')' { $$ = lookup_symbol($1,1); }
    | '(' Expression ')' { $$ = $2;}
    | '[' Expression ']' { $$ = $2;}
    | '&'ID '[' INT_LIT DOTDOT ']' { lookup_symbol($2,1);printf("INT_LIT %d\n", $4);printf("DOTDOT\n"); bbb = 1;}
    | '&'ID '[' INT_LIT DOTDOT INT_LIT']' { lookup_symbol($2,1); printf("INT_LIT %d\n", $4);printf("DOTDOT\n");printf("INT_LIT %d\n", $6);}
    | '&'ID '[' DOTDOT INT_LIT']' { lookup_symbol($2,1); printf("DOTDOT\n");printf("INT_LIT %d\n", $5);}
    //|
;

AddOP
    : '+'   { $$ = "ADD"; }
    | '-'   { $$ = "SUB"; }
;

MULOP
    : '*'   { $$ = "MUL"; }
    | '/'   { $$ = "DIV"; }
    | '%'   { $$ = "REM"; }
;


UOP
    : '+'   { $$ = "POS"; }
    | '-'   { $$ = "NEG"; }
    | '!'   { $$ = "NOT"; }
    //| DOTDOT   { $$ = "DOTDOT"; }
;

ComOP
    : '>'   { $$ = "GTR"; }
    | '<'   { $$ = "LSS"; }
    | GEQ   { $$ = "GEQ"; }
    | LEQ   { $$ = "LEQ"; }
    | EQL   { $$ = "EQL"; }
    | NEQ   { $$ = "NEQ"; }
;

Argument
    : Expression 
    | Argument ',' Expression
;


Literal
    : INT_LIT   { 
                    //printf("INT_LIT %d\n", $1); 
                    CODEGEN("ldc %d\n",$1); 
                    $$ = "i32"; }
    | FLOAT_LIT { 
                //printf("FLOAT_LIT %f\n", $1); 
                CODEGEN("ldc %f\n",$1); 
                    $$ = "f32"; }
    | BOOL_LIT  { $$ = "bool"; }
    | '"' STRING_LIT '"' { 
                            //printf("STRING_LIT \"%s\"\n", $2);
                                $$ = "str";
                          CODEGEN("ldc \"%s\"\n",$2); }
    | '"' '"' { 
                //printf("STRING_LIT \"\"\n");
                CODEGEN("ldc \"\"\n");
                        $$ = "str"; }
;

BOOL_LIT
    : TRUE  { printf("bool TRUE\n");  CODEGEN("iconst_1\n"); }
    | FALSE { printf("bool FALSE\n"); CODEGEN("iconst_0\n"); }
;

ChangeType
    : ID AS Type  { char *temp;
                            asprintf(&temp, "%c2%c", lookup_symbol($1,1)[0], $3[0]);
                            CODEGEN("%s\n", temp);
                            $$ = $3;
                            printf("%s\n", temp); }
    | Literal AS Type  { char *temp;
                            asprintf(&temp, "%c2%c", $1[0], $3[0]);
                            CODEGEN("%s\n", temp);
                            $$ = $3;
                            printf("%s\n", temp); }
    | Literal ',' Expression { $$ = $1;}
    | OtherExpr { $$ = $1;}
;

Type
    : INT    { $$ = "i32"; }
    | FLOAT  { $$ = "f32"; }
    | BOOL   { $$ = "bool"; }
    | '&'STR    { $$ = "str"; }
    | STR    { $$ = "str"; }
;

RBRACE
    : '}'  { 
            if(temp_r != 'v' && print_r_table[stack_pointer] == 1){
                printf("%creturn\n", temp_r);
            }
            dump_symbol();
            scope_level --; }
;



%%

/* C code section */
int main(int argc, char *argv[])
{
    if (argc == 2) {
        yyin = fopen(argv[1], "r");
    } else {
        yyin = stdin;
    }
    if (!yyin) {
        printf("file `%s` doesn't exists or cannot be opened\n", argv[1]);
        exit(1);
    }

    /* Codegen output init */
    char *bytecode_filename = "hw3.j";
    fout = fopen(bytecode_filename, "w");
    CODEGEN(".source hw3.j\n");
    CODEGEN(".class public Main\n");
    CODEGEN(".super java/lang/Object\n");

    for(int i=0 ;i<500 ;i++ ){
        addr_arr[i] = 0;
        for(int j=0 ; j<500 ;j++){
          table_arr[i][j].print_table = 0;
        }
    } 
    mulfun_size = 0 ;
    yylineno = 0;
    int t;
    t = addr_arr[scope_level];
    table_arr[scope_level][t].print_table = 0;
    scope_level ++;
    stack_pointer ++ ;
    create_symbol();
    CODEGEN(".method public static main([Ljava/lang/String;)V\n");
    CODEGEN(".limit stack 100\n");
    CODEGEN(".limit locals 100\n");
    yyparse();
    CODEGEN("return\n");
    CODEGEN(".end method\n");
    dump_symbol();

	printf("Total lines: %d\n", yylineno);
    fclose(yyin);
    if (g_has_error) {
        remove(bytecode_filename);
    }
    yylex_destroy();
    return 0;
}

static void create_symbol() {
    printf("> Create symbol table (scope level %d)\n", stack_pointer);
}

static void insert_symbol(int a,int b) {
    printf("> Insert `%s` (addr: %d) to scope level %d\n", table_arr[a][b].name_table, table_arr[a][b].addr_table, a);
}

static char * lookup_symbol(char *name,int n) {
    int exist = 0;
    int to_print_i, to_print_j;
    for(int i=0; i<500 ;i++ ){
        for(int j=0; j<500 ;j++){
            if(table_arr[i][j].print_table){
                if(strcmp(table_arr[i][j].name_table,name) == 0){
                    exist = 1;
                    to_print_i = i;
                    to_print_j = j;
                    break;
                }
            }
        }
    } 
    if(exist){
        if(strcmp(table_arr[to_print_i][to_print_j].type_table, "func") == 0){
            printf("call: %s%s\n", table_arr[to_print_i][to_print_j].name_table, table_arr[to_print_i][to_print_j].func_sig_table);
            switch(table_arr[to_print_i][to_print_j].func_sig_table[-1]){
                case 'I': return "i32"; break;
                case 'F': return "f32"; break;
                case 'B': return "bool"; break;
                case 'S': return "string"; break;
                default: return "void"; break;
            }
        }else{
            if(n==1){
                printf("IDENT (name=%s, address=%d)\n", table_arr[to_print_i][to_print_j].name_table, table_arr[to_print_i][to_print_j].addr_table);
                 switch(table_arr[to_print_i][to_print_j].type_table[0]){
                        // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                        //         CODEGEN("swap\n");
                        //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                        //         break;
                        case 'f':
                                CODEGEN("fload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        case 'i': 
                                CODEGEN("iload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        case 's': 
                                CODEGEN("aload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        default:  break;
                }
            }else if(n==2){
                 printf("IDENT (name=%s, address=%d)\n", table_arr[to_print_i][to_print_j].name_table, table_arr[to_print_i][to_print_j].addr_table);
                 switch(table_arr[to_print_i][to_print_j].type_table[0]){
                        // case 'b': CODEGEN("getstatic java/lang/System/out Ljava/io/PrintStream;\n");
                        //         CODEGEN("swap\n");
                        //         CODEGEN("invokevirtual java/io/PrintStream/println(Z)V\n"); 
                        //         break;
                        case 'f':
                                CODEGEN("fload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        case 'i': 
                                CODEGEN("iload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        case 's': 
                                CODEGEN("aload %d\n",table_arr[to_print_i][to_print_j].addr_table); 
                                break;
                        default:  break;
                }
                    ta = table_arr[to_print_i][to_print_j].addr_table;
            }else if(n==3){
                ta = table_arr[to_print_i][to_print_j].addr_table;
                ts = table_arr[to_print_i][to_print_j].arr_size_table;
            }
            return table_arr[to_print_i][to_print_j].type_table;
        }
    }else{
        char *temp;
        asprintf(&temp, "undefined: %s", name);
        yyerror(temp);
        g_has_error = true;
        return "undefined";
    }
}

static void dump_symbol() {
    int count = 0;
    printf("\n> Dump symbol table (scope level: %d)\n", stack_pointer);
    printf("%-10s%-10s%-10s%-10s%-10s%-10s%-10s\n",
        "Index", "Name", "Mut","Type", "Addr", "Lineno", "Func_sig");
    for(int i=0; i<500 ;i++){
        if(table_arr[stack_pointer][i].print_table && stack_pointer >= 0){
            printf("%-10d%-10s%-10d%-10s%-10d%-10d%-10s\n",
            count, table_arr[stack_pointer][i].name_table, 
            table_arr[stack_pointer][i].mut_table, table_arr[stack_pointer][i].type_table, 
            table_arr[stack_pointer][i].addr_table, table_arr[stack_pointer][i].lineno_table,
            table_arr[stack_pointer][i].func_sig_table);
            table_arr[stack_pointer][i].print_table = 0;
            count ++;
        }
    }
    stack_pointer -- ;
}