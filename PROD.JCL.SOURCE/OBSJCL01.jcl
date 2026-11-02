//OBSJCL01 JOB (FIN-ACCT),'DAILY ACCOUNT SETTLEMENT',
//             CLASS=A,MSGCLASS=X,NOTIFY=&SYSUID
//* ===================================================================
//* JOB NAME : OBSJCL01
//* PURPOSE  : DAILY CUSTOMER ACCOUNT INTEREST & FEE SETTLEMENT BATCH
//* ===================================================================
//*
//* -------------------------------------------------------------------
//* STEP 01: CLEANUP PREVIOUS RUN OUTPUT DATASETS (SYSTEM UTILITY)
//* -------------------------------------------------------------------
//STEP010  EXEC PGM=IEFBR14
//DELOUT   DD DSN=PROD.FIN.ACCT.SETTLED.OUT,
//            DISP=(MOD,DELETE,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(1,1))
//DELREJ   DD DSN=PROD.FIN.ACCT.REJECT.OUT,
//            DISP=(MOD,DELETE,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(1,1))
//*
//* -------------------------------------------------------------------
//* STEP 02: EXECUTE CORE COBOL ACCOUNT SETTLEMENT PROGRAM (ACCT001)
//* -------------------------------------------------------------------
//STEP020  EXEC PGM=ACCT001
//STEPLIB  DD DSN=PROD.COBOL.LOADLIB,DISP=SHR
//ACCTIN   DD DSN=PROD.FIN.ACCT.MASTER.IN,DISP=SHR
//ACCTOUT  DD DSN=PROD.FIN.ACCT.SETTLED.OUT,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(10,5),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//REJOUT   DD DSN=PROD.FIN.ACCT.REJECT.OUT,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(2,1),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//
