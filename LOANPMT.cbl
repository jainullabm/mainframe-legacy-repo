       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOANPMT.
       AUTHOR. ANALYST-1.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-INPUTS.
           05  WS-PRINCIPAL      PIC 9(07)V99 VALUE 150000.00.
           05  WS-ANNUAL-RATE    PIC 9(02)V9999 VALUE 05.2500.
           05  WS-TERM-MONTHS    PIC 9(03) VALUE 360.

       01  WS-INTERMEDIATE-VARS.
           05  WS-MONTHLY-RATE   PIC 9(03)V999999 VALUE ZERO.
           05  WS-TEMP-CALC      PIC 9(10)V999999 VALUE ZERO.
           05  WS-INTEREST-PMT   PIC 9(07)V99 VALUE ZERO.
           05  WS-PRINCIPAL-PMT  PIC 9(07)V99 VALUE ZERO.

       01  WS-OUTPUTS.
           05  WS-MONTHLY-PMT    PIC 9(07)V99 VALUE ZERO.

       PROCEDURE DIVISION.
       0100-PROCESS-LOAN.
           DISPLAY "CALCULATING LOAN AMORTIZATION..."
           
           * Convert annual percentage to monthly decimal rate
           COMPUTE WS-MONTHLY-RATE = WS-ANNUAL-RATE / 12 / 100.
           
           * Formula: PMT = P * (r(1+r)^n) / ((1+r)^n - 1)
           COMPUTE WS-TEMP-CALC = (1 + WS-MONTHLY-RATE) ** WS-TERM-MONTHS.
           COMPUTE WS-MONTHLY-PMT ROUNDED = 
               WS-PRINCIPAL * (WS-MONTHLY-RATE * WS-TEMP-CALC) / (WS-TEMP-CALC - 1).

           DISPLAY "LOAN PRINCIPAL: " WS-PRINCIPAL.
           DISPLAY "MONTHLY RATE  : " WS-MONTHLY-RATE.
           DISPLAY "TERM IN MONTHS: " WS-TERM-MONTHS.
           DISPLAY "MONTHLY PMT   : " WS-MONTHLY-PMT.
           
           STOP RUN.
