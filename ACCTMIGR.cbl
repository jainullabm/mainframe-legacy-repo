       IDENTIFICATION DIVISION.
       PROGRAM-ID. ACCTMIGR.
       AUTHOR. DATA-MIGRATION-TEAM.
      ******************************************************************
      * PROGRAM OBJECTIVE:                                             *
      * CONVERTS LEGACY RETAIL BANKING ACCOUNTS FROM FLAT FILE LAYOUT  *
      * (LEGACY-ACCT-FILE) INTO MODERN CORE BANKING TARGET FORMAT      *
      * (TARGET-ACCT-FILE) AND INSERTS INTO DB2 STAGING TABLE.         *
      ******************************************************************

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT LEGACY-ACCT-FILE ASSIGN TO 'LEGACCT.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT TARGET-ACCT-FILE ASSIGN TO 'TGTACCT.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT REJECT-ACCT-FILE ASSIGN TO 'REJACCT.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

      *================================================================*
      * SOURCE SYSTEM INPUT LAYOUT (LEGACY MAINFRAME ACCOUNT RECORD)   *
      *================================================================*
       FD  LEGACY-ACCT-FILE.
       01  SRC-LEGACY-RECORD.
           05  SRC-BRANCH-CD         PIC X(03).
           05  SRC-ACCT-NUM          PIC X(10).
           05  SRC-CUST-FIRST-NM     PIC X(15).
           05  SRC-CUST-LAST-NM      PIC X(20).
           05  SRC-ACCT-TYPE-CD      PIC X(01).
               88  SRC-TYPE-SAVINGS  VALUE '1'.
               88  SRC-TYPE-CHECKING VALUE '2'.
               88  SRC-TYPE-LOAN     VALUE '3'.
           05  SRC-STAT-CD           PIC X(01).
           05  SRC-OPEN-YYMMDD       PIC X(06).
           05  SRC-CURR-BAL          PIC S9(07)V99 COMP-3.
           05  SRC-HOLD-AMT          PIC S9(05)V99 COMP-3.
           05  SRC-CR-SCORE          PIC 9(03).

      *================================================================*
      * TARGET SYSTEM OUTPUT LAYOUT (MODERNIZED CORE ACCOUNT RECORD)   *
      *================================================================*
       FD  TARGET-ACCT-FILE.
       01  TGT-MODERN-RECORD.
           05  TGT-GLOBAL-ACCT-ID    PIC X(16).
           05  TGT-FULL-NAME         PIC X(36).
           05  TGT-PRODUCT-CODE      PIC X(06).
           05  TGT-ACCOUNT-STATUS    PIC X(10).
           05  TGT-OPEN-DATE-ISO     PIC X(10).
           05  TGT-LEDGER-BALANCE    PIC S9(09)V99 COMP-3.
           05  TGT-AVAIL-BALANCE     PIC S9(09)V99 COMP-3.
           05  TGT-RISK-TIER         PIC X(06).
           05  TGT-MIGR-SOURCE-SYS   PIC X(08).

      *================================================================*
      * REJECTED / EXCEPTION OUTPUT LAYOUT                             *
      *================================================================*
       FD  REJECT-ACCT-FILE.
       01  REJ-ERROR-RECORD.
           05  REJ-ACCT-NUM          PIC X(10).
           05  REJ-REASON-CODE       PIC X(04).
           05  REJ-REASON-DESC       PIC X(40).

       WORKING-STORAGE SECTION.
       EXEC SQL INCLUDE SQLCA END-EXEC.

       01  WS-FLAGS.
           05  WS-EOF-SW             PIC X(01) VALUE 'N'.
               88  END-OF-FILE       VALUE 'Y'.
           05  WS-VALID-SW           PIC X(01) VALUE 'Y'.
               88  RECORD-IS-VALID   VALUE 'Y'.
               88  RECORD-IS-INVALID VALUE 'N'.

       01  WS-DATE-WORK.
           05  WS-YY                 PIC 9(02).
           05  WS-MM                 PIC 9(02).
           05  WS-DD                 PIC 9(02).
           05  WS-CCYY               PIC 9(04).

       01  WS-AUDIT-COUNTERS.
           05  WS-READ-CNT           PIC 9(07) VALUE ZERO.
           05  WS-MIGRATED-CNT       PIC 9(07) VALUE ZERO.
           05  WS-REJECTED-CNT       PIC 9(07) VALUE ZERO.

       PROCEDURE DIVISION.
       0000-MAIN-MIGRATION.
           OPEN INPUT  LEGACY-ACCT-FILE
                OUTPUT TARGET-ACCT-FILE
                       REJECT-ACCT-FILE.

           PERFORM 1000-READ-SOURCE.
           PERFORM UNTIL END-OF-FILE
               PERFORM 2000-VALIDATE-SOURCE
               IF RECORD-IS-VALID
                   PERFORM 3000-TRANSFORM-AND-MAP
                   PERFORM 4000-LOAD-TARGET
               ELSE
                   PERFORM 5000-WRITE-REJECT
               END-IF
               PERFORM 1000-READ-SOURCE
           END-PERFORM.

           DISPLAY "RECORDS READ    : " WS-READ-CNT.
           DISPLAY "RECORDS MIGRATED: " WS-MIGRATED-CNT.
           DISPLAY "RECORDS REJECTED: " WS-REJECTED-CNT.

           CLOSE LEGACY-ACCT-FILE
                 TARGET-ACCT-FILE
                 REJECT-ACCT-FILE.
           STOP RUN.

       1000-READ-SOURCE.
           READ LEGACY-ACCT-FILE
               AT END MOVE 'Y' TO WS-EOF-SW
               NOT AT END ADD 1 TO WS-READ-CNT
           END-READ.

       2000-VALIDATE-SOURCE.
           MOVE 'Y' TO WS-VALID-SW.
           IF SRC-ACCT-NUM = SPACES OR LOW-VALUES
               MOVE 'N' TO WS-VALID-SW
               MOVE SRC-ACCT-NUM TO REJ-ACCT-NUM
               MOVE 'E001' TO REJ-REASON-CODE
               MOVE 'MISSING SOURCE ACCOUNT NUMBER' TO REJ-REASON-DESC
           END-IF.

       3000-TRANSFORM-AND-MAP.
           INITIALIZE TGT-MODERN-RECORD.

      *    1. Map Composite Key: 'BNK' + Branch(3) + AcctNum(10)
           STRING 'BNK' DELIMITED BY SIZE
                  SRC-BRANCH-CD DELIMITED BY SIZE
                  SRC-ACCT-NUM  DELIMITED BY SIZE
               INTO TGT-GLOBAL-ACCT-ID
           END-STRING.

      *    2. Concatenate Last Name and First Name
           STRING SRC-CUST-LAST-NM  DELIMITED BY '  '
                  ', '              DELIMITED BY SIZE
                  SRC-CUST-FIRST-NM DELIMITED BY '  '
               INTO TGT-FULL-NAME
           END-STRING.

      *    3. Translate Legacy 1-Char Account Type to 6-Char Product Code
           EVALUATE TRUE
               WHEN SRC-TYPE-SAVINGS
                   MOVE 'SAV001' TO TGT-PRODUCT-CODE
               WHEN SRC-TYPE-CHECKING
                   MOVE 'CHK001' TO TGT-PRODUCT-CODE
               WHEN SRC-TYPE-LOAN
                   MOVE 'LON001' TO TGT-PRODUCT-CODE
               WHEN OTHER
                   MOVE 'GEN999' TO TGT-PRODUCT-CODE
           END-EVALUATE.

      *    4. Map Account Status Code to Target Status Description
           EVALUATE SRC-STAT-CD
               WHEN 'A'
                   MOVE 'ACTIVE    ' TO TGT-ACCOUNT-STATUS
               WHEN 'D'
                   MOVE 'DORMANT   ' TO TGT-ACCOUNT-STATUS
               WHEN 'C'
                   MOVE 'CLOSED    ' TO TGT-ACCOUNT-STATUS
               WHEN OTHER
                   MOVE 'SUSPENDED ' TO TGT-ACCOUNT-STATUS
           END-EVALUATE.

      *    5. Convert Legacy YYMMDD Date to ISO YYYY-MM-DD Format
           MOVE SRC-OPEN-YYMMDD(1:2) TO WS-YY.
           MOVE SRC-OPEN-YYMMDD(3:2) TO WS-MM.
           MOVE SRC-OPEN-YYMMDD(5:2) TO WS-DD.
           IF WS-YY > 50
               COMPUTE WS-CCYY = 1900 + WS-YY
           ELSE
               COMPUTE WS-CCYY = 2000 + WS-YY
           END-IF.
           STRING WS-CCYY DELIMITED BY SIZE
                  '-'     DELIMITED BY SIZE
                  WS-MM   DELIMITED BY SIZE
                  '-'     DELIMITED BY SIZE
                  WS-DD   DELIMITED BY SIZE
               INTO TGT-OPEN-DATE-ISO
           END-STRING.

      *    6. Map Ledger Balance and Calculate Available Balance
           MOVE SRC-CURR-BAL TO TGT-LEDGER-BALANCE.
           COMPUTE TGT-AVAIL-BALANCE = SRC-CURR-BAL - SRC-HOLD-AMT.

      *    7. Derive Target Risk Tier from Legacy Credit Score
           EVALUATE TRUE
               WHEN SRC-CR-SCORE >= 750
                   MOVE 'LOW   ' TO TGT-RISK-TIER
               WHEN SRC-CR-SCORE >= 620
                   MOVE 'MEDIUM' TO TGT-RISK-TIER
               WHEN OTHER
                   MOVE 'HIGH  ' TO TGT-RISK-TIER
           END-EVALUATE.

      *    8. Populate Hardcoded Migration Source System Identifier
           MOVE 'CORE-LEG' TO TGT-MIGR-SOURCE-SYS.

       4000-LOAD-TARGET.
           WRITE TGT-MODERN-RECORD.

           EXEC SQL
               INSERT INTO STG_CORE_ACCOUNTS
               (GLOBAL_ACCT_ID, FULL_NAME, PRODUCT_CODE,
                ACCOUNT_STATUS, OPEN_DATE_ISO, LEDGER_BALANCE,
                AVAIL_BALANCE, RISK_TIER, MIGR_SOURCE_SYS)
               VALUES
               (:TGT-GLOBAL-ACCT-ID, :TGT-FULL-NAME, :TGT-PRODUCT-CODE,
                :TGT-ACCOUNT-STATUS, :TGT-OPEN-DATE-ISO, :TGT-LEDGER-BALANCE,
                :TGT-AVAIL-BALANCE, :TGT-RISK-TIER, :TGT-MIGR-SOURCE-SYS)
           END-EXEC.

           ADD 1 TO WS-MIGRATED-CNT.

       5000-WRITE-REJECT.
           WRITE REJ-ERROR-RECORD.
           ADD 1 TO WS-REJECTED-CNT.
