      *================================================================*
      * COPYBOOK : ACCTMIGC                                            *
      * PURPOSE  : LEGACY-TO-TARGET ACCOUNT MIGRATION DATA STRUCTURES  *
      *================================================================*
       01  LEGACY-ACCT-REC.
           05  LGCY-ACCT-ID              PIC X(10).
           05  LGCY-CUST-ID              PIC X(09).
           05  LGCY-BRANCH-CD            PIC X(04).
           05  LGCY-ACCT-TYPE            PIC X(02).
               88  LGCY-TYPE-SAVINGS         VALUE 'SV'.
               88  LGCY-TYPE-CURRENT         VALUE 'CA'.
               88  LGCY-TYPE-LOAN            VALUE 'LN'.
           05  LGCY-ACCT-STATUS          PIC X(01).
               88  LGCY-STATUS-ACTIVE        VALUE 'A'.
               88  LGCY-STATUS-DORMANT       VALUE 'D'.
               88  LGCY-STATUS-CLOSED        VALUE 'C'.
           05  LGCY-CURRENCY-CD          PIC X(03).
           05  LGCY-CURR-BAL             PIC S9(11)V99 COMP-3.
           05  LGCY-ACCRUED-INT          PIC S9(07)V99 COMP-3.
           05  LGCY-OPEN-DATE            PIC X(08).
           05  LGCY-CREDIT-LIMIT         PIC S9(09)V99 COMP-3.
           05  LGCY-FILLER               PIC X(20).

       01  TARGET-MIGR-REC.
           05  TGT-GLOBAL-ACCT-KEY       PIC X(18).
           05  TGT-PARTY-ID              PIC X(12).
           05  TGT-PRODUCT-CODE          PIC X(06).
           05  TGT-LIFECYCLE-STATUS      PIC X(10).
           05  TGT-ISO-CURRENCY          PIC X(03).
           05  TGT-PRINCIPAL-BAL         PIC S9(13)V99.
           05  TGT-ACCRUED-INT-AMT       PIC S9(09)V99.
           05  TGT-TOTAL-SETTLEMENT-BAL  PIC S9(13)V99.
           05  TGT-RISK-TIER             PIC X(08).
           05  TGT-OPEN-ISO-DATE         PIC X(10).
           05  TGT-MIGRATION-STATUS      PIC X(08).
           05  TGT-REJECT-REASON         PIC X(30).
