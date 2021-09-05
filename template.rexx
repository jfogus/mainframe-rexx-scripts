/**************************** REXX *********************************/
/* REXX Script to create a JCL/COBOL Template                      */
/* Must give it a jcl dataset name, src COBOL datasets to compile, */
/* dataset of where to put the compiled COBOL, and any input or    */
/* output datasets for the cobol and jcl in the form of a space    */
/* seperated list.  E.g.: jcl=data.jcl(set) src=source.cobol(set)  */
/* exe=load.cobol(set) dds=data.set(first),data.set(second)        */
/*******************************************************************/
PARSE UPPER ARG args
PARSE UPPER ARG 'JCL=' jcl_file .
PARSE UPPER ARG 'DDS=' dd_args .
PARSE UPPER ARG 'SRC=' src .
PARSE UPPER ARG 'EXE=' exe .
jcl_sep = "//"COPIES("*",50)"*/"
cbl_sep = COPIES(" ", 6)"*"
spaces7 = COPIES(" ", 7)
spaces11 = COPIES(" ", 11)

cbl_id_div. = ""
cbl_en_div. = ""
cbl_en_len  = 0
cbl_da_div. = ""
cbl_da_len  = 0
cbl_pr_div. = ""
cbl_pr_len  = 0

/*******************************************************************/
/* Open Files */
/*******************************************************************/
"FREE FI(jcldd)"
"FREE FI(cbldd)"
"ALLOC FI(jcldd) DA('"jcl_file"') SHR REUSE"
"ALLOC FI(cbldd) DA('"src"') SHR REUSE"

/*******************************************************************/
/* Write JCL Job Line */
/*******************************************************************/
open_paren = INDEX(jcl_file, "(")
clos_paren = INDEX(jcl_file, ")")
jcl_member = SUBSTR(jcl_file, open_paren + 1, clos_paren - open_paren - 1)

jcl_data.1 = "//"jcl_member" JOB 1,NOTIFY=&SYSUID"
jcl_data.2 = jcl_sep
"EXECIO 2 DISKW jcldd (STEM jcl_data."

/*******************************************************************/
/* Write JCL Compile Lines */
/*******************************************************************/
PARSE VAR src src_project "." src
PARSE VAR exe exe_project "." exe

jcl_data.1 = "//COBRUN EXEC IGYWCL"
jcl_data.2 = "//COBOL.SYSIN DD DSN=&SYSUID.."src",DISP=SHR"
jcl_data.3 = "//LKED.SYSLMOD DD DSN=&SYSUID.."exe",DISP=SHR"
jcl_data.4 = jcl_sep
jcl_data.5 = "// IF RC = 0 THEN"
jcl_data.6 = jcl_sep
"EXECIO 6 DISKW jcldd (STEM jcl_data."

/*******************************************************************/
/* Write JCL Run Lines */
/*******************************************************************/
PARSE VAR exe grp_type "(" member ")"

jcl_data.1 = "//RUN EXEC PGM="member
jcl_data.2 = "//STEPLIB DD DSN=&SYSUID.."grp_type",DISP=SHR"
"EXECIO 2 DISKW jcldd (STEM jcl_data."

/*******************************************************************/
/* Write CBL Identification Division */
/*******************************************************************/
cbl_id_div.1 = spaces7"IDENTIFICATION DIVISION."
cbl_id_div.2 = spaces7"PROGRAM-ID." member
cbl_id_div.3 = cbl_sep "TODO: Change Author"
cbl_id_div.4 = spaces7"AUTHOR. A-NAME."
cbl_id_div.5 = cbl_sep
"EXECIO 5 DISKW cbldd (stem cbl_id_div."

/*******************************************************************/
/* Write CBL Environment Division */
/*******************************************************************/
cbl_en_div.1 = spaces7"ENVIRONMENT DIVISION."
cbl_en_div.2 = cbl_sep
cbl_en_div.3 = spaces7"INPUT-OUTPUT SECTION."
cbl_en_div.4 = spaces7"FILE-CONTROL."
cbl_en_div.5 = cbl_sep "TODO: Change all occurrences of file handle"
cbl_en_len = 5

/*******************************************************************/
/* Write CBL Data Division */
/*******************************************************************/
cbl_da_div.1 = spaces7"DATA DIVISION."
cbl_da_div.2 = spaces7"FILE SECTION."
cbl_da_len = 2

/*******************************************************************/
/* Write File Lines */
/*******************************************************************/
i = 1
DO WHILE (LENGTH(dd_args) \= 0)
    PARSE VAR dd_args input "," dd_args
    PARSE VAR input inp_project "." input
    PARSE VAR input grp_type "(" member ")"

    j = cbl_en_len + 1
    k = cbl_da_len + 1

    jcl_data.i = "//"member" DD DSN=&SYSUID.."input",DISP=SHR"

    fi_handle = INSERT("-", member, length(member) % 2)
    cbl_en_div.j = spaces11"SELECT" fi_handle
    cbl_en_div.j = cbl_en_div.j "ASSIGN TO" member"."

    cbl_da_div.k = spaces7"FD" fi_handle "RECORD CONTAINS 80 CHARACTERS"
    cbl_da_div.k = cbl_da_div.k "RECORDING MODE F."

    k = k + 1
    cbl_da_div.k = spaces7"01" SUBSTR(member, 1, length(member) % 2)"."

    cbl_en_len = j
    cbl_da_len = k
    i = i + 1
END

cbl_en_len = cbl_en_len + 1
cbl_en_div.cbl_en_len = cbl_sep

"EXECIO" i - 1 "DISKW jcldd (STEM jcl_data."
"EXECIO" cbl_en_len "DISKW cbldd (STEM cbl_en_div."
"EXECIO" cbl_da_len "DISKW cbldd (STEM cbl_da_div."

/*******************************************************************/
/* Write CBL Procedure Division */
/*******************************************************************/
data.1 = cbl_sep
data.2 = spaces7"PROCEDURE DIVISION."
data.3 = spaces11"STOP RUN."

"EXECIO 3 DISKW cbldd (STEM data."

/*******************************************************************/
/* Write JCL System Info */
/*******************************************************************/
jcl_data.1 = "//SYSOUT DD SYSOUT=*,OUTLIM=15000"
jcl_data.2 = "//CEEDUMP DD DUMMY"
jcl_data.3 = "//SYSUDUMP DD DUMMY"
jcl_data.4 = jcl_sep
jcl_data.5 = "// ELSE"
jcl_data.6 = "// ENDIF"
"EXECIO 6 DISKW jcldd (STEM jcl_data."

/*******************************************************************/
/* Close Files */
/*******************************************************************/
"EXECIO 0 DISKW jcldd (FINIS"
"EXECIO 0 DISKW cbldd (FINIS"
"FREE FI(jcldd)"
"FREE FI(cbldd)"

EXIT
