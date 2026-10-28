       IDENTIFICATION DIVISION.
       PROGRAM-ID. DB2SELC.
       
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       
       EXEC SQL INCLUDE SQLCA END-EXEC.

       EXEC SQL BEGIN DECLARE SECTION END-EXEC.
       01  DB-HOST-VARIABLES.
           05  H-EMP-ID          PIC X(06).
           05  H-FIRSTNAME       PIC X(12).
           05  H-LASTNAME        PIC X(15).
           05  H-SALARY          PIC S9(7)V99 COMP-3.
       EXEC SQL END DECLARE SECTION END-EXEC.

       01  WS-SYSTEM-VARS.
           05  WS-FETCH-COUNT    PIC 9(05) VALUE ZERO.

       PROCEDURE DIVISION.
       0001-EXECUTE-QUERY.
           DISPLAY "OPENING DB2 SQL CURSOR..."
           
           EXEC SQL
               DECLARE EMP_CURSOR CURSOR FOR
               SELECT EMPNO, FIRSTNME, LASTNAME, SALARY
               FROM EMPLOYEE
               WHERE SALARY > 75000.00
           END-EXEC.

           EXEC SQL OPEN EMP_CURSOR END-EXEC.
           
           IF SQLCODE NOT = 0
               DISPLAY "ERROR OPENING CURSOR: " SQLCODE
               PERFORM 9999-ERROR-EXIT
           END-IF.

           PERFORM 1000-FETCH-ROW UNTIL SQLCODE = 100.

           EXEC SQL CLOSE EMP_CURSOR END-EXEC.
           DISPLAY "TOTAL EMPLOYEES RETRIEVED: " WS-FETCH-COUNT.
           STOP RUN.

       1000-FETCH-ROW.
           EXEC SQL
               FETCH EMP_CURSOR 
               INTO :H-EMP-ID, :H-FIRSTNAME, :H-LASTNAME, :H-SALARY
           END-EXEC.

           IF SQLCODE = 0
               ADD 1 TO WS-FETCH-COUNT
               DISPLAY H-EMP-ID " - " H-LASTNAME ", " H-FIRSTNAME " - " H-SALARY
           ELSE IF SQLCODE NOT = 100
               DISPLAY "SQL FETCH ERROR: " SQLCODE
               PERFORM 9999-ERROR-EXIT
           END-IF.

       9999-ERROR-EXIT.
           DISPLAY "ABNORMAL END OF DB2 JOB."
           STOP RUN.
