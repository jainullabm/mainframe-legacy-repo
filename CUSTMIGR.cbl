       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTMIGR.
       AUTHOR. DATA-MODERNIZATION-AGENT.
       
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LEGACY-CUSTOMER ASSIGN TO "LEGACY.CUST.DAT"
               ORGANIZATION IS SEQUENTIAL.
           SELECT TARGET-CUSTOMER ASSIGN TO "TARGET.CUST.DAT"
               ORGANIZATION IS SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.
       FD  LEGACY-CUSTOMER.
       01  LEGACY-REC.
           05  SRC-CUST-ID        PIC X(08).
           05  SRC-FIRST-NAME     PIC X(15).
           05  SRC-LAST-NAME      PIC X(20).
           05  SRC-STATUS-CD      PIC X(01).
           05  SRC-JOIN-YYMMDD    PIC X(06).
           05  SRC-CURR-BAL       PIC S9(7)V99 COMP-3.
           05  SRC-HOLD-AMT       PIC S9(5)V99 COMP-3.

       FD  TARGET-CUSTOMER.
       01  TARGET-REC.
           05  TGT-GLOBAL-ID      PIC X(15).
           05  TGT-FULL-NAME      PIC X(36).
           05  TGT-STATUS-DESC    PIC X(12).
           05  TGT-JOIN-DATE-ISO  PIC X(10).
           05  TGT-LEDGER-BAL     PIC S9(9)V99 COMP-3.
           05  TGT-AVAILABLE-BAL  PIC S9(9)V99 COMP-3.

       WORKING-STORAGE SECTION.
       01  WS-EOF-SW              PIC X(01) VALUE 'N'.
           88  EOF-REACHED                   VALUE 'Y'.
           
       01  WS-DATE-TEMP.
           05  WS-YY              PIC X(02).
           05  WS-MM              PIC X(02).
           05  WS-DD              PIC X(02).
           
       01  WS-CENTURY-CC          PIC X(02).
       01  WS-AVAIL-CALC          PIC S9(9)V99 COMP-3.

       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT LEGACY-CUSTOMER
           OPEN OUTPUT TARGET-CUSTOMER
           
           PERFORM UNTIL EOF-REACHED
               READ LEGACY-CUSTOMER
                   AT END
                       SET EOF-REACHED TO TRUE
                   NOT AT END
                       PERFORM 1000-MIGRATE-RECORD
               END-READ
           END-PERFORM
           
           CLOSE LEGACY-CUSTOMER
           CLOSE TARGET-CUSTOMER
           STOP RUN.

       1000-MIGRATE-RECORD.
           INITIALIZE TARGET-REC
           
           * 1. Transform Customer ID to a modern global concatenated ID format
           STRING "CNV-" SRC-CUST-ID DELIMITED BY SIZE INTO TGT-GLOBAL-ID
           
           * 2. Format and merge Full Name
           STRING SRC-LAST-NAME DELIMITED BY "  "
                  ", " DELIMITED BY SIZE
                  SRC-FIRST-NAME DELIMITED BY "  "
                  INTO TGT-FULL-NAME
                  
           * 3. Translate legacy Status Codes
           EVALUATE SRC-STATUS-CD
               WHEN "A"
                   MOVE "ACTIVE" TO TGT-STATUS-DESC
               WHEN "I"
                   MOVE "INACTIVE" TO TGT-STATUS-DESC
               WHEN "S"
                   MOVE "SUSPENDED" TO TGT-STATUS-DESC
               WHEN OTHER
                   MOVE "UNKNOWN" TO TGT-STATUS-DESC
           END-EVALUATE
           
           * 4. Perform Century Windowing for Date Formatting
           MOVE SRC-JOIN-YYMMDD TO WS-DATE-TEMP
           IF WS-YY > "50"
               MOVE "19" TO WS-CENTURY-CC
           ELSE
               MOVE "20" TO WS-CENTURY-CC
           END-IF
           
           STRING WS-CENTURY-CC DELIMITED BY SIZE
                  WS-YY DELIMITED BY SIZE
                  "-" DELIMITED BY SIZE
                  WS-MM DELIMITED BY SIZE
                  "-" DELIMITED BY SIZE
                  WS-DD DELIMITED BY SIZE
                  INTO TGT-JOIN-DATE-ISO
                  
           * 5. Scale and transfer ledger balance COMP-3 values
           MOVE SRC-CURR-BAL TO TGT-LEDGER-BAL
           
           * 6. Calculate available balance subtracting Hold amount
           COMPUTE WS-AVAIL-CALC = SRC-CURR-BAL - SRC-HOLD-AMT
           MOVE WS-AVAIL-CALC TO TGT-AVAILABLE-BAL
           
           WRITE TARGET-REC.
