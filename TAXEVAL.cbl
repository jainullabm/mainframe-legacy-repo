       IDENTIFICATION DIVISION.
       PROGRAM-ID. TAXEVAL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-TAX-PROFILE.
           05  WS-ANNUAL-INCOME  PIC 9(07)V99 VALUE 55000.00.
               88  TAX-BRACKET-LOW   VALUE 0.00 THRU 25000.00.
               88  TAX-BRACKET-MID   VALUE 25000.01 THRU 85000.00.
               88  TAX-BRACKET-HIGH  VALUE 85000.01 THRU 9999999.99.
           
           05  WS-FILING-STATUS  PIC X(01) VALUE 'S'.
               88  STATUS-SINGLE     VALUE 'S', 's'.
               88  STATUS-JOINT      VALUE 'M', 'm'.

       01  WS-CALC-VARS.
           05  WS-TAX-RATE       PIC 9(02)V99 VALUE ZERO.
           05  WS-DUE-TAX        PIC 9(06)V99 VALUE ZERO.

       PROCEDURE DIVISION.
       0000-PROCESS-TAX.
           DISPLAY "EVALUATING FEDERAL TAX SPEC..."

           EVALUATE TRUE
               WHEN TAX-BRACKET-LOW
                   IF STATUS-SINGLE
                       MOVE 0.10 TO WS-TAX-RATE
                   ELSE
                       MOVE 0.08 TO WS-TAX-RATE
                   END-IF
               WHEN TAX-BRACKET-MID
                   IF STATUS-SINGLE
                       MOVE 0.22 TO WS-TAX-RATE
                   ELSE
                       MOVE 0.15 TO WS-TAX-RATE
                   END-IF
               WHEN TAX-BRACKET-HIGH
                   MOVE 0.35 TO WS-TAX-RATE
               WHEN OTHER
                   DISPLAY "INVALID TAX PROFILE RANGE"
                   STOP RUN
           END-EVALUATE.

           COMPUTE WS-DUE-TAX = WS-ANNUAL-INCOME * WS-TAX-RATE.
           
           DISPLAY "TAX RATE DETECTED: " WS-TAX-RATE.
           DISPLAY "TOTAL LIABILITY  : " WS-DUE-TAX.
           STOP RUN.
