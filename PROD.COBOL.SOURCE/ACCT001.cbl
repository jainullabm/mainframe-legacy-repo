       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCT001.
       AUTHOR. MAINFRAME-MODERNIZATION-TEAM.
      *================================================================*
      * PROGRAM : ACCT001                                              *
      * PURPOSE : READS CUSTOMER ACCOUNT INPUT, VALIDATES STATUS,      *
      *           APPLIES TIERED INTEREST & MAINTENANCE FEES, AND      *
      *           WRITES SETTLED OR REJECTED ACCOUNT RECORDS.          *
      *================================================================*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCT-IN-FILE  ASSIGN TO ACCTIN
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-IN-STATUS.
           SELECT ACCT-OUT-FILE ASSIGN TO ACCTOUT
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-OUT-STATUS.
           SELECT ACCT-REJ-FILE ASSIGN TO REJOUT
                  ORGANIZATION IS SEQUENTIAL
                  FILE STATUS IS WS-REJ-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCT-IN-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 120 CHARACTERS.
       01  FD-ACCT-IN-REC              PIC X(120).

       FD  ACCT-OUT-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 120 CHARACTERS.
       01  FD-ACCT-OUT-REC             PIC X(120).

       FD  ACCT-REJ-FILE
           RECORDING MODE IS F
           RECORD CONTAINS 120 CHARACTERS.
       01  FD-ACCT-REJ-REC             PIC X(120).

       WORKING-STORAGE SECTION.
       01  WS-FILE-FLAGS.
           05  WS-IN-STATUS            PIC X(02) VALUE SPACES.
           05  WS-OUT-STATUS           PIC X(02) VALUE SPACES.
           05  WS-REJ-STATUS           PIC X(02) VALUE SPACES.
           05  WS-EOF-FLAG             PIC X(01) VALUE 'N'.
               88  END-OF-FILE                   VALUE 'Y'.

       01  WS-CALC-WORK-FIELDS.
           05  WS-INTEREST-RATE        PIC 9(01)V9(04) VALUE 0.0350.
           05  WS-CALC-INTEREST        PIC 9(07)V99    VALUE ZEROS.
           05  WS-SERVICE-FEE          PIC 9(05)V99    VALUE ZEROS.
           05  WS-READ-CNT             PIC 9(07)       VALUE ZEROS.
           05  WS-VALID-CNT            PIC 9(07)       VALUE ZEROS.
           05  WS-REJECT-CNT           PIC 9(07)       VALUE ZEROS.

      *--- PULL RECORD LAYOUTS FROM PROD.COPYBOOK.SOURCE ---*
       COPY ACCTCPY1.

       PROCEDURE DIVISION.
       0000-MAIN-CONTROL.
           PERFORM 1000-INITIALIZE
           PERFORM 2000-PROCESS-RECORDS
               UNTIL END-OF-FILE
           PERFORM 3000-TERMINATE
           STOP RUN.

       1000-INITIALIZE.
           OPEN INPUT  ACCT-IN-FILE
                OUTPUT ACCT-OUT-FILE
                       ACCT-REJ-FILE
           INITIALIZE SRC-ACCT-RECORD
                      TGT-ACCT-RECORD
           PERFORM 1500-READ-NEXT-RECORD.

       1500-READ-NEXT-RECORD.
           READ ACCT-IN-FILE INTO SRC-ACCT-RECORD
               AT END
                   MOVE 'Y' TO WS-EOF-FLAG
               NOT AT END
                   ADD 1 TO WS-READ-CNT
           END-READ.

       2000-PROCESS-RECORDS.
           IF SRC-ACCT-ID = SPACES OR SRC-ACCT-STATUS = 'C'
               PERFORM 2200-HANDLE-REJECT
           ELSE
               PERFORM 2100-CALCULATE-SETTLEMENT
           END-IF
           PERFORM 1500-READ-NEXT-RECORD.

       2100-CALCULATE-SETTLEMENT.
           INITIALIZE TGT-ACCT-RECORD
           MOVE SRC-ACCT-ID       TO TGT-ACCT-ID
           MOVE SRC-CUST-FirstName TO TGT-CUST-NAME
           MOVE SRC-ACCT-TYPE     TO TGT-ACCT-TYPE
           MOVE SRC-OPEN-DATE     TO TGT-SETTLE-DATE

           EVALUATE SRC-ACCT-TYPE
               WHEN 'SAV'
                   MOVE 0.0425 TO WS-INTEREST-RATE
                   MOVE 0.00   TO WS-SERVICE-FEE
               WHEN 'CHK'
                   MOVE 0.0125 TO WS-INTEREST-RATE
                   IF SRC-CURR-BAL < 1000.00
                       MOVE 15.00 TO WS-SERVICE-FEE
                   ELSE
                       MOVE 0.00  TO WS-SERVICE-FEE
                   END-IF
               WHEN 'VIP'
                   MOVE 0.0550 TO WS-INTEREST-RATE
                   MOVE 0.00   TO WS-SERVICE-FEE
               WHEN OTHER
                   MOVE 0.0100 TO WS-INTEREST-RATE
                   MOVE 10.00  TO WS-SERVICE-FEE
           END-EVALUATE

           COMPUTE WS-CALC-INTEREST ROUNDED =
               SRC-CURR-BAL * WS-INTEREST-RATE

           COMPUTE TGT-NEW-BAL ROUNDED =
               SRC-CURR-BAL + WS-CALC-INTEREST - WS-SERVICE-FEE

           MOVE WS-CALC-INTEREST  TO TGT-INT-EARNED
           MOVE WS-SERVICE-FEE    TO TGT-FEE-APPLIED
           MOVE 'SETTLED'         TO TGT-PROC-STATUS

           WRITE FD-ACCT-OUT-REC FROM TGT-ACCT-RECORD
           ADD 1 TO WS-VALID-CNT.

       2200-HANDLE-REJECT.
           INITIALIZE TGT-ACCT-RECORD
           MOVE SRC-ACCT-ID       TO TGT-ACCT-ID
           MOVE SRC-CUST-FirstName TO TGT-CUST-NAME
           MOVE SRC-ACCT-TYPE     TO TGT-ACCT-TYPE
           MOVE SRC-CURR-BAL      TO TGT-NEW-BAL
           MOVE ZEROS             TO TGT-INT-EARNED
           MOVE ZEROS             TO TGT-FEE-APPLIED
           MOVE 'REJECTED'        TO TGT-PROC-STATUS
           MOVE SRC-OPEN-DATE     TO TGT-SETTLE-DATE

           WRITE FD-ACCT-REJ-REC FROM TGT-ACCT-RECORD
           ADD 1 TO WS-REJECT-CNT.

       3000-TERMINATE.
           DISPLAY 'TOTAL RECORDS READ     : ' WS-READ-CNT
           DISPLAY 'TOTAL RECORDS SETTLED  : ' WS-VALID-CNT
           DISPLAY 'TOTAL RECORDS REJECTED : ' WS-REJECT-CNT
           CLOSE ACCT-IN-FILE
                 ACCT-OUT-FILE
                 ACCT-REJ-FILE.
