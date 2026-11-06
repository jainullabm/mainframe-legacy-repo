//ACCTMIGJ JOB (MIGR,2026),'LEGACY ACCT MIGRATION',
//             CLASS=A,MSGCLASS=X,MSGLEVEL=(1,1),NOTIFY=&SYSUID
//*================================================================*
//* JOB NAME : ACCTMIGJ                                            *
//* PURPOSE  : MIGRATE LEGACY CORE BANKING ACCOUNTS TO TARGET      *
//*            CLOUD/MODERN CORE PLATFORM WITH VALIDATION & AUDIT  *
//*================================================================*
//STEP005  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE PROD.MIGR.TARGET.ACCOUNTS PURGE
  DELETE PROD.MIGR.REJECT.ACCOUNTS PURGE
  SET MAXCC = 0
/*
//*----------------------------------------------------------------*
//* STEP010: EXECUTE COBOL ACCOUNT MIGRATION ENGINE (ACCTMIG1)     *
//*----------------------------------------------------------------*
//STEP010  EXEC PGM=ACCTMIG1
//STEPLIB  DD DSN=PROD.COBOL.LOADLIB,DISP=SHR
//LGCYACCT DD DSN=PROD.LEGACY.MASTER.ACCOUNTS,DISP=SHR
//MIGRACCT DD DSN=PROD.MIGR.TARGET.ACCOUNTS,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(20,10),RLSE),
//            DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//REJACCT  DD DSN=PROD.MIGR.REJECT.ACCOUNTS,
//            DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(CYL,(5,2),RLSE),
//            DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//MIGRPT   DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//
