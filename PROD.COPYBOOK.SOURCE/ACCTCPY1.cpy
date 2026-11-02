      *================================================================*
      * COPYBOOK : ACCTCPY1                                            *
      * LIBRARY  : PROD.COPYBOOK.SOURCE                                *
      * PURPOSE  : SOURCE INPUT & TARGET OUTPUT ACCOUNT RECORD LAYOUTS *
      *================================================================*
       01  SRC-ACCT-RECORD.
           05  SRC-ACCT-ID             PIC X(10).
           05  SRC-CUST-FirstName      PIC X(25).
           05  SRC-ACCT-TYPE           PIC X(03).
           05  SRC-ACCT-STATUS         PIC X(01).
           05  SRC-OPEN-DATE           PIC X(08).
           05  SRC-CURR-BAL            PIC 9(07)V99.
           05  SRC-BRANCH-CODE         PIC X(04).
           05  SRC-FILLER              PIC X(60).

       01  TGT-ACCT-RECORD.
           05  TGT-ACCT-ID             PIC X(10).
           05  TGT-CUST-NAME           PIC X(25).
           05  TGT-ACCT-TYPE           PIC X(03).
           05  TGT-PROC-STATUS         PIC X(08).
           05  TGT-SETTLE-DATE         PIC X(08).
           05  TGT-NEW-BAL             PIC 9(07)V99.
           05  TGT-INT-EARNED          PIC 9(07)V99.
           05  TGT-FEE-APPLIED         PIC 9(05)V99.
           05  TGT-FILLER              PIC X(41).
